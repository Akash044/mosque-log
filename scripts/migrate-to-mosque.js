// One-off migration: backfills the pre-multi-tenant Firestore data into a
// single "default mosque" so the app keeps working once mosqueId-scoped
// rules are deployed.
//
// Run this AFTER verifying the multi-tenant app build against a TEST Firebase
// project, and BEFORE deploying the new firestore.rules / firestore.indexes.json
// to production (the new rules reject any doc that has no matching mosqueId,
// so un-migrated data would become unreadable the instant they go live).
//
// Usage:
//   1. Firebase console → Project settings → Service accounts → Generate new
//      private key. Save it next to this script as serviceAccountKey.json
//      (already gitignored — never commit it).
//   2. npm install firebase-admin
//   3. node migrate-to-mosque.js --uid=<existing-admin-uid> [--dry-run]
//
// The uid is whichever Firebase Auth user currently signs into the app —
// find it in Firebase console → Authentication → Users.

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  })
);

const adminUid = args.uid;
const dryRun = Boolean(args['dry-run']);

if (!adminUid) {
  console.error('Usage: node migrate-to-mosque.js --uid=<existing-admin-uid> [--dry-run]');
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const DEFAULT_MOSQUE = {
  name: 'Baitur Nur Jame Mosjid',
  address: 'Khushi Para, Patuakandi, Bheramara, Kushtia',
  phone: null,
};

const COLLECTIONS = ['persons', 'income', 'expenses', 'audit_logs'];
const BATCH_SIZE = 500;

async function stampCollection(collectionName, mosqueId) {
  const collectionRef = db.collection(collectionName);
  let stamped = 0;
  let lastDoc = null;

  for (;;) {
    let query = collectionRef.orderBy(admin.firestore.FieldPath.documentId()).limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    const snap = await query.get();
    if (snap.empty) break;

    const batch = db.batch();
    let batchCount = 0;
    for (const doc of snap.docs) {
      if (doc.data().mosqueId) continue; // already migrated, skip
      batch.update(doc.ref, { mosqueId });
      batchCount++;
    }
    if (batchCount > 0 && !dryRun) await batch.commit();
    stamped += batchCount;
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < BATCH_SIZE) break;
  }

  console.log(`${dryRun ? '[dry-run] would stamp' : 'stamped'} ${stamped} docs in ${collectionName}`);
}

async function main() {
  console.log(dryRun ? 'Running in --dry-run mode, no writes will be made.' : 'Running for real.');

  const mosqueRef = db.collection('mosques').doc();
  const userRef = db.collection('users').doc(adminUid);
  const now = admin.firestore.Timestamp.now();

  console.log(`${dryRun ? '[dry-run] would create' : 'creating'} mosques/${mosqueRef.id} and users/${adminUid}`);
  if (!dryRun) {
    const authUser = await admin.auth().getUser(adminUid);
    await db.runTransaction(async (tx) => {
      tx.set(mosqueRef, { ...DEFAULT_MOSQUE, createdBy: adminUid, createdAt: now });
      tx.set(userRef, {
        email: authUser.email ?? '',
        name: authUser.displayName ?? '',
        mosqueId: mosqueRef.id,
        role: 'admin',
        createdAt: now,
      });
    });
  }

  for (const collectionName of COLLECTIONS) {
    await stampCollection(collectionName, mosqueRef.id);
  }

  console.log('Done.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

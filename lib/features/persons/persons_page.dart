import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/person.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/person_provider.dart';
import '../income/widgets/add_person_dialog.dart';

class PersonsPage extends ConsumerWidget {
  const PersonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final personsAsync = ref.watch(personsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.managePeople)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddPersonDialog(),
        ),
        icon: const Icon(Icons.person_add),
        label: Text(l.addPerson),
      ),
      body: personsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (persons) {
          if (persons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noPersons),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: persons.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) =>
                _PersonTile(person: persons[i]),
          );
        },
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final service = ref.read(firestoreServiceProvider);

    return Dismissible(
      key: ValueKey(person.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                content: Text(l.deleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.no),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l.yes),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => service.deletePerson(person.id),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            person.name.isEmpty ? '?' : person.name[0].toUpperCase(),
          ),
        ),
        title: Text(person.name),
        subtitle: person.phone == null || person.phone!.isEmpty
            ? null
            : Text(person.phone!),
        trailing: Switch(
          value: person.active,
          onChanged: (v) => service.setPersonActive(person.id, v),
        ),
      ),
    );
  }
}

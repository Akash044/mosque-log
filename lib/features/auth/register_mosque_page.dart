import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/mosque_provider.dart';
import 'widgets/admin_info_step.dart';
import 'widgets/mosque_info_step.dart';

/// New-mosque signup: mosque info first, then the admin account that will
/// own it. The Firebase Auth account and the `mosques`/`users` docs are only
/// created on final submit — the two steps here are a data-collection order,
/// not a write order (Firestore rules require an authenticated request).
class RegisterMosquePage extends ConsumerStatefulWidget {
  const RegisterMosquePage({super.key});

  @override
  ConsumerState<RegisterMosquePage> createState() =>
      _RegisterMosquePageState();
}

class _RegisterMosquePageState extends ConsumerState<RegisterMosquePage> {
  final _mosqueFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  final _mosqueName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _adminName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  int _step = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _mosqueName.dispose();
    _address.dispose();
    _phone.dispose();
    _adminName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _next() {
    if (!_mosqueFormKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  void _back() => setState(() => _step = 0);

  Future<void> _submit() async {
    if (!_adminFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final l = AppLocalizations.of(context);
    try {
      await ref.read(registrationServiceProvider).registerMosqueWithNewAdmin(
            mosqueName: _mosqueName.text,
            address: _address.text,
            phone: _phone.text,
            adminName: _adminName.text,
            email: _email.text,
            password: _password.text,
          );
      // No manual navigation: the router redirect moves us on once the new
      // users/{uid} doc is visible via userProfileProvider.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l.registrationFailed)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.registrationFailed)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.registerMosqueTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _StepDot(active: true),
                      const SizedBox(width: 6),
                      _StepDot(active: _step == 1),
                      const SizedBox(width: 12),
                      Text(
                        _step == 0 ? l.stepMosqueInfo : l.stepAdminInfo,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_step == 0)
                    Form(
                      key: _mosqueFormKey,
                      child: MosqueInfoStep(
                        nameController: _mosqueName,
                        addressController: _address,
                        phoneController: _phone,
                      ),
                    )
                  else
                    Form(
                      key: _adminFormKey,
                      child: AdminInfoStep(
                        nameController: _adminName,
                        emailController: _email,
                        passwordController: _password,
                        confirmPasswordController: _confirmPassword,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_step == 1) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : _back,
                            child: Text(l.back),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : (_step == 0 ? _next : _submit),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(_step == 0 ? l.next : l.register),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    return Container(
      width: 24,
      height: 4,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

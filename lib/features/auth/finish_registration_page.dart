import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mosque_provider.dart';
import 'widgets/mosque_info_step.dart';

/// Shown to an authenticated user with no `users/{uid}` doc yet — a
/// first-time Google sign-in, or an email/password signup interrupted after
/// the Firebase Auth account was created but before the mosque doc landed.
/// Collects only mosque info since identity is already established.
class FinishRegistrationPage extends ConsumerStatefulWidget {
  const FinishRegistrationPage({super.key});

  @override
  ConsumerState<FinishRegistrationPage> createState() =>
      _FinishRegistrationPageState();
}

class _FinishRegistrationPageState
    extends ConsumerState<FinishRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _mosqueName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _mosqueName.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(registrationServiceProvider)
          .finishRegistrationForCurrentUser(
            mosqueName: _mosqueName.text,
            address: _address.text,
            phone: _phone.text,
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
        title: Text(l.finishRegistrationTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.signOut,
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
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
                  Text(
                    l.finishRegistrationDesc,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: MosqueInfoStep(
                      nameController: _mosqueName,
                      addressController: _address,
                      phoneController: _phone,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.register),
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

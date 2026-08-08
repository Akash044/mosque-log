import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class AdminInfoStep extends StatelessWidget {
  const AdminInfoStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(labelText: l.adminNameLabel),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.adminNameRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: l.email),
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return l.emailRequired;
            if (!value.contains('@')) return l.emailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: l.password),
          validator: (v) {
            if ((v ?? '').isEmpty) return l.passwordRequired;
            if ((v ?? '').length < 6) return l.passwordTooShort;
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(labelText: l.confirmPassword),
          validator: (v) =>
              v != passwordController.text ? l.passwordMismatch : null,
        ),
      ],
    );
  }
}

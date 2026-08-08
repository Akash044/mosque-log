import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Mosque name/address/phone fields, reused by both the new-mosque
/// registration wizard and the "finish registration" flow for a user who
/// signed in (e.g. via Google) before any mosque existed for them.
class MosqueInfoStep extends StatelessWidget {
  const MosqueInfoStep({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(labelText: l.mosqueNameLabel),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.mosqueNameRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(labelText: l.mosqueAddressLabel),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.mosqueAddressRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l.mosquePhoneLabel),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push('/settings'),
    );
  }
}

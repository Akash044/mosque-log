import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/', '/income', '/expense', '/report'];

  int _indexFor(String location) {
    final i = _tabs.indexOf(location);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up_outlined),
            selectedIcon: const Icon(Icons.trending_up),
            label: l.navIncome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l.navExpense,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assessment_outlined),
            selectedIcon: const Icon(Icons.assessment),
            label: l.navReport,
          ),
        ],
      ),
    );
  }
}

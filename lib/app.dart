import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/expense/expense_page.dart';
import 'features/income/income_page.dart';
import 'features/persons/persons_page.dart';
import 'features/report/report_page.dart';
import 'features/settings/settings_page.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/app_shell.dart';
import 'widgets/offline_banner.dart';

class MosqueApp extends ConsumerWidget {
  const MosqueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Layout the banner above the route content. When online the banner
        // renders as SizedBox.shrink() so it costs zero vertical space.
        // SafeArea handles the status bar inset; removePadding below stops
        // the nested Scaffold from adding it a second time.
        return Column(
          children: [
            SafeArea(
              top: true,
              bottom: false,
              child: const OfflineBanner(),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final loggedIn = auth.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
      final loggingIn = state.matchedLocation == '/login';
      if (auth.isLoading) return null;
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/persons',
        builder: (context, state) => const PersonsPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardPage()),
          GoRoute(path: '/income', builder: (c, s) => const IncomePage()),
          GoRoute(path: '/expense', builder: (c, s) => const ExpensePage()),
          GoRoute(path: '/report', builder: (c, s) => const ReportPage()),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

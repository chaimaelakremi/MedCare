import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chatbot/screens/chatbot_screen.dart';
import '../../features/family/providers/family_providers.dart';
import '../../features/family/screens/family_home_screen.dart';
import '../../features/family/screens/family_medications_screen.dart';
import '../../features/family/screens/family_report_screen.dart';
import '../../features/family/screens/family_screen.dart';
import '../../features/family/screens/notifications_screen.dart';
import '../../features/medications/screens/add_medication_screen.dart';
import '../../features/medications/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, _) => notifyListeners());
    _ref.listen<bool>(onboardingDoneProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn =
        _ref.read(authStateProvider).asData?.value != null;
    final onboardingDone = _ref.read(onboardingDoneProvider);
    final loc = state.matchedLocation;

    if (!onboardingDone && loc != '/onboarding') return '/onboarding';
    if (onboardingDone && loc == '/onboarding') return '/login';
    if (!isLoggedIn && loc != '/login' && loc != '/register' && loc != '/onboarding') return '/login';
    if (isLoggedIn && (loc == '/login' || loc == '/register')) return '/';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login',      builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/add-medication', builder: (_, _) => const AddMedicationScreen()),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/',                   builder: (_, _) => const _HomeWrapper()),
          GoRoute(path: '/analytics',          builder: (_, _) => const AnalyticsScreen()),
          GoRoute(path: '/chatbot',            builder: (_, _) => const ChatbotScreen()),
          GoRoute(path: '/family',             builder: (_, _) => const FamilyScreen()),
          GoRoute(path: '/family-medications', builder: (_, _) => const FamilyMedicationsScreen()),
          GoRoute(path: '/family-report',      builder: (_, _) => const FamilyReportScreen()),
          GoRoute(path: '/notifications',      builder: (_, _) => const NotificationsScreen()),
          GoRoute(path: '/profile',            builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/settings',           builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

// ── Home wrapper (dispatches patient vs family home) ──────────────────────────

class _HomeWrapper extends ConsumerWidget {
  const _HomeWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(userDocProvider);
    return userDocAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const HomeScreen(),
      data: (doc) {
        final role = doc?['role'] as String? ?? 'patient';
        return role == 'family' ? const FamilyHomeScreen() : const HomeScreen();
      },
    );
  }
}

// ── App shell (role-aware navigation bar) ─────────────────────────────────────

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final userDocAsync = ref.watch(userDocProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final role =
        userDocAsync.asData?.value?['role'] as String? ?? 'patient';
    final isFamily = role == 'family';
    final location = GoRouterState.of(context).uri.path;

    if (isFamily) {
      return _FamilyShell(
        l10n: l10n,
        location: location,
        unreadCount: unreadCount,
        child: child,
      );
    }

    return _PatientShell(
      l10n: l10n,
      location: location,
      unreadCount: unreadCount,
      child: child,
    );
  }
}

// ── Patient shell (5 tabs, purple) ────────────────────────────────────────────

class _PatientShell extends StatelessWidget {
  final Widget child;
  final AppLocalizations l10n;
  final String location;
  final int unreadCount;

  const _PatientShell({
    required this.child,
    required this.l10n,
    required this.location,
    required this.unreadCount,
  });

  int _index() {
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/chatbot'))   return 2;
    if (location.startsWith('/family'))    return 3;
    if (location.startsWith('/settings'))  return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(),
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/');
            case 1: context.go('/analytics');
            case 2: context.go('/chatbot');
            case 3: context.go('/family');
            case 4: context.go('/settings');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.get('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l10n.get('analytics'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy_rounded),
            label: l10n.get('chatbot'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.people_rounded),
            ),
            label: l10n.get('family'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.get('settings'),
          ),
        ],
      ),
    );
  }
}

// ── Family shell (4 tabs, pink) ───────────────────────────────────────────────

class _FamilyShell extends StatelessWidget {
  final Widget child;
  final AppLocalizations l10n;
  final String location;
  final int unreadCount;

  const _FamilyShell({
    required this.child,
    required this.l10n,
    required this.location,
    required this.unreadCount,
  });

  int _index() {
    if (location.startsWith('/family-medications')) { return 1; }
    if (location.startsWith('/family-report'))      { return 2; }
    if (location.startsWith('/settings') ||
        location.startsWith('/profile'))             { return 3; }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const pink = AppTheme.familyPrimary;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(),
        indicatorColor: pink.withValues(alpha: 0.15),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/');
            case 1: context.go('/family-medications');
            case 2: context.go('/family-report');
            case 3: context.go('/settings');
          }
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.home_rounded),
            ),
            label: l10n.get('home'),
          ),
          const NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Médicaments',
          ),
          const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Rapport',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l10n.get('profile'),
          ),
        ],
      ),
    );
  }
}

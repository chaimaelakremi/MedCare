import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'core/providers/onboarding_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/notifications/notification_service.dart';
import 'firebase_options.dart';

// ── Firebase ready state ──────────────────────────────────────────────────────

class FirebaseStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setStatus(bool value) => state = value;
}

final firebaseReadyProvider =
    NotifierProvider<FirebaseStatusNotifier, bool>(FirebaseStatusNotifier.new);

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeDateFormatting();

  final firebaseReady = await _initFirebase();
  await NotificationService.initialize();

  final container = ProviderContainer();
  container.read(firebaseReadyProvider.notifier).setStatus(firebaseReady);
  container.read(onboardingDoneProvider.notifier).setDone(false);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MedCareApp(),
    ),
  );
}

/// Tries Firebase init up to 3 times with exponential back-off.
/// Returns true on success, false when all attempts fail (offline mode).
Future<bool> _initFirebase() async {
  for (int attempt = 1; attempt <= 3; attempt++) {
    try {
      if (attempt > 1) {
        await Future.delayed(Duration(seconds: attempt));
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable Firestore offline cache so the app works without network.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint('[MedCare] Firebase ready (attempt $attempt)');
      return true;
    } catch (e) {
      debugPrint('[MedCare] Firebase init attempt $attempt failed: $e');
    }
  }

  debugPrint('[MedCare] Firebase unavailable — running in offline mode');
  return false;
}

// ── Root widget ───────────────────────────────────────────────────────────────

class MedCareApp extends ConsumerWidget {
  const MedCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'MedCare',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _OfflineBanner(child: child!),
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────────

class _OfflineBanner extends ConsumerWidget {
  final Widget child;
  const _OfflineBanner({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    if (ready) return child;

    return Column(
      children: [
        Material(
          color: Colors.orange.shade700,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mode hors-ligne — vérifiez votre connexion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => _retry(ref),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Future<void> _retry(WidgetRef ref) async {
    final ok = await _initFirebase();
    ref.read(firebaseReadyProvider.notifier).setStatus(ok);
  }
}

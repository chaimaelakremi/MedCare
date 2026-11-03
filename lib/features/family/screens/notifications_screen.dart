import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/family_repository.dart';
import '../data/notification_model.dart';
import '../providers/family_providers.dart';
import '../../auth/providers/auth_providers.dart';

const _kPink = AppTheme.familyPrimary;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authStateProvider).asData?.value?.uid;
      if (uid != null) {
        ref.read(familyRepositoryProvider).markNotificationsRead(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: _kPink.withValues(alpha: 0.08),
        foregroundColor: _kPink,
        titleTextStyle: const TextStyle(
          color: _kPink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _kPink),
        actions: [
          notifsAsync.maybeWhen(
            data: (notifs) => notifs.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () {
                      final uid =
                          ref.read(authStateProvider).asData?.value?.uid;
                      if (uid != null) {
                        ref
                            .read(familyRepositoryProvider)
                            .markNotificationsRead(uid);
                      }
                    },
                    child: const Text('Tout lire',
                        style: TextStyle(color: _kPink)),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const _EmptyState();
          }
          final groups = _groupByDate(notifs);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: groups.length,
            itemBuilder: (ctx, i) {
              final group = groups[i];
              return _NotifGroup(
                label: group.label,
                notifications: group.items,
                startIndex: group.startIndex,
              );
            },
          );
        },
      ),
    );
  }

  List<_Group> _groupByDate(List<AppNotification> notifs) {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    final Map<String, List<AppNotification>> map = {};
    for (final n in notifs) {
      final key = n.createdAt != null
          ? DateFormat('yyyy-MM-dd').format(n.createdAt!)
          : 'other';
      map.putIfAbsent(key, () => []).add(n);
    }

    final result = <_Group>[];
    int idx = 0;
    for (final entry in map.entries) {
      String label;
      if (entry.key == todayStr) {
        label = 'Aujourd\'hui';
      } else if (entry.key == yesterdayStr) {
        label = 'Hier';
      } else if (entry.key == 'other') {
        label = 'Plus tôt';
      } else {
        try {
          label = DateFormat('EEEE d MMMM', 'fr_FR')
              .format(DateFormat('yyyy-MM-dd').parse(entry.key));
        } catch (_) {
          label = entry.key;
        }
      }
      result.add(_Group(label: label, items: entry.value, startIndex: idx));
      idx += entry.value.length;
    }
    return result;
  }
}

// ── Data helpers ──────────────────────────────────────────────────────────────

class _Group {
  final String label;
  final List<AppNotification> items;
  final int startIndex;
  const _Group(
      {required this.label,
      required this.items,
      required this.startIndex});
}

// ── Group section ─────────────────────────────────────────────────────────────

class _NotifGroup extends StatelessWidget {
  final String label;
  final List<AppNotification> notifications;
  final int startIndex;

  const _NotifGroup({
    required this.label,
    required this.notifications,
    required this.startIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...notifications.asMap().entries.map((e) {
          return _NotifTile(
            notif: e.value,
            animIndex: startIndex + e.key,
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotifTile extends ConsumerWidget {
  final AppNotification notif;
  final int animIndex;

  const _NotifTile({required this.notif, required this.animIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTaken = notif.type == 'taken_medication';
    final color = isTaken ? Colors.green.shade600 : Colors.orange.shade700;
    final bgColor = isTaken
        ? Colors.green.withValues(alpha: 0.08)
        : Colors.orange.withValues(alpha: 0.08);
    final icon =
        isTaken ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final prefix = isTaken ? '✅' : '⚠️';

    final timeStr = notif.createdAt != null
        ? DateFormat('HH:mm').format(notif.createdAt!)
        : '';

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        // Firestore delete handled silently — provider stream removes it
        final uid = ref.read(authStateProvider).asData?.value?.uid;
        if (uid != null) {
          FirebaseNotifDeleter.delete(uid, notif.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notif.read
              ? (Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface)
              : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: notif.read
              ? null
              : Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
              children: [
                TextSpan(text: '$prefix '),
                TextSpan(
                  text: notif.patientName,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: isTaken ? ' a pris ' : ' a oublié ',
                ),
                TextSpan(
                  text: notif.medicationName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 11, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  notif.timeSlot.isNotEmpty
                      ? '${notif.timeSlot} · $timeStr'
                      : timeStr,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          trailing: notif.read
              ? null
              : Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animIndex * 40))
        .fade(duration: 300.ms)
        .slideX(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

// ── Firestore delete helper ───────────────────────────────────────────────────

class FirebaseNotifDeleter {
  static Future<void> delete(String uid, String notifId) async {
    try {
      await FamilyRepository()
          .deleteNotification(uid, notifId);
    } catch (_) {}
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 52,
              color: _kPink,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fade(duration: 300.ms),
          const SizedBox(height: 20),
          const Text(
            'Aucune notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ).animate().fade(delay: 150.ms, duration: 300.ms),
          const SizedBox(height: 8),
          Text(
            'Les alertes de prise et d\'oubli\napparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ).animate().fade(delay: 250.ms, duration: 300.ms),
        ],
      ),
    );
  }
}

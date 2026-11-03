import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final userDoc = ref.watch(userDocProvider).asData?.value;
    final name = userDoc?['name'] as String? ?? '';
    final email = userDoc?['email'] as String? ?? '';
    final role = userDoc?['role'] as String? ?? 'patient';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('settings'))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _ProfileHeader(name: name, email: email, role: role, l10n: l10n),
            const SizedBox(height: 24),

            // Profile section
            _Section(
              title: l10n.get('profile'),
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: AppTheme.primary),
                  title: Text(name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(email),
                  trailing:
                      const Icon(Icons.chevron_right, color: AppTheme.primary),
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Appearance
            _Section(
              title: 'Apparence',
              children: [
                SwitchListTile(
                  value: isDark,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (_) =>
                      ref.read(themeProvider.notifier).toggle(),
                  secondary: Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    isDark ? 'Mode sombre' : 'Mode clair',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Language
            _Section(
              title: l10n.get('language'),
              children: [
                _LanguageTile(
                  flag: '🇫🇷',
                  label: 'Français',
                  selected: locale == 'fr',
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale('fr'),
                ),
                const Divider(height: 1, indent: 56),
                _LanguageTile(
                  flag: '🇬🇧',
                  label: 'English',
                  selected: locale == 'en',
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale('en'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Role info
            _Section(
              title: 'Compte',
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.badge_outlined, color: AppTheme.primary),
                  title: Text(l10n.get('role_select'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    role == 'patient'
                        ? l10n.get('role_patient')
                        : l10n.get('role_family'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 52),
                ),
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.get('logout')),
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 32),
            Text(
              'MedCare v1.0.0 • Made with 💜',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final AppLocalizations l10n;

  const _ProfileHeader(
      {required this.name,
      required this.email,
      required this.role,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role == 'patient'
                ? '🧓 ${l10n.get('role_patient')}'
                : '👨‍👩‍👧 ${l10n.get('role_family')}',
            style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05);
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile(
      {required this.flag,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label,
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : null,
          )),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
          : null,
    );
  }
}

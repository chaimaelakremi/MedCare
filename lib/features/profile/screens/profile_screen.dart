import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (!mounted || data == null) return;
    _nameCtrl.text = data['name'] as String? ?? '';
    _ageCtrl.text = (data['age'] as int?)?.toString() ?? '';
    _conditionCtrl.text = data['condition'] as String? ?? '';
    _doctorCtrl.text = data['doctorName'] as String? ?? '';
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text.trim()),
      'condition': _conditionCtrl.text.trim(),
      'doctorName': _doctorCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil mis à jour !'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _conditionCtrl.dispose();
    _doctorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 32),
                    _Field(
                      controller: _nameCtrl,
                      label: 'Nom complet',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                      onChanged: (_) => setState(() {}),
                    ).animate().fade(delay: 50.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _ageCtrl,
                      label: 'Âge',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                    ).animate().fade(delay: 100.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _conditionCtrl,
                      label: 'Condition médicale',
                      icon: Icons.medical_information_outlined,
                      hint: 'Ex: Diabète, Hypertension...',
                    ).animate().fade(delay: 150.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _doctorCtrl,
                      label: 'Nom du médecin',
                      icon: Icons.local_hospital_outlined,
                    ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Enregistrer',
                              style: TextStyle(fontSize: 17)),
                    ).animate().fade(delay: 250.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
    );
  }
}

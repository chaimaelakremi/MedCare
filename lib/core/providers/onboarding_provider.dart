import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDone(bool value) => state = value;

  Future<void> markDone() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }
}

final onboardingDoneProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

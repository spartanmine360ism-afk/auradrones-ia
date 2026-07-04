import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 500), _route);
  }

  Future<void> _route() async {
    final auth = ref.read(authServiceProvider);
    final user = auth.currentUser ?? await auth.authStateChanges().first;
    if (!mounted) return;
    if (user == null) {
      context.go('/login');
      return;
    }
    if (!user.emailVerified) {
      context.go('/verify-email');
      return;
    }
    final profile = await ref
        .read(userDataServiceProvider)
        .ensureUserProfile(user);
    if (profile.emailVerified != user.emailVerified) {
      await ref
          .read(userDataServiceProvider)
          .saveProfile(profile.copyWith(emailVerified: user.emailVerified));
    }
    if (!mounted) return;
    context.go(profile.onboardingComplete ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AuraBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radar, size: 76, color: AuraColors.cyan),
              SizedBox(height: 18),
              Text(
                'Aura Pilot',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'Fly smarter. Film safer.',
                style: TextStyle(color: AuraColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

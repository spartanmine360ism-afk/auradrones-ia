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
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 500), _route);
  }

  Future<void> _route() async {
    try {
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
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar, size: 76, color: AuraColors.cyan),
              const SizedBox(height: 18),
              const Text(
                'Aura Pilot',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fly smarter. Film safer.',
                style: TextStyle(color: AuraColors.muted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AuraColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

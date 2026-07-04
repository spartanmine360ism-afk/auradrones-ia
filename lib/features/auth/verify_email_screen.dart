import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = false;
  String? _message;

  Future<void> _checkVerification() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final user = await auth.reloadCurrentUser();
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      if (!user.emailVerified) {
        setState(() => _message = 'Tu correo todavia no aparece verificado.');
        return;
      }
      final dataService = ref.read(userDataServiceProvider);
      final profile = await dataService.ensureUserProfile(user);
      await dataService.saveProfile(profile.copyWith(emailVerified: true));
      ref.invalidateSensitiveUserState();
      if (mounted) {
        context.go(profile.onboardingComplete ? '/home' : '/onboarding');
      }
    } catch (error) {
      setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      setState(() => _message = 'Correo de verificacion reenviado.');
    } catch (error) {
      setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    ref.invalidateSensitiveUserState();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AuraGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 54),
                    const SizedBox(height: 14),
                    Text(
                      'Verifica tu correo',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(user?.email ?? '', textAlign: TextAlign.center),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _checkVerification,
                      child: Text(_loading ? 'Revisando...' : 'Ya verifique'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _resend,
                      child: const Text('Reenviar correo'),
                    ),
                    TextButton.icon(
                      onPressed: _loading ? null : _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

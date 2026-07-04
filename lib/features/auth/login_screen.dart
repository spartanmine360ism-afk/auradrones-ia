import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_register) {
        final user = await auth.register(
          name: _name.text.trim().isEmpty ? 'Piloto' : _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
        await ref.read(userDataServiceProvider).ensureUserProfile(user);
        if (mounted) context.go('/verify-email');
      } else {
        final user = await auth.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (mounted) {
          if (!user.emailVerified) {
            context.go('/verify-email');
            return;
          }
          final profile = await ref
              .read(userDataServiceProvider)
              .ensureUserProfile(user);
          if (!mounted) return;
          context.go(profile.onboardingComplete ? '/home' : '/onboarding');
        }
      }
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe tu email para recuperar password');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te enviamos un correo para cambiar tu contrasena'),
          ),
        );
      }
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      _register ? 'Crear cuenta' : 'Iniciar sesion',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (FirebaseBootstrap.localMode) ...[
                      const SizedBox(height: 10),
                      const _ModeBanner(
                        text:
                            'Modo local: Firebase no esta configurado en esta build.',
                      ),
                    ] else if (FirebaseBootstrap.failed) ...[
                      const SizedBox(height: 10),
                      _ModeBanner(
                        text:
                            'Error real de Firebase: ${FirebaseBootstrap.failureMessage}',
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (_register)
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_register ? 'Registrarme' : 'Entrar'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _register = !_register),
                      child: Text(
                        _register ? 'Ya tengo cuenta' : 'Crear cuenta nueva',
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Olvide mi contrasena'),
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

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _level = 'Principiante';
  String _goal = 'Hobby';
  final _hours = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) return;
    await ref
        .read(userDataServiceProvider)
        .saveProfile(
          profile.copyWith(
            pilotLevel: _level,
            mainGoal: _goal,
            totalFlightHours: double.tryParse(_hours.text) ?? 0,
            onboardingComplete: true,
          ),
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AuraGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configura tu perfil',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      initialValue: _level,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de piloto',
                      ),
                      items:
                          const [
                                'Principiante',
                                'Intermedio',
                                'Avanzado',
                                'Profesional',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => _level = value!),
                    ),
                    DropdownButtonFormField(
                      initialValue: _goal,
                      decoration: const InputDecoration(
                        labelText: 'Objetivo principal',
                      ),
                      items:
                          const [
                                'Hobby',
                                'Contenido',
                                'Trabajo',
                                'Inmobiliario',
                                'Eventos',
                                'Inspeccion',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => _goal = value!),
                    ),
                    TextField(
                      controller: _hours,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Horas de vuelo ya realizadas',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: Text(_loading ? 'Guardando...' : 'Continuar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

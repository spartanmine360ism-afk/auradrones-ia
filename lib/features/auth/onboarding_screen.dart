import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/drone_constants.dart';
import '../../core/models/battery.dart';
import '../../core/models/drone.dart';
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
  final _droneBrand = TextEditingController();
  final _droneModel = TextEditingController();
  final _droneSerial = TextEditingController();
  final _droneWeight = TextEditingController();
  final _batteryName = TextEditingController(text: 'Bateria 1');
  final _batteryModel = TextEditingController();
  final _batteryCycles = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    _hours.dispose();
    _droneBrand.dispose();
    _droneModel.dispose();
    _droneSerial.dispose();
    _droneWeight.dispose();
    _batteryName.dispose();
    _batteryModel.dispose();
    _batteryCycles.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_droneBrand.text.trim().isEmpty ||
        _droneModel.text.trim().isEmpty ||
        _batteryName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un dron y una bateria')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final authUser = ref.read(currentUserProvider);

      if (authUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final dataService = ref.read(userDataServiceProvider);
      final profile = await dataService.ensureUserProfile(authUser);
      final droneId = 'drone-${DateTime.now().microsecondsSinceEpoch}';
      final batteryId = 'battery-${DateTime.now().microsecondsSinceEpoch}';

      await dataService.saveDrone(
        authUser.id,
        Drone(
          id: droneId,
          brand: _droneBrand.text.trim(),
          model: _droneModel.text.trim(),
          serialNumber: _droneSerial.text.trim(),
          weightGrams: int.tryParse(_droneWeight.text.trim()) ?? 0,
          type: DroneConstants.defaultDroneType,
          flightHours: 0,
          flightsCount: 0,
          status: 'Listo',
          nextMaintenance: '',
          purchaseDate: null,
          notes: '',
          photoUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await dataService.saveBattery(
        authUser.id,
        DroneBattery(
          id: batteryId,
          name: _batteryName.text.trim(),
          compatibleModel: _batteryModel.text.trim().isEmpty
              ? _droneModel.text.trim()
              : _batteryModel.text.trim(),
          droneId: droneId,
          cycles: int.tryParse(_batteryCycles.text.trim()) ?? 0,
          health: 100,
          lastCharge: '',
          lastUse: '',
          level: 100,
          status: 'buena',
          notes: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await dataService.saveProfile(
        profile.copyWith(
          pilotLevel: _level,
          mainGoal: _goal,
          totalFlightHours: double.tryParse(_hours.text) ?? 0,
          activeDroneId: droneId,
          activeBatteryId: batteryId,
          onboardingComplete: true,
        ),
      );

      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error guardando perfil: $error')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
                    DropdownButtonFormField<String>(
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
                          ].map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _level = value);
                      },
                    ),
                    DropdownButtonFormField<String>(
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
                          ].map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _goal = value);
                      },
                    ),
                    TextField(
                      controller: _hours,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Horas de vuelo ya realizadas',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dron inicial',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextField(
                      controller: _droneBrand,
                      decoration: const InputDecoration(labelText: 'Marca'),
                    ),
                    TextField(
                      controller: _droneModel,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                    ),
                    TextField(
                      controller: _droneSerial,
                      decoration: const InputDecoration(
                        labelText: 'Numero de serie',
                      ),
                    ),
                    TextField(
                      controller: _droneWeight,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peso (g)'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bateria inicial',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextField(
                      controller: _batteryName,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: _batteryModel,
                      decoration: const InputDecoration(
                        labelText: 'Modelo compatible',
                      ),
                    ),
                    TextField(
                      controller: _batteryCycles,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ciclos de bateria si los conoces',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class FlightPlannerScreen extends ConsumerStatefulWidget {
  const FlightPlannerScreen({super.key});

  @override
  ConsumerState<FlightPlannerScreen> createState() =>
      _FlightPlannerScreenState();
}

class _FlightPlannerScreenState extends ConsumerState<FlightPlannerScreen> {
  static const _checklistItems = [
    'Helices revisadas',
    'Baterias cargadas',
    'Control cargado',
    'Memoria disponible',
    'Clima revisado',
    'KP revisado',
    'Zona revisada',
    'Home Point actualizado',
    'GPS estable',
    'Plan de emergencia listo',
  ];

  Map<String, bool> _checked = {
    for (final item in _checklistItems) item: false,
  };
  bool _loaded = false;
  bool _generatingShotlist = false;
  String? _aiShotlist;
  String? _aiShotlistError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadChecklist);
  }

  Future<void> _loadChecklist() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final saved = await ref
        .read(userDataServiceProvider)
        .loadPreflightChecklist(user.id);
    if (!mounted) return;
    setState(() {
      _checked = {
        for (final item in _checklistItems) item: saved[item] ?? false,
      };
      _loaded = true;
    });
  }

  Future<void> _setChecked(String item, bool value) async {
    final next = {..._checked, item: value};
    setState(() => _checked = next);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref
          .read(userDataServiceProvider)
          .savePreflightChecklist(user.id, next);
    }
  }

  Future<void> _resetChecklist() async {
    final next = {for (final item in _checklistItems) item: false};
    setState(() => _checked = next);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref
          .read(userDataServiceProvider)
          .savePreflightChecklist(user.id, next);
    }
  }

  Future<void> _generateShotlist() async {
    setState(() {
      _generatingShotlist = true;
      _aiShotlistError = null;
    });
    try {
      final weather = await ref.read(weatherProvider.future);
      final location = await ref.read(locationProvider.future);
      final kp = await ref.read(kpProvider.future);
      final flyScore = await ref.read(flyScoreProvider.future);
      final drone = await ref.read(activeDroneProvider.future);
      final drones = await ref.read(dronesProvider.future);
      final battery = await ref.read(activeBatteryProvider.future);
      final profile = await ref.read(userProfileProvider.future);
      final answer = await ref
          .read(openAIServiceProvider)
          .ask(
            message:
                'Genera un shotlist breve para un vuelo hoy. Usa ubicacion actual, hora local, clima, objetivo ${profile?.mainGoal ?? 'contenido'}, dron activo y bateria disponible. Devuelve 4 tomas con riesgo y consejo de camara.',
            history: const [],
            weather: weather,
            location: location,
            kp: kp,
            flyScore: flyScore,
            drone: drone,
            drones: drones,
            battery: battery,
            pilotLevel: profile?.pilotLevel ?? 'Dato no disponible',
            totalFlightHours: profile?.totalFlightHours ?? 0,
          );
      if (!mounted) return;
      setState(() => _aiShotlist = answer);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aiShotlistError =
            'Aura IA no pudo generar la lista. Modo local activado.';
        _aiShotlist = _localShotlist();
      });
    } finally {
      if (mounted) setState(() => _generatingShotlist = false);
    }
  }

  String _localShotlist() {
    return 'Shotlist local:\n'
        '- Reveal lento desde baja altura, confirma zona libre.\n'
        '- Orbit amplio del sujeto con radio conservador.\n'
        '- Plano cenital corto para contexto.\n'
        '- Dolly out de cierre manteniendo bateria de regreso.';
  }

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);
    final location = ref.watch(locationProvider);
    final drone = ref.watch(activeDroneProvider);
    final battery = ref.watch(activeBatteryProvider);
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planear vuelo'),
        actions: [
          IconButton(
            tooltip: 'Drones',
            onPressed: () => context.go('/drones'),
            icon: const Icon(Icons.flight),
          ),
          IconButton(
            tooltip: 'Baterias',
            onPressed: () => context.go('/batteries'),
            icon: const Icon(Icons.battery_5_bar),
          ),
        ],
      ),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              AuraGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist previa',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (!_loaded) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Cargando checklist'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    for (final item in _checklistItems)
                      CheckboxListTile(
                        value: _checked[item] ?? false,
                        onChanged: (value) => _setChecked(item, value ?? false),
                        title: Text(item),
                        contentPadding: EdgeInsets.zero,
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _resetChecklist,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reiniciar checklist'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AuraGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos reales del vuelo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    location.when(
                      data: (value) => Text(
                        'Ubicacion: ${value.city} (${value.coordinates})',
                      ),
                      loading: () => const Text('Obteniendo ubicacion actual'),
                      error: (error, _) =>
                          Text('Ubicacion no disponible: $error'),
                    ),
                    drone.when(
                      data: (value) =>
                          Text('Dron activo: ${value.brand} ${value.model}'),
                      loading: () => const Text('Leyendo dron activo'),
                      error: (error, _) =>
                          Text('Dron activo no disponible: $error'),
                    ),
                    battery.when(
                      data: (value) => Text(
                        'Bateria activa: ${value.name}, ${value.level}% disponible',
                      ),
                      loading: () => const Text('Leyendo bateria activa'),
                      error: (error, _) =>
                          Text('Bateria activa no disponible: $error'),
                    ),
                    profile.when(
                      data: (value) => Text(
                        'Objetivo: ${value?.mainGoal ?? 'Sin objetivo'}',
                      ),
                      loading: () => const Text('Leyendo objetivo del usuario'),
                      error: (error, _) =>
                          Text('Objetivo no disponible: $error'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              weather.when(
                data: (value) => AuraGlassCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wb_twilight_outlined),
                    title: const Text('Hora dorada en tu ubicación'),
                    subtitle: Text(
                      'Amanecer: ${value.sunrise}\n'
                      'Atardecer: ${value.sunset}\n'
                      'Golden hour mañana: ${value.sunrise} - ${_addMinutes(value.sunrise, 60)}\n'
                      'Golden hour tarde: ${_addMinutes(value.sunset, -60)} - ${value.sunset}',
                    ),
                  ),
                ),
                loading: () => const AuraGlassCard(
                  child: Text('Calculando hora dorada con tu ubicacion'),
                ),
                error: (error, _) => AuraGlassCard(child: Text('$error')),
              ),
              const SizedBox(height: 14),
              Text(
                'Shotlist IA',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              AuraGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _generatingShotlist ? null : _generateShotlist,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        _generatingShotlist
                            ? 'Generando...'
                            : 'Generar shotlist con IA',
                      ),
                    ),
                    if (_aiShotlistError != null) ...[
                      const SizedBox(height: 10),
                      Text(_aiShotlistError!),
                    ],
                    if (_aiShotlist != null) ...[
                      const SizedBox(height: 10),
                      Text(_aiShotlist!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _addMinutes(String hhmm, int minutes) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return '--:--';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return '--:--';
    final date = DateTime(
      2000,
      1,
      1,
      hour,
      minute,
    ).add(Duration(minutes: minutes));
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

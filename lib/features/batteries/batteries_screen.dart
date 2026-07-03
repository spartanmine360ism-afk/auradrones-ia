import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/battery.dart';
import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class BatteriesScreen extends ConsumerWidget {
  const BatteriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteries = ref.watch(batteriesProvider);
    final profile = ref.watch(userProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Baterias')),
      body: AuraBackground(
        child: SafeArea(
          child: batteries.when(
            data: (items) => ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final battery = items[index];
                final active = battery.id == profile?.activeBatteryId;
                final color = battery.level < 30 || battery.cycles > 100
                    ? AuraColors.amber
                    : AuraColors.mint;
                return AuraGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      active ? Icons.check_circle : Icons.battery_charging_full,
                      color: color,
                    ),
                    title: Text(battery.name),
                    subtitle: Text(
                      '${battery.compatibleModel} - ${battery.cycles} ciclos - salud ${battery.health}%',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleAction(context, ref, value, battery),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'active',
                          child: Text('Elegir activa'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatteryForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
    DroneBattery battery,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final data = ref.read(userDataServiceProvider);
    if (value == 'active') {
      await data.setActiveBattery(user.id, battery.id);
      ref.invalidate(userProfileProvider);
    } else if (value == 'edit') {
      await _showBatteryForm(context, ref, battery: battery);
    } else if (value == 'delete') {
      await data.deleteBattery(user.id, battery.id);
      ref.invalidate(batteriesProvider);
    }
  }

  Future<void> _showBatteryForm(
    BuildContext context,
    WidgetRef ref, {
    DroneBattery? battery,
  }) async {
    final name = TextEditingController(text: battery?.name ?? '');
    final model = TextEditingController(text: battery?.compatibleModel ?? '');
    final cycles = TextEditingController(text: '${battery?.cycles ?? 0}');
    final health = TextEditingController(text: '${battery?.health ?? 100}');
    final level = TextEditingController(text: '${battery?.level ?? 100}');
    final lastUse = TextEditingController(text: battery?.lastUse ?? '');
    final lastCharge = TextEditingController(text: battery?.lastCharge ?? '');
    final notes = TextEditingController(text: battery?.notes ?? '');
    String status = battery?.status ?? 'buena';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                battery == null ? 'Agregar bateria' : 'Editar bateria',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: model,
                decoration: const InputDecoration(
                  labelText: 'Modelo compatible',
                ),
              ),
              TextField(
                controller: cycles,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ciclos de carga'),
              ),
              TextField(
                controller: health,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Salud estimada %',
                ),
              ),
              TextField(
                controller: level,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Porcentaje actual',
                ),
              ),
              TextField(
                controller: lastUse,
                decoration: const InputDecoration(labelText: 'Ultimo uso'),
              ),
              TextField(
                controller: lastCharge,
                decoration: const InputDecoration(labelText: 'Ultima carga'),
              ),
              DropdownButtonFormField(
                initialValue: status,
                items: const ['buena', 'revisar', 'reemplazar']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => status = v!,
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notas'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;
                  await ref
                      .read(userDataServiceProvider)
                      .saveBattery(
                        user.id,
                        DroneBattery(
                          id: battery?.id ?? '',
                          name: name.text.trim(),
                          compatibleModel: model.text.trim(),
                          droneId: battery?.droneId,
                          cycles: int.tryParse(cycles.text) ?? 0,
                          health: int.tryParse(health.text) ?? 100,
                          lastCharge: lastCharge.text.trim(),
                          lastUse: lastUse.text.trim(),
                          level: int.tryParse(level.text) ?? 100,
                          status: status,
                          notes: notes.text.trim(),
                        ),
                      );
                  ref.invalidate(batteriesProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

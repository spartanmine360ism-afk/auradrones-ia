import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/drone.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class DronesScreen extends ConsumerWidget {
  const DronesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drones = ref.watch(dronesProvider);
    final profile = ref.watch(userProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Drones')),
      body: AuraBackground(
        child: SafeArea(
          child: drones.when(
            data: (items) => ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final drone = items[index];
                final active = drone.id == profile?.activeDroneId;
                return AuraGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(active ? Icons.check_circle : Icons.flight),
                    title: Text('${drone.brand} ${drone.model}'),
                    subtitle: Text(
                      '${drone.weightGrams} g - ${drone.flightHours} h - ${drone.flightsCount} vuelos',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleAction(context, ref, value, drone),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'active',
                          child: Text('Elegir activo'),
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
        onPressed: () => _showDroneForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
    Drone drone,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final data = ref.read(userDataServiceProvider);
    if (value == 'active') {
      await data.setActiveDrone(user.id, drone.id);
      ref.invalidate(userProfileProvider);
    } else if (value == 'edit') {
      await _showDroneForm(context, ref, drone: drone);
    } else if (value == 'delete') {
      await data.deleteDrone(user.id, drone.id);
      ref.invalidate(dronesProvider);
    }
  }

  Future<void> _showDroneForm(
    BuildContext context,
    WidgetRef ref, {
    Drone? drone,
  }) async {
    final brand = TextEditingController(text: drone?.brand ?? 'DJI');
    final model = TextEditingController(text: drone?.model ?? '');
    final serial = TextEditingController(text: drone?.serialNumber ?? '');
    final weight = TextEditingController(text: '${drone?.weightGrams ?? 249}');
    final hours = TextEditingController(text: '${drone?.flightHours ?? 0}');
    final flights = TextEditingController(text: '${drone?.flightsCount ?? 0}');
    final notes = TextEditingController(text: drone?.notes ?? '');
    String type = drone?.type ?? 'Ligero';
    String status = drone?.status ?? 'Listo';

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
                drone == null ? 'Agregar dron' : 'Editar dron',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                controller: brand,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              TextField(
                controller: model,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              TextField(
                controller: serial,
                decoration: const InputDecoration(labelText: 'Numero de serie'),
              ),
              TextField(
                controller: weight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Peso g'),
              ),
              TextField(
                controller: hours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Horas de vuelo'),
              ),
              TextField(
                controller: flights,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Vuelos realizados',
                ),
              ),
              DropdownButtonFormField(
                initialValue: type,
                items: const ['Ligero', 'Mediano', 'FPV', 'Otro']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => type = v!,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              DropdownButtonFormField(
                initialValue: status,
                items: const ['Listo', 'Revisar', 'Mantenimiento']
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
                      .saveDrone(
                        user.id,
                        Drone(
                          id: drone?.id ?? '',
                          brand: brand.text.trim(),
                          model: model.text.trim(),
                          serialNumber: serial.text.trim(),
                          weightGrams: int.tryParse(weight.text) ?? 0,
                          type: type,
                          flightHours: double.tryParse(hours.text) ?? 0,
                          flightsCount: int.tryParse(flights.text) ?? 0,
                          status: status,
                          nextMaintenance: drone?.nextMaintenance ?? '',
                          purchaseDate: drone?.purchaseDate,
                          notes: notes.text.trim(),
                          photoUrl: drone?.photoUrl,
                          createdAt: drone?.createdAt ?? DateTime.now(),
                        ),
                      );
                  ref.invalidate(dronesProvider);
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

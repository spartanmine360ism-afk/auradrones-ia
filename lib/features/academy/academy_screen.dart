import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Academia Aura')),
      body: AuraBackground(
        child: SafeArea(
          child: lessons.when(
            data: (items) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('Principiante')),
                    Chip(label: Text('Seguridad')),
                    Chip(label: Text('Clima')),
                    Chip(label: Text('Composicion')),
                    Chip(label: Text('Camara')),
                    Chip(label: Text('Normativa')),
                  ],
                ),
                const SizedBox(height: 14),
                for (final lesson in items) ...[
                  AuraGlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.school_outlined),
                      title: Text(lesson.title),
                      subtitle: Text(
                        '${lesson.category} - ${lesson.level} - ${lesson.minutes} min\n${lesson.description}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}

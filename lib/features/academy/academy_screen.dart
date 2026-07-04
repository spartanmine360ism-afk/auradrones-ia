import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/lesson.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';
import '../shared/aura_community_card.dart';

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
                    Chip(label: Text('Movimientos')),
                    Chip(label: Text('Camara')),
                    Chip(label: Text('Edicion')),
                    Chip(label: Text('Composicion')),
                    Chip(label: Text('Normativa')),
                    Chip(label: Text('Mantenimiento')),
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLesson(context, lesson),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const AuraCommunityCard(),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }

  void _showLesson(BuildContext context, Lesson lesson) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '${lesson.category} - ${lesson.level} - ${lesson.minutes} min',
              ),
              const SizedBox(height: 12),
              Text(lesson.description),
              const SizedBox(height: 12),
              const Text('Puntos clave'),
              const SizedBox(height: 6),
              const Text('- Revisa condiciones antes de despegar.'),
              const Text('- Mantente dentro de linea visual.'),
              const Text('- Prioriza bateria de regreso y zona segura.'),
            ],
          ),
        ),
      ),
    );
  }
}

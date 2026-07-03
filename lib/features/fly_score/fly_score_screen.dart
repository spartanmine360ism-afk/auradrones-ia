import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';
import '../../core/widgets/aura_status_badge.dart';

class FlyScoreScreen extends ConsumerWidget {
  const FlyScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(flyScoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Fly Score')),
      body: AuraBackground(
        child: SafeArea(
          child: score.when(
            data: (s) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                AuraGlassCard(
                  child: Column(
                    children: [
                      Text(
                        '${s.value}',
                        style: const TextStyle(
                          fontSize: 86,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AuraStatusBadge(
                        label: s.status,
                        color: s.value >= 80
                            ? AuraColors.mint
                            : AuraColors.amber,
                      ),
                      const SizedBox(height: 16),
                      Text(s.explanation, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(s.recommendation, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AuraGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Factores positivos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final factor in s.positiveFactors)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.check_circle_outline,
                            color: AuraColors.cyan,
                          ),
                          title: Text(factor),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Alertas y restricciones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (s.negativeFactors.isEmpty)
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.verified_outlined,
                            color: AuraColors.mint,
                          ),
                          title: Text('Sin alertas relevantes'),
                        )
                      else
                        for (final factor in s.negativeFactors)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.warning_amber_outlined,
                              color: AuraColors.amber,
                            ),
                            title: Text(factor),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const AuraGlassCard(
                  child: Text(
                    'Antes de volar, confirma la normativa local vigente. Esta app es una herramienta de apoyo, no reemplaza la responsabilidad del piloto.',
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('No se pudo calcular: $error')),
          ),
        ),
      ),
    );
  }
}

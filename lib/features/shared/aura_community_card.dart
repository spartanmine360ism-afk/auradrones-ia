import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/aura_glass_card.dart';

class AuraCommunityCard extends StatelessWidget {
  const AuraCommunityCard({super.key});

  static const _links = [
    _SocialLink(
      name: 'TikTok',
      description: 'Tips rapidos, vuelos y avances de Aura Drones IA.',
      url: 'https://www.tiktok.com/@aldo_auradrones',
      icon: Icons.music_note,
    ),
    _SocialLink(
      name: 'Instagram',
      description: 'Contenido visual, reels y detras de camaras.',
      url: 'https://www.instagram.com/aldo_aurandrones',
      icon: Icons.camera_alt_outlined,
    ),
    _SocialLink(
      name: 'Facebook',
      description: 'Comunidad, novedades y soporte para pilotos.',
      url: 'https://www.facebook.com/profile.php?id=61575643846321',
      icon: Icons.groups_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AuraGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comunidad Aura', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final link in _links)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(link.icon),
              title: Text(link.name),
              subtitle: Text(link.description),
              trailing: TextButton(
                onPressed: () => _open(link.url),
                child: const Text('Seguir'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}

class _SocialLink {
  const _SocialLink({
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
  });

  final String name;
  final String description;
  final String url;
  final IconData icon;
}

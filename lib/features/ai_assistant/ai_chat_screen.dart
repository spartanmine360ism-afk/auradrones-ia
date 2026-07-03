import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/ai_chat_message.dart';
import '../../core/services/providers.dart';
import '../../core/theme/aura_theme.dart';
import '../../core/widgets/aura_background.dart';
import '../../core/widgets/aura_glass_card.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _messages = <AiChatMessage>[
    const AiChatMessage(
      role: 'assistant',
      text: 'Soy Aura IA. Preguntame clima, riesgos, ND o tomas.',
    ),
  ];
  bool _loading = false;
  String? _lastFailedPrompt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? retryText]) async {
    final text = (retryText ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      if (retryText == null) {
        _messages.add(AiChatMessage(role: 'user', text: text));
        _controller.clear();
      }
      _loading = true;
      _lastFailedPrompt = null;
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
            message: text,
            history: _messages,
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
      setState(() {
        _messages.add(AiChatMessage(role: 'assistant', text: answer));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _lastFailedPrompt = text;
        _messages.add(
          AiChatMessage(
            role: 'assistant',
            text: 'Error real de IA\n$error',
            isError: true,
            canRetry: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _clearChat() {
    setState(() {
      _messages
        ..clear()
        ..add(
          const AiChatMessage(
            role: 'assistant',
            text: 'Chat limpio. Preguntame algo concreto para ayudarte.',
          ),
        );
      _lastFailedPrompt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width <= 430 ? 12.0 : 18.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura IA'),
        actions: [
          IconButton(
            tooltip: 'Limpiar chat',
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: AuraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    12,
                  ),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (_loading && index == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _MessageBubble(
                      message: _messages[index],
                      onRetry: _lastFailedPrompt == null
                          ? null
                          : () => _send(_lastFailedPrompt),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Pregunta algo...',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      dimension: 48,
                      child: IconButton.filled(
                        tooltip: 'Enviar',
                        onPressed: _loading ? null : _send,
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onRetry});

  final AiChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: AuraGlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'Tu' : 'Aura IA',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: message.isError ? AuraColors.danger : null,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.25),
              ),
              if (message.canRetry && onRetry != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: AuraGlassCard(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Aura IA responde...'),
          ],
        ),
      ),
    );
  }
}

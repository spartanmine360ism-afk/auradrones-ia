class AiChatMessage {
  const AiChatMessage({
    required this.role,
    required this.text,
    this.isError = false,
    this.canRetry = false,
  });

  final String role;
  final String text;
  final bool isError;
  final bool canRetry;

  bool get isUser => role == 'user';
}

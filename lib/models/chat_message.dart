class ChatMessage {
  final String sender;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.createdAt,
  });
}

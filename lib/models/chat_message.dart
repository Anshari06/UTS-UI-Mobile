class ChatMessage {
  final int id;
  final int ticketId;
  final String userId;
  final String sender;
  final String text;
  final String? attachment;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.sender,
    required this.text,
    this.attachment,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromDb(Map<String, dynamic> row, String senderName) {
    return ChatMessage(
      id: row['id'] as int,
      ticketId: row['ticket_id'] as int,
      userId: row['user_id'] as String,
      sender: senderName,
      text: row['comment'] as String,
      attachment: row['attachment'] as String?,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : DateTime.now(),
    );
  }
}

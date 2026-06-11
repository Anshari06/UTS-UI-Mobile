class AppNotification {
  final int? id;
  final String title;
  final String body; // Maps from 'message' in DB
  final int? ticketId;
  final bool isRead;
  final DateTime createdAt;
  final String? userId; // For helpdesk to see all notifications

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    this.ticketId,
    this.isRead = false,
    required this.createdAt,
    this.userId,
  });

  factory AppNotification.fromDb(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as int?,
      title: row['title'] as String? ?? '',
      body: row['message'] as String? ?? row['body'] as String? ?? '',
      ticketId: row['ticket_id'] as int?,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      userId: row['user_id'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      ticketId: ticketId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      userId: userId,
    );
  }
}
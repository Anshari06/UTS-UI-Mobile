import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/ticket.dart';
import '../models/ticket_history.dart';
import 'ticket_service.dart';
import 'comment_service.dart';
import 'notification_service.dart';

class TicketStore extends ChangeNotifier {
  TicketStore._internal() {
    _nextTicketId = 1;
  }

  static final TicketStore instance = TicketStore._internal();

  final List<Ticket> _tickets = [];
  final Map<int, List<ChatMessage>> _messages = {};
  final Map<int, Map<String, dynamic>> _latestComments = {}; // ticketId -> latest comment
  final List<AppNotification> _notifications = [];
  final List<TicketHistory> _history = [];

  int _nextTicketId = 1;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<TicketHistory> get history => List.unmodifiable(_history);

  // Get latest comment preview for a ticket
  Map<String, dynamic>? getLatestComment(int ticketId) {
    return _latestComments[ticketId];
  }

  final TicketService _ticketService = TicketService();
  final CommentService _commentService = CommentService();
  final NotificationService _notificationService = NotificationService();

  Future<void> fetchTicketsFromDb() async {
    try {
      final dbTickets = await _ticketService.getTickets();
      debugPrint('fetchTicketsFromDb: got ${dbTickets.length} tickets');
      _tickets.clear();

      final List<int> ticketIds = [];

      for (final row in dbTickets) {
        final String statusRaw = row['status'] ?? 'send';
        final String status = statusRaw.isNotEmpty
            ? '${statusRaw[0].toUpperCase()}${statusRaw.substring(1).toLowerCase()}'
            : 'Send';

        final String? priorityRaw = row['priority'];
        final String priority = priorityRaw != null && priorityRaw.isNotEmpty
            ? '${priorityRaw[0].toUpperCase()}${priorityRaw.substring(1).toLowerCase()}'
            : 'Normal';

        final ticket = Ticket(
          id: row['id'] as int,
          title: row['title'] ?? '',
          status: status,
          description: row['description'] ?? '',
          createdBy: row['user_id'] ?? 'user',
          createdAt: row['created_at'] != null
              ? DateTime.parse(row['created_at'] as String)
              : DateTime.now(),
          assignedTo: row['assigned_to'],
          priority: priority,
        );

        _tickets.add(ticket);
        ticketIds.add(ticket.id);
      }

      // Fetch latest comments for all tickets
      if (ticketIds.isNotEmpty) {
        final latestComments = await _commentService.getLatestCommentsForTickets(ticketIds);
        _latestComments.clear();
        _latestComments.addAll(latestComments);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      // Jangan clear list kalau fetch gagal — data lama tetap tampil
    }
  }

  Future<void> fetchNotificationsFromDb() async {
    try {
      final rows = await _notificationService.getNotifications();
      _notifications.clear();
      for (final row in rows) {
        _notifications.add(AppNotification.fromDb(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  // For helpdesk/admin - fetch all notifications
  Future<void> fetchAllNotifications() async {
    try {
      final rows = await _notificationService.getAllNotifications();
      _notifications.clear();
      for (final row in rows) {
        _notifications.add(AppNotification.fromDb(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all notifications: $e');
    }
  }

  // For helpdesk - fetch notifications from users (messages)
  Future<void> fetchHelpdeskNotifications() async {
    try {
      final rows = await _notificationService.getHelpdeskNotifications();
      _notifications.clear();
      for (final row in rows) {
        _notifications.add(AppNotification.fromDb(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching helpdesk notifications: $e');
      // Fallback to all notifications
      await fetchAllNotifications();
    }
  }

  Future<void> fetchHistoryFromDb() async {
    try {
      _history.clear();
      // Fetch all ticket histories
      for (final ticket in _tickets) {
        final rows = await _ticketService.getTicketHistories(ticket.id);
        for (final row in rows) {
          _history.add(TicketHistory(
            ticketId: row['ticket_id'] as int,
            action: row['action'] as String,
            performedBy: row['action_by'] as String? ?? 'Unknown',
            oldValue: row['old_value'] as String?,
            newValue: row['new_value'] as String?,
            createdAt: row['created_at'] != null
                ? DateTime.parse(row['created_at'] as String)
                : DateTime.now(),
          ));
        }
      }
      // Sort by created_at descending (newest first)
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  // For helpdesk - fetch all histories for all tickets
  Future<void> fetchAllHistories() async {
    try {
      _history.clear();
      // Get all tickets (for staff)
      final allTickets = await _ticketService.getAllTickets();
      for (final row in allTickets) {
        final ticketId = row['id'] as int;
        final histories = await _ticketService.getTicketHistories(ticketId);
        for (final historyRow in histories) {
          _history.add(TicketHistory(
            ticketId: historyRow['ticket_id'] as int,
            action: historyRow['action'] as String,
            performedBy: historyRow['action_by'] as String? ?? 'Unknown',
            oldValue: historyRow['old_value'] as String?,
            newValue: historyRow['new_value'] as String?,
            createdAt: historyRow['created_at'] != null
                ? DateTime.parse(historyRow['created_at'] as String)
                : DateTime.now(),
          ));
        }
      }
      // Sort by created_at descending (newest first)
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching all histories: $e');
    }
  }

  Ticket? ticketById(int id) {
    for (final ticket in _tickets) {
      if (ticket.id == id) {
        return ticket;
      }
    }
    return null;
  }

  List<TicketHistory> historyForTicket(int ticketId) {
    return _history.where((h) => h.ticketId == ticketId).toList();
  }

  Future<void> fetchCommentsForTicket(int ticketId) async {
    try {
      final rows = await _commentService.getComments(ticketId);
      final msgs = rows.map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        final senderName = profile != null ? profile['name'] as String? : 'Unknown';
        return ChatMessage.fromDb(row, senderName ?? 'Unknown');
      }).toList();
      _messages[ticketId] = msgs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching comments for ticket $ticketId: $e');
    }
  }

  List<ChatMessage> messagesForTicket(int ticketId) {
    return List.unmodifiable(_messages[ticketId] ?? const []);
  }

  String latestMessagePreview(int ticketId) {
    // First check in-memory messages
    final messages = _messages[ticketId];
    if (messages != null && messages.isNotEmpty) {
      return messages.last.text;
    }

    // Then check latest comment from DB
    final latestComment = _latestComments[ticketId];
    if (latestComment != null) {
      final comment = latestComment['comment'] as String?;
      final profile = latestComment['profiles'] as Map<String, dynamic>?;
      final senderName = profile?['name'] as String?;
      if (comment != null) {
        return comment;
      }
    }

    return 'Belum ada chat';
  }

  // Get sender name for a ticket's latest message
  String latestMessageSender(int ticketId) {
    // First check in-memory messages
    final messages = _messages[ticketId];
    if (messages != null && messages.isNotEmpty) {
      return messages.last.sender;
    }

    // Then check latest comment from DB
    final latestComment = _latestComments[ticketId];
    if (latestComment != null) {
      final profile = latestComment['profiles'] as Map<String, dynamic>?;
      return profile?['name'] as String? ?? 'Unknown';
    }

    return '';
  }

  Future<void> addUserMessage(int ticketId, String text, {String? attachment}) async {
    final commentId = await _commentService.addComment(
      ticketId: ticketId,
      comment: text,
      attachment: attachment,
    );
    if (commentId != null) {
      _messages.putIfAbsent(ticketId, () => []);
      _messages[ticketId]!.add(
        ChatMessage(
          id: commentId,
          ticketId: ticketId,
          userId: 'user',
          sender: 'User',
          text: text,
          attachment: attachment,
          createdAt: DateTime.now(),
        ),
      );
      // Notify helpdesk that user sent a message
      await _notificationService.notifyHelpdesk(
        title: 'Pesan baru dari User',
        body: 'Tiket #$ticketId: $text',
        ticketId: ticketId,
      );
      notifyListeners();
    }
  }

  Future<void> addHelpdeskMessage(int ticketId, String text, {String? attachment}) async {
    final commentId = await _commentService.addComment(
      ticketId: ticketId,
      comment: text,
      attachment: attachment,
    );
    if (commentId != null) {
      _messages.putIfAbsent(ticketId, () => []);
      _messages[ticketId]!.add(
        ChatMessage(
          id: commentId,
          ticketId: ticketId,
          userId: 'helpdesk',
          sender: 'Helpdesk',
          text: text,
          attachment: attachment,
          createdAt: DateTime.now(),
        ),
      );
      // Notify the ticket owner user
      final userId = await _notificationService.getTicketOwnerId(ticketId);
      if (userId != null) {
        await _notificationService.notifyUser(
          userId: userId,
          title: 'Balasan dari Helpdesk',
          body: 'Tiket #$ticketId: $text',
          ticketId: ticketId,
        );
      }
      notifyListeners();
    }
  }

  Future<void> updateStatus(int ticketId, String status) async {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      return;
    }

    final oldStatus = _tickets[index].status;
    _tickets[index] = _tickets[index].copyWith(status: status);

    // Update status in database
    await _ticketService.updateTicketStatus(ticketId, status);

    // Add history to DB
    await _ticketService.addHistory(
      ticketId: ticketId,
      action: 'Status diubah dari $oldStatus ke $status',
      oldValue: oldStatus,
      newValue: status,
    );

    // Notify the ticket owner user with detailed message
    final userId = await _notificationService.getTicketOwnerId(ticketId);
    if (userId != null) {
      await _notificationService.notifyUser(
        userId: userId,
        title: 'Status Tiket Diperbarui',
        body: 'Tiket #$ticketId: Status berubah dari "$oldStatus" menjadi "$status"',
        ticketId: ticketId,
      );
    }

    notifyListeners();
  }

  Future<void> assignTicket(int ticketId, String assignee) async {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      return;
    }

    final oldAssignee = _tickets[index].assignedTo ?? 'Unassigned';
    _tickets[index] = _tickets[index].copyWith(assignedTo: assignee);

    // Update assignee in database
    await _ticketService.assignTicketTo(ticketId, assignee);

    // Add history to DB
    await _ticketService.addHistory(
      ticketId: ticketId,
      action: 'Ditugaskan kepada $assignee',
      oldValue: oldAssignee,
      newValue: assignee,
    );

    // Notify the ticket owner user
    final userId = await _notificationService.getTicketOwnerId(ticketId);
    if (userId != null) {
      await _notificationService.notifyUser(
        userId: userId,
        title: 'Tiket Ditugaskan',
        body: 'Tiket #$ticketId: Ditugaskan kepada $assignee',
        ticketId: ticketId,
      );
    }

    notifyListeners();
  }

  Future<void> unassignTicket(int ticketId) async {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      return;
    }

    final oldAssignee = _tickets[index].assignedTo ?? 'Unassigned';
    _tickets[index] = _tickets[index].copyWith(assignedTo: null);

    // Update assignee to null in database
    await _ticketService.unassignTicket(ticketId);

    // Add history to DB
    await _ticketService.addHistory(
      ticketId: ticketId,
      action: 'Dibatalkan assign dari $oldAssignee',
      oldValue: oldAssignee,
      newValue: 'Unassigned',
    );

    // Notify the ticket owner user
    final userId = await _notificationService.getTicketOwnerId(ticketId);
    if (userId != null) {
      await _notificationService.notifyUser(
        userId: userId,
        title: 'Tiket Tidak Ditugaskan',
        body: 'Tiket #$ticketId: Ticket tersedia untuk diambil kembali',
        ticketId: ticketId,
      );
    }

    notifyListeners();
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    await _notificationService.markAllAsRead();
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}

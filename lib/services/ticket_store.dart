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
  final Map<int, Map<String, dynamic>> _latestComments = {};
  final List<AppNotification> _notifications = [];
  final List<TicketHistory> _history = [];

  int _nextTicketId = 1;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<TicketHistory> get history => List.unmodifiable(_history);

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
          completedAt: row['completed_at'] != null
              ? DateTime.parse(row['completed_at'] as String)
              : null,
          assignedTo: row['assigned_to'],
          priority: priority,
        );

        _tickets.add(ticket);
        ticketIds.add(ticket.id);
      }

      if (ticketIds.isNotEmpty) {
        final latestComments = await _commentService.getLatestCommentsForTickets(ticketIds);
        _latestComments.clear();
        _latestComments.addAll(latestComments);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
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
      await fetchAllNotifications();
    }
  }

  Future<void> fetchHistoryFromDb() async {
    try {
      _history.clear();
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
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  Future<void> fetchAllHistories() async {
    try {
      _history.clear();
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

  Future<void> fetchHistoryForTicket(int ticketId) async {
    try {
      final rows = await _ticketService.getTicketHistories(ticketId);
      final existingIds = _history
          .where((h) => h.ticketId == ticketId)
          .map((h) => '${h.ticketId}_${h.createdAt.millisecondsSinceEpoch}')
          .toSet();

      for (final row in rows) {
        final createdAt = row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now();
        final key = '${row['ticket_id']}_${createdAt.millisecondsSinceEpoch}';
        if (!existingIds.contains(key)) {
          _history.add(TicketHistory(
            ticketId: row['ticket_id'] as int,
            action: row['action'] as String,
            performedBy: row['action_by'] as String? ?? 'Unknown',
            oldValue: row['old_value'] as String?,
            newValue: row['new_value'] as String?,
            createdAt: createdAt,
          ));
        }
      }
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching history for ticket $ticketId: $e');
    }
  }

  List<ChatMessage> messagesForTicket(int ticketId) {
    return List.unmodifiable(_messages[ticketId] ?? const []);
  }

  String latestMessagePreview(int ticketId) {
    final messages = _messages[ticketId];
    if (messages != null && messages.isNotEmpty) {
      return messages.last.text;
    }
    final latestComment = _latestComments[ticketId];
    if (latestComment != null) {
      final comment = latestComment['comment'] as String?;
      if (comment != null) {
        return comment;
      }
    }
    return 'Belum ada chat';
  }

  String latestMessageSender(int ticketId) {
    final messages = _messages[ticketId];
    if (messages != null && messages.isNotEmpty) {
      return messages.last.sender;
    }
    final latestComment = _latestComments[ticketId];
    if (latestComment != null) {
      final profile = latestComment['profiles'] as Map<String, dynamic>?;
      return profile?['name'] as String? ?? '';
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
    var index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      await fetchTicketsFromDb();
      index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    }
    if (index == -1) return;

    final oldStatus = _tickets[index].status;

    DateTime? completedAt;
    if (status.toLowerCase() == 'done') {
      completedAt = DateTime.now();
    }

    _tickets[index] = _tickets[index].copyWith(
      status: status,
      completedAt: completedAt,
    );

    await _ticketService.updateTicketStatus(ticketId, status, completedAt: completedAt);

    await _ticketService.addHistory(
      ticketId: ticketId,
      action: 'Status diubah dari $oldStatus ke $status',
      oldValue: oldStatus,
      newValue: status,
    );

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

  /// Assign ticket to helpdesk. Returns true if success.
  Future<bool> assignTicket(int ticketId, String assignee) async {
    // Fetch from DB if ticket not in local list
    var index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      debugPrint('assignTicket: ticket $ticketId not in local list, fetching...');
      await fetchTicketsFromDb();
      index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    }
    if (index == -1) {
      debugPrint('assignTicket: FAILED — ticket $ticketId still not found');
      return false;
    }

    final oldAssignee = _tickets[index].assignedTo ?? 'Unassigned';
    _tickets[index] = _tickets[index].copyWith(assignedTo: assignee);
    notifyListeners();

    // Update database
    final success = await _ticketService.assignTicketTo(ticketId, assignee);
    if (!success) {
      // Rollback
      _tickets[index] = _tickets[index].copyWith(assignedTo: oldAssignee);
      notifyListeners();
      debugPrint('assignTicket: FAILED — database update returned false');
      return false;
    }

    // Add history
    await _ticketService.addHistory(
      ticketId: ticketId,
      action: 'Ditugaskan kepada $assignee',
      oldValue: oldAssignee,
      newValue: assignee,
    );

    // Notify assigned helpdesk
    await _notificationService.notifyUser(
      userId: assignee,
      title: 'Tiket Ditugaskan',
      body: 'Tiket #$ticketId: Anda ditugaskan untuk menangani tiket ini',
      ticketId: ticketId,
    );

    // Notify ticket owner
    final userId = await _notificationService.getTicketOwnerId(ticketId);
    if (userId != null) {
      await _notificationService.notifyUser(
        userId: userId,
        title: 'Tiket Ditugaskan',
        body: 'Tiket #$ticketId: Ditugaskan kepada $assignee',
        ticketId: ticketId,
      );
    }

    debugPrint('assignTicket: SUCCESS');
    return true;
  }

  /// Unassign ticket. Returns true if success.
  Future<bool> unassignTicket(int ticketId) async {
    var index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      debugPrint('unassignTicket: ticket $ticketId not in local list, fetching...');
      await fetchTicketsFromDb();
      index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    }
    if (index == -1) {
      debugPrint('unassignTicket: FAILED — ticket $ticketId not found');
      return false;
    }

    final oldAssignee = _tickets[index].assignedTo ?? 'Unassigned';
    _tickets[index] = _tickets[index].copyWith(assignedTo: null);
    notifyListeners();

    final success = await _ticketService.unassignTicket(ticketId);
    if (!success) {
      // Rollback
      _tickets[index] = _tickets[index].copyWith(assignedTo: oldAssignee);
      notifyListeners();
      debugPrint('unassignTicket: FAILED — database update returned false');
      return false;
    }

    await _ticketService.addHistory(
      ticketId: ticketId,
      action: 'Dibatalkan assign dari $oldAssignee',
      oldValue: oldAssignee,
      newValue: 'Unassigned',
    );

    final userId = await _notificationService.getTicketOwnerId(ticketId);
    if (userId != null) {
      await _notificationService.notifyUser(
        userId: userId,
        title: 'Tiket Tidak Ditugaskan',
        body: 'Tiket #$ticketId: Ticket tersedia untuk diambil kembali',
        ticketId: ticketId,
      );
    }

    debugPrint('unassignTicket: SUCCESS');
    return true;
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

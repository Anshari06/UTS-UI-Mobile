import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/ticket.dart';
import '../models/ticket_history.dart';

class TicketStore extends ChangeNotifier {
  TicketStore._internal() {
    _tickets.addAll([
      Ticket(
        id: 1,
        title: 'Laptop rusak',
        status: 'Open',
        description: 'Laptop tidak bisa menyala setelah update sistem.',
        createdAt: DateTime(2026, 4, 22, 8, 0),
        createdBy: 'user',
      ),
      Ticket(
        id: 2,
        title: 'WiFi mati',
        status: 'Progress',
        description: 'Jaringan kantor terputus di lantai 2.',
        createdAt: DateTime(2026, 4, 22, 7, 0),
        createdBy: 'user',
        assignedTo: 'Budi',
      ),
      Ticket(
        id: 3,
        title: 'Printer error',
        status: 'Done',
        description: 'Printer area admin sudah selesai diperbaiki.',
        createdAt: DateTime(2026, 4, 21, 9, 0),
        createdBy: 'user',
        assignedTo: 'Ahmad',
      ),
    ]);

    _messages[1] = [
      ChatMessage(
        sender: 'Helpdesk',
        text: 'Halo, tiket Anda sudah kami terima.',
        createdAt: DateTime(2026, 4, 22, 8, 10),
      ),
    ];
    _messages[2] = [
      ChatMessage(
        sender: 'Helpdesk',
        text: 'Tim teknisi sedang menuju lokasi.',
        createdAt: DateTime(2026, 4, 22, 8, 20),
      ),
    ];
    _messages[3] = [
      ChatMessage(
        sender: 'Helpdesk',
        text: 'Permasalahan sudah selesai ditangani.',
        createdAt: DateTime(2026, 4, 22, 8, 30),
      ),
    ];

    _notifications.addAll([
      AppNotification(
        title: 'Tiket #3 selesai',
        body: 'Printer error telah ditutup oleh helpdesk.',
        createdAt: DateTime(2026, 4, 22, 8, 35),
      ),
      AppNotification(
        title: 'Tiket #2 diproses',
        body: 'Helpdesk sedang menangani keluhan WiFi.',
        createdAt: DateTime(2026, 4, 22, 8, 25),
      ),
    ]);

    // Initialize history
    _history.addAll([
      TicketHistory(
        ticketId: 1,
        action: 'Created',
        performedBy: 'user',
        newValue: 'Open',
        timestamp: DateTime(2026, 4, 22, 8, 0),
      ),
      TicketHistory(
        ticketId: 2,
        action: 'Created',
        performedBy: 'user',
        newValue: 'Open',
        timestamp: DateTime(2026, 4, 22, 7, 0),
      ),
      TicketHistory(
        ticketId: 2,
        action: 'Assigned to Budi',
        performedBy: 'help',
        oldValue: 'Unassigned',
        newValue: 'Budi',
        timestamp: DateTime(2026, 4, 22, 7, 30),
      ),
      TicketHistory(
        ticketId: 2,
        action: 'Status Changed',
        performedBy: 'help',
        oldValue: 'Open',
        newValue: 'Progress',
        timestamp: DateTime(2026, 4, 22, 8, 5),
      ),
      TicketHistory(
        ticketId: 3,
        action: 'Created',
        performedBy: 'user',
        newValue: 'Open',
        timestamp: DateTime(2026, 4, 21, 9, 0),
      ),
      TicketHistory(
        ticketId: 3,
        action: 'Assigned to Ahmad',
        performedBy: 'help',
        oldValue: 'Unassigned',
        newValue: 'Ahmad',
        timestamp: DateTime(2026, 4, 21, 10, 0),
      ),
      TicketHistory(
        ticketId: 3,
        action: 'Status Changed',
        performedBy: 'help',
        oldValue: 'Open',
        newValue: 'Progress',
        timestamp: DateTime(2026, 4, 21, 11, 0),
      ),
      TicketHistory(
        ticketId: 3,
        action: 'Status Changed',
        performedBy: 'help',
        oldValue: 'Progress',
        newValue: 'Done',
        timestamp: DateTime(2026, 4, 22, 8, 30),
      ),
    ]);

    _nextTicketId = _tickets.length + 1;
  }

  static final TicketStore instance = TicketStore._internal();

  final List<Ticket> _tickets = [];
  final Map<int, List<ChatMessage>> _messages = {};
  final List<AppNotification> _notifications = [];
  final List<TicketHistory> _history = [];

  int _nextTicketId = 1;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<TicketHistory> get history => List.unmodifiable(_history);

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

  List<ChatMessage> messagesForTicket(int ticketId) {
    return List.unmodifiable(_messages[ticketId] ?? const []);
  }

  String latestMessagePreview(int ticketId) {
    final messages = _messages[ticketId];
    if (messages == null || messages.isEmpty) {
      return 'Belum ada chat';
    }
    return messages.last.text;
  }

  void addTicket({required String title, required String description}) {
    final ticket = Ticket(
      id: _nextTicketId++,
      title: title,
      status: 'Open',
      description: description,
      createdBy: 'user',
    );

    _tickets.insert(0, ticket);
    _messages[ticket.id] = [
      ChatMessage(
        sender: 'Helpdesk',
        text: 'Ticket sudah diterima. Mohon tunggu konfirmasi selanjutnya.',
        createdAt: DateTime.now(),
      ),
    ];

    // Add history
    _history.add(
      TicketHistory(
        ticketId: ticket.id,
        action: 'Created',
        performedBy: 'user',
        newValue: 'Open',
      ),
    );

    _notifications.insert(
      0,
      AppNotification(
        title: 'Tiket baru #${ticket.id}',
        body: ticket.title,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addUserMessage(int ticketId, String text) {
    _messages.putIfAbsent(ticketId, () => []);
    _messages[ticketId]!.add(
      ChatMessage(sender: 'User', text: text, createdAt: DateTime.now()),
    );
    _notifications.insert(
      0,
      AppNotification(
        title: 'Pesan dari user',
        body: 'Tiket #$ticketId: $text',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addHelpdeskMessage(int ticketId, String text) {
    _messages.putIfAbsent(ticketId, () => []);
    _messages[ticketId]!.add(
      ChatMessage(sender: 'Helpdesk', text: text, createdAt: DateTime.now()),
    );
    _notifications.insert(
      0,
      AppNotification(
        title: 'Balasan helpdesk',
        body: 'Tiket #$ticketId: $text',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void updateStatus(int ticketId, String status) {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      return;
    }

    final oldStatus = _tickets[index].status;
    _tickets[index] = _tickets[index].copyWith(status: status);

    // Add history
    _history.add(
      TicketHistory(
        ticketId: ticketId,
        action: 'Status Changed',
        performedBy: 'help',
        oldValue: oldStatus,
        newValue: status,
      ),
    );

    _notifications.insert(
      0,
      AppNotification(
        title: 'Status tiket #$ticketId diperbarui',
        body: 'Sekarang: $status',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void assignTicket(int ticketId, String assignee) {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      return;
    }

    final oldAssignee = _tickets[index].assignedTo ?? 'Unassigned';
    _tickets[index] = _tickets[index].copyWith(assignedTo: assignee);

    // Add history
    _history.add(
      TicketHistory(
        ticketId: ticketId,
        action: 'Assigned to $assignee',
        performedBy: 'help',
        oldValue: oldAssignee,
        newValue: assignee,
      ),
    );

    _notifications.insert(
      0,
      AppNotification(
        title: 'Tiket #$ticketId di-assign',
        body: 'Ditugaskan kepada $assignee',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void unassignTicket(int ticketId) {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1) {
      return;
    }

    final oldAssignee = _tickets[index].assignedTo ?? 'Unassigned';
    _tickets[index] = _tickets[index].copyWith(assignedTo: null);

    // Add history
    _history.add(
      TicketHistory(
        ticketId: ticketId,
        action: 'Unassigned',
        performedBy: 'help',
        oldValue: oldAssignee,
        newValue: 'Unassigned',
      ),
    );

    _notifications.insert(
      0,
      AppNotification(
        title: 'Tiket #$ticketId tidak di-assign',
        body: 'Tiket tersedia untuk diambil',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

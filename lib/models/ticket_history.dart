class TicketHistory {
  final int ticketId;
  final String action;
  final String performedBy;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;

  TicketHistory({
    required this.ticketId,
    required this.action,
    required this.performedBy,
    this.oldValue,
    this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

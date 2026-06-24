class Ticket {
  final int id;
  final String title;
  final String status;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? assignedTo;
  final String? priority;

  Ticket({
    required this.id,
    required this.title,
    required this.status,
    this.description = '',
    this.createdBy = 'user',
    DateTime? createdAt,
    this.completedAt,
    this.assignedTo,
    this.priority = 'Normal',
  }) : createdAt = createdAt ?? DateTime.now();

  Ticket copyWith({
    int? id,
    String? title,
    String? status,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? completedAt,
    String? assignedTo,
    String? priority,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../models/ticket_history.dart';
import '../../services/ticket_store.dart';
import '../../services/ticket_service.dart';
import '../../services/user_service.dart';

// FR-006: Helpdesk menangani tiket yang ditugaskan
// - Update status pengerjaan
// - Memberikan tanggapan / chat
// - Menutup tiket

class HelpdeskTicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const HelpdeskTicketDetailScreen({super.key, required this.ticket});

  @override
  State<HelpdeskTicketDetailScreen> createState() =>
      _HelpdeskTicketDetailScreenState();
}

class _HelpdeskTicketDetailScreenState
    extends State<HelpdeskTicketDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final TicketService _ticketService = TicketService();
  final UserService _userService = UserService();

  bool _isSending = false;
  bool _isLoadingHistory = true;
  List<TicketHistory> _localHistories = [];
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    TicketStore.instance.fetchCommentsForTicket(widget.ticket.id);
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Load profiles untuk resolve UUID → nama
    _profiles = await _userService.getAllUsers();

    // Fetch history langsung dari DB (bukan dari cache TicketStore)
    final rawHistories = await _ticketService.getTicketHistories(widget.ticket.id);
    _localHistories = rawHistories.map((row) {
      return TicketHistory(
        ticketId: row['ticket_id'] as int,
        action: row['action'] as String,
        performedBy: row['action_by'] as String? ?? 'Unknown',
        oldValue: row['old_value'] as String?,
        newValue: row['new_value'] as String?,
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now(),
      );
    }).toList();

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  String _nameFromId(String? id) {
    if (id == null) return 'Unknown';
    try {
      final found = _profiles.firstWhere((p) => p['id'] == id, orElse: () => {});
      return (found['name'] as String?) ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    await TicketStore.instance.addHelpdeskMessage(widget.ticket.id, text);
    _replyController.clear();
    if (mounted) setState(() => _isSending = false);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'send':    return Colors.blueGrey;
      case 'open':    return Colors.green;
      case 'progress': return Colors.orange;
      case 'done':    return Colors.blue;
      default:        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final currentTicket =
            TicketStore.instance.ticketById(widget.ticket.id) ?? widget.ticket;
        final messages = TicketStore.instance.messagesForTicket(currentTicket.id);

        return Scaffold(
          appBar: AppBar(title: Text('Tiket #${currentTicket.id}')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Tiket ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ticket #${currentTicket.id}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(
                                currentTicket.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: _getStatusColor(currentTicket.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentTicket.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentTicket.description.isEmpty
                              ? 'Deskripsi belum diisi.'
                              : currentTicket.description,
                          style: const TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 16),

                        // Assigned info — resolve UUID ke nama
                        if (currentTicket.assignedTo != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 18,
                                    color: Color(0xFF0F766E)),
                                const SizedBox(width: 8),
                                Text(
                                  'Ditugaskan kepada: ${_nameFromId(currentTicket.assignedTo)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Priority
                        if (currentTicket.priority != null &&
                            currentTicket.priority!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(currentTicket.priority!)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Prioritas: ${currentTicket.priority}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(currentTicket.priority!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(),
                        const SizedBox(height: 8),

                        // ── Update Status ──
                        const Text(
                          'Update Status',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatusChip('Send', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Send');
                              _loadAll();
                            }),
                            _buildStatusChip('Open', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Open');
                              _loadAll();
                            }),
                            _buildStatusChip('Progress', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Progress');
                              _loadAll();
                            }),
                            _buildStatusChip('Done', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Done');
                              _loadAll();
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Tracking Status (stepper visual) ──
                const Text(
                  "Tracking Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (_isLoadingHistory)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildTimelineStep(
                    title: "Terkirim (Send)",
                    isActive: true,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Tiket Dibuka (Open)",
                    isActive:
                        currentTicket.status.toLowerCase() == 'open' ||
                        currentTicket.status.toLowerCase() == 'progress' ||
                        currentTicket.status.toLowerCase() == 'done',
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Sedang Diproses (Progress)",
                    isActive:
                        currentTicket.status.toLowerCase() == 'progress' ||
                        currentTicket.status.toLowerCase() == 'done',
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Selesai (Done)",
                    isActive: currentTicket.status.toLowerCase() == 'done',
                    isLast: true,
                  ),
                ],

                // ── Detail Tracking (log aktivitas) ──
                const SizedBox(height: 16),
                if (!_isLoadingHistory && _localHistories.isNotEmpty) ...[
                  const Text(
                    "Log Aktivitas",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (int i = 0; i < _localHistories.length; i++) ...[
                            _buildHistoryItem(_localHistories[i],
                                i == _localHistories.length - 1),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // ── Komunikasi Helpdesk ──
                const Text(
                  "Komunikasi Helpdesk",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        if (messages.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Belum ada pesan.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: messages.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isHelpdesk = message.sender == 'Helpdesk';

                              return Align(
                                alignment: isHelpdesk
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isHelpdesk
                                        ? const Color(0xFF0F766E)
                                            .withValues(alpha: 0.12)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.sender,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(message.text),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                onSubmitted: (_) => _sendReply(),
                                decoration: const InputDecoration(
                                  hintText: 'Balas ke user...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              onPressed: _isSending ? null : _sendReply,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, String currentStatus,
      Future<void> Function() onTap) {
    final isActive = label == currentStatus;
    final color = _getStatusColor(label);

    return ActionChip(
      avatar: Icon(
        _getStatusIcon(label),
        size: 16,
        color: isActive ? Colors.white : color,
      ),
      label: Text(label),
      backgroundColor: isActive ? color : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.black87,
      ),
      onPressed: onTap,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'send':    return Icons.send;
      case 'open':    return Icons.mark_email_unread_outlined;
      case 'progress': return Icons.hourglass_bottom;
      case 'done':    return Icons.check_circle_outline;
      default:        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':   return Colors.red;
      case 'medium': return Colors.orange;
      case 'low':   return Colors.green;
      default:      return Colors.grey;
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? Colors.blue : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getHistoryColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('status')) return Colors.orange;
    if (a.contains('assign') || a.contains('tugaskan')) return Colors.blue;
    if (a.contains('unassign') || a.contains('batal')) return Colors.red;
    if (a.contains('membuat') || a.contains('create')) return Colors.teal;
    if (a.contains('chat') || a.contains('balas')) return Colors.purple;
    return Colors.grey;
  }

  IconData _getHistoryIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('status')) return Icons.update;
    if (a.contains('assign') || a.contains('tugaskan')) return Icons.person_add;
    if (a.contains('unassign') || a.contains('batal')) return Icons.person_remove;
    if (a.contains('membuat') || a.contains('create')) return Icons.add_circle;
    if (a.contains('chat') || a.contains('balas')) return Icons.chat_bubble;
    return Icons.history;
  }

  Widget _buildHistoryItem(TicketHistory history, bool isLast) {
    final performerName = _nameFromId(history.performedBy);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _getHistoryIcon(history.action),
          size: 16,
          color: _getHistoryColor(history.action),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.action,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                '$performerName • ${_formatTime(history.createdAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../models/ticket_history.dart';
import '../../services/ticket_store.dart';
import '../../services/user_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final UserService _userService = UserService();
  bool _isSending = false;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingHistory = true);
    _profiles = await _userService.getAllUsers();
    TicketStore.instance.fetchCommentsForTicket(widget.ticket.id);
    await TicketStore.instance.fetchHistoryForTicket(widget.ticket.id);
    if (mounted) setState(() => _isLoadingHistory = false);
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    await TicketStore.instance.addUserMessage(widget.ticket.id, text);
    _messageController.clear();
    if (mounted) setState(() => _isSending = false);
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
          appBar: AppBar(title: const Text("Detail Tiket")),
          body: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
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
                                      "ID Tiket: #${currentTicket.id}",
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
                                const SizedBox(height: 16),
                                const Text(
                                  "Deskripsi Masalah:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentTicket.description.isEmpty
                                      ? 'Pengguna melaporkan masalah: ${currentTicket.title}.'
                                      : currentTicket.description,
                                  style: const TextStyle(fontSize: 16, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Tracking Status (Step Progress) ──
                        const Text(
                          "Tracking Status",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildStatusStep(
                                  icon: Icons.send,
                                  label: "Send",
                                  isActive: _isStepActive(currentTicket.status, 'send'),
                                  isDone: _isStepDone(currentTicket.status, 'send'),
                                ),
                                _buildConnector(
                                  _isStepDone(currentTicket.status, 'send'),
                                ),
                                _buildStatusStep(
                                  icon: Icons.mark_email_unread_outlined,
                                  label: "Open",
                                  isActive: _isStepActive(currentTicket.status, 'open'),
                                  isDone: _isStepDone(currentTicket.status, 'open'),
                                ),
                                _buildConnector(
                                  _isStepDone(currentTicket.status, 'open'),
                                ),
                                _buildStatusStep(
                                  icon: Icons.hourglass_bottom,
                                  label: "Progress",
                                  isActive: _isStepActive(currentTicket.status, 'progress'),
                                  isDone: _isStepDone(currentTicket.status, 'progress'),
                                ),
                                _buildConnector(
                                  _isStepDone(currentTicket.status, 'progress'),
                                ),
                                _buildStatusStep(
                                  icon: Icons.check_circle_outline,
                                  label: "Done",
                                  isActive: _isStepActive(currentTicket.status, 'done'),
                                  isDone: _isStepDone(currentTicket.status, 'done'),
                                ),
                              ],
                            ),
                          ),
                        ),

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
                                      final isUser = message.sender == 'User';
                                      return Align(
                                        alignment: isUser
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isUser
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
                                        controller: _messageController,
                                        onSubmitted: (_) => _sendMessage(),
                                        decoration: const InputDecoration(
                                          hintText: "Tulis pesan ke helpdesk...",
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton.filled(
                                      onPressed: _isSending ? null : _sendMessage,
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
                ),
        );
      },
    );
  }

  // ── Step progress tracking ──
  bool _isStepDone(String currentStatus, String step) {
    final order = ['send', 'open', 'progress', 'done'];
    final currentIndex = order.indexOf(currentStatus.toLowerCase());
    final stepIndex = order.indexOf(step.toLowerCase());
    return currentIndex > stepIndex;
  }

  bool _isStepActive(String currentStatus, String step) {
    return currentStatus.toLowerCase() == step.toLowerCase();
  }

  Widget _buildStatusStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    final color = isDone
        ? Colors.green
        : isActive
            ? _getStatusColor(label)
            : Colors.grey.shade300;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isDone ? Icons.check : icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isDone || isActive ? Colors.black87 : Colors.grey.shade400,
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SEKARANG',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnector(bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: Container(
        width: 2,
        height: 20,
        color: isDone ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  // ── History tracking ──
  Widget _buildTrackingSection(int ticketId) {
    final histories = TicketStore.instance.historyForTicket(ticketId);

    if (histories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Belum ada aktivitas.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < histories.length; i++)
              _buildTrackingItem(histories[i], i == histories.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingItem(TicketHistory history, bool isLast) {
    final color = _getTrackingColor(history.action);
    final performerName = _nameFromId(history.performedBy);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(_getTrackingIcon(history.action), size: 16, color: color),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.action,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    performerName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(history.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTrackingColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('status')) return Colors.orange;
    if (a.contains('assign') || a.contains('tugaskan')) return Colors.blue;
    if (a.contains('unassign') || a.contains('batal')) return Colors.red;
    if (a.contains('membuat') || a.contains('create')) return Colors.teal;
    if (a.contains('chat') || a.contains('balas')) return Colors.purple;
    return Colors.grey;
  }

  IconData _getTrackingIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('status')) return Icons.update;
    if (a.contains('assign') || a.contains('tugaskan')) return Icons.person_add;
    if (a.contains('unassign') || a.contains('batal')) return Icons.person_remove;
    if (a.contains('membuat') || a.contains('create')) return Icons.add_circle;
    if (a.contains('chat') || a.contains('balas')) return Icons.chat_bubble;
    return Icons.history;
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

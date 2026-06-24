import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../services/ticket_store.dart';

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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    TicketStore.instance.fetchCommentsForTicket(widget.ticket.id);
  }

  @override
  void dispose() {
    _replyController.dispose();
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

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    await TicketStore.instance.addHelpdeskMessage(widget.ticket.id, text);
    _replyController.clear();
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

                        // Assigned info
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
                                  'Ditugaskan kepada: ${currentTicket.assignedTo}',
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
                            }),
                            _buildStatusChip('Open', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Open');
                            }),
                            _buildStatusChip('Progress', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Progress');
                            }),
                            _buildStatusChip('Done', currentTicket.status, () async {
                              await TicketStore.instance
                                  .updateStatus(currentTicket.id, 'Done');
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Percakapan ──
                const Text(
                  'Percakapan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
}

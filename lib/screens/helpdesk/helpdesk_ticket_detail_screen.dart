import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../services/ticket_store.dart';

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
      case 'send':
        return Colors.blueGrey;
      case 'open':
        return Colors.green;
      case 'progress':
        return Colors.orange;
      case 'done':
        return Colors.blue;
      default:
        return Colors.blueGrey;
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

  Widget _buildAssignDropdown(Ticket ticket) {
    return DropdownButtonFormField<String>(
      value: ticket.assignedTo,
      hint: const Text('Pilih staff...'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tidak ada assign'),
        ),
        ..._helpdeskStaff.map(
          (staff) => DropdownMenuItem<String>(value: staff, child: Text(staff)),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          TicketStore.instance.assignTicket(ticket.id, value);
        }
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  final List<String> _helpdeskStaff = [
    'Ahmad',
    'Budi',
    'Citra',
    'Dani',
    'Eka',
    'Fajar',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final currentTicket =
            TicketStore.instance.ticketById(widget.ticket.id) ?? widget.ticket;
        final messages = TicketStore.instance.messagesForTicket(
          currentTicket.id,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Helpdesk Ticket')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              backgroundColor: _getStatusColor(
                                currentTicket.status,
                              ),
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: Icon(
                                Icons.send,
                                size: 16,
                                color: currentTicket.status == 'Send'
                                    ? Colors.white
                                    : Colors.blueGrey,
                              ),
                              label: const Text('Send'),
                              backgroundColor: currentTicket.status == 'Send'
                                  ? Colors.blueGrey
                                  : Colors.grey.shade200,
                              onPressed: () async {
                                await TicketStore.instance.updateStatus(
                                  currentTicket.id,
                                  'Send',
                                );
                              },
                            ),
                            ActionChip(
                              avatar: Icon(
                                Icons.mark_email_unread_outlined,
                                size: 16,
                                color: currentTicket.status == 'Open'
                                    ? Colors.white
                                    : Colors.green,
                              ),
                              label: const Text('Open'),
                              backgroundColor: currentTicket.status == 'Open'
                                  ? Colors.green
                                  : Colors.grey.shade200,
                              onPressed: () async {
                                await TicketStore.instance.updateStatus(
                                  currentTicket.id,
                                  'Open',
                                );
                              },
                            ),
                            ActionChip(
                              avatar: Icon(
                                Icons.hourglass_bottom,
                                size: 16,
                                color: currentTicket.status == 'Progress'
                                    ? Colors.white
                                    : Colors.orange,
                              ),
                              label: const Text('Progress'),
                              backgroundColor: currentTicket.status == 'Progress'
                                  ? Colors.orange
                                  : Colors.grey.shade200,
                              onPressed: () async {
                                await TicketStore.instance.updateStatus(
                                  currentTicket.id,
                                  'Progress',
                                );
                              },
                            ),
                            ActionChip(
                              avatar: Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: currentTicket.status == 'Done'
                                    ? Colors.white
                                    : Colors.blue,
                              ),
                              label: const Text('Done'),
                              backgroundColor: currentTicket.status == 'Done'
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              onPressed: () async {
                                await TicketStore.instance.updateStatus(
                                  currentTicket.id,
                                  'Done',
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_add_alt,
                                    size: 18,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Assign ke',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildAssignDropdown(currentTicket),
                                  ),
                                  if (currentTicket.assignedTo != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed: () {
                                        TicketStore.instance.unassignTicket(
                                          currentTicket.id,
                                        );
                                      },
                                      icon: const Icon(Icons.close),
                                      tooltip: 'Batalkan assign',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.shade100,
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (currentTicket.assignedTo != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Ditugaskan kepada: ${currentTicket.assignedTo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                                'Belum ada pesan dari user.',
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
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
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
                                      if (message.attachment != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lampiran: ${message.attachment}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
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
}
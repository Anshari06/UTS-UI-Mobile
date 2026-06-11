import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../services/ticket_store.dart';
import '../../services/ticket_service.dart';

class TicketTrackingScreen extends StatefulWidget {
  final int ticketId;

  const TicketTrackingScreen({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketTrackingScreen> createState() => _TicketTrackingScreenState();
}

class _TicketTrackingScreenState extends State<TicketTrackingScreen> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> histories = [];
  bool isLoadingHistories = true;

  @override
  void initState() {
    super.initState();
    fetchHistories();
  }

  Future<void> fetchHistories() async {
    final data = await _ticketService.getTicketHistories(widget.ticketId);
    if (mounted) {
      setState(() {
        histories = data;
        isLoadingHistories = false;
      });
    }
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

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final currentTicket =
            TicketStore.instance.ticketById(widget.ticketId) ??
                Ticket(
                  id: widget.ticketId,
                  title: 'Loading...',
                  status: 'Send',
                  description: '',
                  createdBy: 'user',
                );

        final messages = TicketStore.instance.messagesForTicket(widget.ticketId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tracking Ticket'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    isLoadingHistories = true;
                  });
                  fetchHistories();
                  TicketStore.instance.fetchTicketsFromDb();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket Details Card
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
                              ? 'Pengguna melaporkan masalah: ${currentTicket.title}. Mohon segera ditindaklanjuti.'
                              : currentTicket.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Tracking / History Timeline Title
                const Text(
                  "Tracking Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Tracking / History Timeline
                isLoadingHistories
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : histories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "Belum ada riwayat tracking",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: histories.length,
                            itemBuilder: (context, index) {
                              final history = histories[index];
                              final isLast = index == histories.length - 1;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          width: 2,
                                          height: 40,
                                          color: Colors.blue.shade200,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          history['action'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(
                                              history['created_at']),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                const SizedBox(height: 20),

                // Helpdesk Chat Title
                const Text(
                  "Komunikasi Helpdesk",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Helpdesk Chat Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        messages.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  "Belum ada percakapan dengan helpdesk",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                decoration: const InputDecoration(
                                  hintText: "Tulis pesan ke helpdesk...",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              onPressed: () {
                                final text = _messageController.text.trim();
                                if (text.isEmpty) {
                                  return;
                                }
                                TicketStore.instance.addUserMessage(
                                  currentTicket.id,
                                  text,
                                );
                                _messageController.clear();
                              },
                              icon: const Icon(Icons.send),
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

import 'package:flutter/material.dart';
import 'ticket_create_screen.dart';
import 'ticket_tracking_screen.dart';
import '../../services/ticket_store.dart';

// FR-005: User dapat melihat daftar tiket
// FR-011: User dapat tracking status tiket

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await TicketStore.instance.fetchTicketsFromDb();
    if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final tickets = TicketStore.instance.tickets;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Daftar Tiket"),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: tickets.isEmpty
                      ? const Center(
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "Belum ada tiket",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.insights_outlined),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Total tiket: ${tickets.length}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: tickets.length,
                                itemBuilder: (context, index) {
                                  final ticket = tickets[index];
                                  final preview = TicketStore.instance
                                      .latestMessagePreview(ticket.id);
                                  final sender = TicketStore.instance
                                      .latestMessageSender(ticket.id);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: _getStatusColor(
                                          ticket.status,
                                        ).withValues(alpha: 0.15),
                                        child: Icon(
                                          Icons.confirmation_number,
                                          color: _getStatusColor(ticket.status),
                                        ),
                                      ),
                                      title: Text(
                                        ticket.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("ID: #${ticket.id}"),
                                          if (preview.isNotEmpty &&
                                              preview != 'Belum ada chat') ...[
                                            const SizedBox(height: 4),
                                            if (sender.isNotEmpty)
                                              Text(
                                                '$sender: $preview',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          ticket.status,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: _getStatusColor(
                                          ticket.status,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TicketTrackingScreen(
                                                  ticketId: ticket.id,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'ticket_list_fab',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTicketScreen(),
                ),
              );

              if (result != null) {
                // Refresh dari DB setelah tiket dibuat
                await _refresh();
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

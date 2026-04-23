import 'package:flutter/material.dart';
import 'ticket_detail_screen.dart';
import 'ticket_create_screen.dart';
import '../../services/ticket_store.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'progress':
        return Colors.orange;
      case 'done':
        return Colors.blue;
      default:
        return Colors.grey;
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
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTicketScreen(),
                    ),
                  );

                  if (result != null) {
                    TicketStore.instance.addTicket(
                      title: result['title'] ?? 'Tiket Baru',
                      description: result['description'] ?? '',
                    );
                  }
                },
              ),
            ],
          ),
          body: tickets.isEmpty
              ? const Center(child: Text("Belum ada tiket"))
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
                        padding: const EdgeInsets.all(16),
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
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
                              subtitle: Text("ID: #${ticket.id}"),
                              trailing: Chip(
                                label: Text(
                                  ticket.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(ticket.status),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TicketDetailScreen(ticket: ticket),
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
        );
      },
    );
  }
}

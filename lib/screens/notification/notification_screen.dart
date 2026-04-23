import 'package:flutter/material.dart';
import '../../services/ticket_store.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final notifications = TicketStore.instance.notifications;

        return Scaffold(
          appBar: AppBar(title: const Text("Notifikasi")),
          body: notifications.isEmpty
              ? const Center(child: Text('Belum ada notifikasi'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF0F766E,
                          ).withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${notification.body}\n${notification.createdAt.hour.toString().padLeft(2, '0')}:${notification.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

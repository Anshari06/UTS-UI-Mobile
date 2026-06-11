import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../services/ticket_store.dart';
import '../ticket/ticket_detail_screen.dart';
import '../../models/ticket.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    this.isForHelpdesk = false, // True for helpdesk/admin to see all notifications
  });

  final bool isForHelpdesk;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    if (widget.isForHelpdesk) {
      // For helpdesk: fetch notifications from users (messages)
      await TicketStore.instance.fetchHelpdeskNotifications();
    } else {
      // For user: fetch their own notifications
      await TicketStore.instance.fetchNotificationsFromDb();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markAllRead() async {
    await TicketStore.instance.markAllNotificationsAsRead();
  }

  void _onNotificationTap(AppNotification notification) async {
    if (notification.id != null && !notification.isRead) {
      await TicketStore.instance.markNotificationAsRead(notification.id!);
    }

    if (notification.ticketId != null) {
      final ticketId = notification.ticketId!;
      final ticket = TicketStore.instance.ticketById(ticketId);
      if (ticket != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: ticket),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isForHelpdesk ? "Notifikasi Helpdesk" : "Notifikasi"),
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: TicketStore.instance,
            builder: (context, _) {
              final unreadCount = TicketStore.instance.notifications
                  .where((n) => !n.isRead)
                  .length;
              if (unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Baca semua'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: AnimatedBuilder(
          animation: TicketStore.instance,
          builder: (context, _) {
            final notifications = TicketStore.instance.notifications;

            if (notifications.isEmpty && !_isLoading) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada notifikasi",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUnread ? const Color(0xFFE8F5E9).withValues(alpha: 0.5) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnread
                      ? const Color(0xFF0F766E).withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: isUnread
                      ? const Color(0xFF0F766E)
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                              color: isUnread ? Colors.black87 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F766E),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (notification.ticketId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${notification.ticketId}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(AppNotification notification) {
    final lowerTitle = notification.title.toLowerCase();
    if (lowerTitle.contains('status')) {
      return Icons.update;
    } else if (lowerTitle.contains('assign')) {
      return Icons.person_add;
    } else if (lowerTitle.contains('reply') || lowerTitle.contains('balasan')) {
      return Icons.chat_bubble_outline;
    } else if (lowerTitle.contains('pesan')) {
      return Icons.message;
    } else if (lowerTitle.contains('tiket baru')) {
      return Icons.add_circle_outline;
    }
    return notification.isRead ? Icons.notifications_none : Icons.notifications_active;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return "Baru saja";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m lalu";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h lalu";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d lalu";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }
}
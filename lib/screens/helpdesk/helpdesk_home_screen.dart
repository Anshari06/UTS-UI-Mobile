import 'package:flutter/material.dart';

import '../../services/ticket_store.dart';
import '../../services/auth_service.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../ticket/history_screen.dart';
import 'helpdesk_ticket_detail_screen.dart';

// FR-006: Helpdesk dapat melakukan manajemen tiket
// - Melihat semua tiket
// - Update status
// - Assign tiket
// FR-007: Notification - Menampilkan pemberitahuan status tiket
// FR-008: Statistik Tiket - Menampilkan data ringkasan tiket
// FR-010: Riwayat Tiket - Menampilkan riwayat penanganan tiket

class HelpdeskHomeScreen extends StatefulWidget {
  const HelpdeskHomeScreen({super.key});

  @override
  State<HelpdeskHomeScreen> createState() => _HelpdeskHomeScreenState();
}

class _HelpdeskHomeScreenState extends State<HelpdeskHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _statusFilter;

  // User data from database
  String _userName = 'Helpdesk';

  // Status options for filter
  final List<String> _statusOptions = ['Semua', 'Send', 'Open', 'Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTickets();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _authService.getCurrentProfile();
      if (mounted && profile != null) {
        setState(() {
          _userName = profile['name'] ?? 'Helpdesk';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadTickets() async {
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

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final allTickets = TicketStore.instance.tickets;

        // Filter tickets based on selected status
        final filteredTickets = _statusFilter == null || _statusFilter == 'Semua'
            ? allTickets
            : allTickets.where((t) => t.status == _statusFilter).toList();

        final sendCount = allTickets
            .where((ticket) => ticket.status == 'Send')
            .length;
        final openCount = allTickets
            .where((ticket) => ticket.status == 'Open')
            .length;
        final progressCount = allTickets
            .where((ticket) => ticket.status == 'Progress')
            .length;
        final doneCount = allTickets
            .where((ticket) => ticket.status == 'Done')
            .length;

        final pages = [
          Scaffold(
            appBar: AppBar(title: const Text('Dashboard Helpdesk')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message with user data from database
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        child: const Icon(Icons.support_agent, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role: Helpdesk',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ringkasan Tiket',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsCard(
                    title: 'Total Tiket',
                    value: allTickets.length.toString(),
                    icon: Icons.confirmation_number_outlined,
                    color: const Color(0xFF0F766E),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Terkirim',
                    value: sendCount.toString(),
                    icon: Icons.send_outlined,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Open',
                    value: openCount.toString(),
                    icon: Icons.mark_email_unread_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Progress',
                    value: progressCount.toString(),
                    icon: Icons.hourglass_bottom,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Done',
                    value: doneCount.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                       leading: const Icon(Icons.info_outline),
                       title: const Text('Info Cepat Helpdesk'),
                       subtitle: Text(
                         'Terkirim: $sendCount | Open: $openCount | Progress: $progressCount | Done: $doneCount',
                       ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Scaffold(
            appBar: AppBar(title: const Text('Antrian Helpdesk')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: Column(
                children: [
                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: _statusOptions.map((status) {
                        final isSelected = (_statusFilter == null && status == 'Semua') ||
                            _statusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _statusFilter = status == 'Semua' ? null : status;
                              });
                            },
                            selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.2),
                            checkmarkColor: const Color(0xFF0F766E),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Ticket count info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredTickets.length} tiket',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Ticket List
                  Expanded(
                    child: filteredTickets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada tiket',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = filteredTickets[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
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
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket.description.isEmpty
                                            ? 'Belum ada deskripsi'
                                            : ticket.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (ticket.assignedTo != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              ticket.assignedTo!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      ticket.status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(ticket.status),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HelpdeskTicketDetailScreen(ticket: ticket),
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
          ),
          Scaffold(
            appBar: AppBar(title: const Text('Chat Helpdesk')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: filteredTickets.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Belum ada tiket untuk di-chat')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        final preview = TicketStore.instance.latestMessagePreview(
                          ticket.id,
                        );
                        final sender = TicketStore.instance.latestMessageSender(
                          ticket.id,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.12),
                              child: const Icon(Icons.chat_bubble_outline),
                            ),
                            title: Text(
                              ticket.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sender.isNotEmpty)
                                  Text(
                                    sender,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                ticket.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: _getStatusColor(ticket.status),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HelpdeskTicketDetailScreen(ticket: ticket),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          const HistoryScreen(isForHelpdesk: true),
          const NotificationScreen(isForHelpdesk: true),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: 'Antrian',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none),
                selectedIcon: Icon(Icons.notifications),
                label: 'Notif',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
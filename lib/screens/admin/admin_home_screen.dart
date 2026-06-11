import 'package:flutter/material.dart';

import '../../services/ticket_store.dart';
import '../../services/auth_service.dart';
import '../notification/notification_screen.dart';
import '../helpdesk/helpdesk_ticket_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../ticket/history_screen.dart';

// FR-006: Admin dapat melakukan manajemen tiket
// - Melihat semua tiket
// - Update status
// - Assign tiket
// FR-007: Notification - Menampilkan pemberitahuan status tiket
// FR-008: Statistik Tiket - Menampilkan data ringkasan tiket
// FR-010: Riwayat Tiket - Menampilkan riwayat penanganan tiket

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isLoading = false;

  // User data from database
  String _userName = 'Admin';

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
          _userName = profile['name'] ?? 'Admin';
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
        final tickets = TicketStore.instance.tickets;
        final sendCount = tickets
            .where((ticket) => ticket.status.toLowerCase() == 'send')
            .length;
        final openCount = tickets
            .where((ticket) => ticket.status.toLowerCase() == 'open')
            .length;
        final progressCount = tickets
            .where((ticket) => ticket.status.toLowerCase() == 'progress')
            .length;
        final doneCount = tickets
            .where((ticket) => ticket.status.toLowerCase() == 'done')
            .length;

        final pages = [
          Scaffold(
            appBar: AppBar(title: const Text('Dashboard Admin')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message with user data from database
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
                        child: const Icon(Icons.admin_panel_settings, color: Color(0xFFDC2626)),
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
                    'Role: Admin',
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
                    value: tickets.length.toString(),
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
                       title: const Text('Info Cepat Admin'),
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
            appBar: AppBar(title: const Text('Antrian Admin')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: tickets.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Belum ada tiket')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                ticket.status,
                              ).withValues(alpha: 0.15),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: _getStatusColor(ticket.status),
                              ),
                            ),
                            title: Text(
                              ticket.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              ticket.description.isEmpty
                                  ? 'Belum ada deskripsi'
                                  : ticket.description,
                            ),
                            trailing: Chip(
                              label: Text(
                                ticket.status,
                                style: const TextStyle(color: Colors.white),
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
          Scaffold(
            appBar: AppBar(title: const Text('Chat Admin')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: tickets.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Belum ada tiket')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final preview = TicketStore.instance.latestMessagePreview(
                          ticket.id,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFDC2626,
                              ).withValues(alpha: 0.12),
                              child: const Icon(Icons.chat_bubble_outline),
                            ),
                            title: Text(ticket.title),
                            subtitle: Text(preview),
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
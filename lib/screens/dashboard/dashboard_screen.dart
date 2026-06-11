import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../ticket/ticket_create_screen.dart';
import '../ticket/ticket_list_screen.dart';
import '../ticket/history_screen.dart';
import '../../services/ticket_store.dart';
import '../../services/auth_service.dart';

// FR-005: User dapat membuat tiket, upload, lihat daftar, detail, komentar
// FR-008: Statistik Tiket - Menampilkan data ringkasan tiket (total, status)
// FR-010: Riwayat Tiket - Menampilkan riwayat penanganan tiket
// FR-011: Tracking Tiket - User dapat melihat status tracking tiket aktif

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  // User data from database
  String _userName = 'User';
  String _userRole = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    TicketStore.instance.fetchTicketsFromDb();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _authService.getCurrentProfile();
      if (mounted && profile != null) {
        setState(() {
          _userName = profile['name'] ?? 'User';
          _userRole = (profile['role'] as String? ?? 'user')[0].toUpperCase() +
              (profile['role'] as String? ?? 'user').substring(1).toLowerCase();
        });
      }
    } catch (e) {
      // Handle error silently, use default values
    }
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
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
        final totalCount = tickets.length;
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
            appBar: AppBar(title: Text('$_userRole Dashboard')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message with user data from database
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                        child: const Icon(Icons.person, color: Color(0xFF0F766E)),
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
                    'Role: $_userRole',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Ringkasan Tiket",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsCard(
                    title: "Total Tiket",
                    value: totalCount.toString(),
                    icon: Icons.confirmation_number_outlined,
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Terkirim",
                    value: sendCount.toString(),
                    icon: Icons.send_outlined,
                    color: Colors.blueGrey,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Open",
                    value: openCount.toString(),
                    icon: Icons.mark_email_unread_outlined,
                    color: const Color(0xFF16A34A),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Progress",
                    value: progressCount.toString(),
                    icon: Icons.hourglass_bottom,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Done",
                    value: doneCount.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'dashboard_fab',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTicketScreen(),
                  ),
                );

                if (result != null) {
                  // Tiket sudah disimpan ke DB oleh CreateTicketScreen.
                  // Refresh dari DB agar daftar tiket terupdate.
                  await TicketStore.instance.fetchTicketsFromDb();
                  setState(() {
                    _selectedIndex = 1; // Pindah ke tab Daftar Tiket
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
          const TicketListScreen(),
          CreateTicketScreen(
            embeddedMode: true,
            onTicketCreated: (ticketData) async {
              // Tiket sudah tersimpan di DB, refresh store dari DB
              await TicketStore.instance.fetchTicketsFromDb();
              setState(() {
                _selectedIndex = 1; // Pindah ke tab Daftar Tiket
              });
            },
          ),
          const HistoryScreen(),
          const NotificationScreen(),
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
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Tiket',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Buat',
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
import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../ticket/ticket_create_screen.dart';
import '../ticket/ticket_list_screen.dart';
import '../ticket/history_screen.dart';
import '../../services/ticket_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
        final totalCount = tickets.length;
        final openCount = tickets
            .where((ticket) => ticket.status == 'Open')
            .length;
        final progressCount = tickets
            .where((ticket) => ticket.status == 'Progress')
            .length;
        final doneCount = tickets
            .where((ticket) => ticket.status == 'Done')
            .length;

        final pages = [
          Scaffold(
            appBar: AppBar(title: const Text("Dashboard")),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Open",
                    value: openCount.toString(),
                    icon: Icons.mark_email_unread_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Progress",
                    value: progressCount.toString(),
                    icon: Icons.hourglass_bottom,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: "Done",
                    value: doneCount.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
          const TicketListScreen(),
          const CreateTicketScreen(embeddedMode: true),
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

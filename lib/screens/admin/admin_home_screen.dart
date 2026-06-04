import 'package:flutter/material.dart';

import '../../services/ticket_store.dart';
import '../ticket/ticket_list_screen.dart';
import '../profile/profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _users = [
    {'username': 'user', 'email': 'user@email.com', 'active': true},
    {'username': 'help', 'email': 'helpdesk@company.com', 'active': true},
    {'username': 'tester', 'email': 'tester@example.com', 'active': false},
  ];

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(31),
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
        final total = tickets.length;
        final open = tickets.where((t) => t.status == 'Open').length;
        final progress = tickets.where((t) => t.status == 'Progress').length;
        final done = tickets.where((t) => t.status == 'Done').length;

        final pages = [
          // Dashboard
          Scaffold(
            appBar: AppBar(title: const Text('Admin Dashboard')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Sistem',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsCard(
                    title: 'Total Tiket',
                    value: '$total',
                    icon: Icons.confirmation_number_outlined,
                    color: const Color(0xFF0F766E),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Open',
                    value: '$open',
                    icon: Icons.mark_email_unread_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Progress',
                    value: '$progress',
                    icon: Icons.hourglass_bottom,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 10),
                  _buildStatsCard(
                    title: 'Done',
                    value: '$done',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),

          // Tickets
          const TicketListScreen(),

          // Users management
          Scaffold(
            appBar: AppBar(title: const Text('User Management')),
            body: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['username']),
                    subtitle: Text(user['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: user['active'] as bool,
                          onChanged: (v) {
                            setState(() => _users[index]['active'] = v);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() => _users.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Reports (placeholder)
          Scaffold(
            appBar: AppBar(title: const Text('Reports')),
            body: Center(
              child: Text(
                'Laporan sistem akan ditampilkan di sini',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ),

          // Profile
          const ProfileScreen(
            roleLabel: 'Admin',
            displayName: 'Administrator',
            email: 'admin@company.com',
          ),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
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
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reports',
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

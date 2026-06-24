import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../services/ticket_store.dart';
import '../../services/auth_service.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../ticket/history_screen.dart';
import 'helpdesk_ticket_detail_screen.dart';

// FR-006: Helpdesk dapat melakukan pengelolaan tiket
// Flow: Admin assign tiket → Helpdesk tangani → Update status → Tutup tiket
// - Melihat tiket yang ditugaskan (bukan semua tiket)
// - Update status pengerjaan tiket
// - Memberikan tanggapan / chat
// - Menutup tiket

class HelpdeskHomeScreen extends StatefulWidget {
  const HelpdeskHomeScreen({super.key});

  @override
  State<HelpdeskHomeScreen> createState() => _HelpdeskHomeScreenState();
}

class _HelpdeskHomeScreenState extends State<HelpdeskHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isLoadingUser = true;
  String? _statusFilter;

  String _userName = 'Helpdesk';
  String? _userId; // profiles.id (UUID) — untuk compare dengan assignedTo
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
          _userId = profile['id'] as String?; // simpan UUID
          _isLoadingUser = false;
        });
      } else {
        setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    await TicketStore.instance.fetchTicketsFromDb();
    if (mounted) setState(() => _isLoading = false);
  }

  /// Filter tickets assigned to this logged-in helpdesk user
  /// assignedTo di DB = profiles.id (UUID)
  List<Ticket> get _myTickets {
    final all = TicketStore.instance.tickets;
    // Filter: hanya tiket yang assigned ke helpdesk ini (compare UUID)
    final mine = all.where((t) => t.assignedTo == _userId).toList();

    if (_statusFilter == null || _statusFilter == 'Semua') {
      return mine;
    }
    return mine.where((t) => t.status == _statusFilter).toList();
  }

  int get _sendCount => TicketStore.instance.tickets
      .where((t) => t.assignedTo == _userId && t.status == 'Send').length;
  int get _openCount => TicketStore.instance.tickets
      .where((t) => t.assignedTo == _userId && t.status == 'Open').length;
  int get _progressCount => TicketStore.instance.tickets
      .where((t) => t.assignedTo == _userId && t.status == 'Progress').length;
  int get _doneCount => TicketStore.instance.tickets
      .where((t) => t.assignedTo == _userId && t.status == 'Done').length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'send':  return Colors.blueGrey;
      case 'open':  return Colors.green;
      case 'progress': return Colors.orange;
      case 'done':  return Colors.blue;
      default:      return Colors.blueGrey;
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
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final myTickets = _myTickets;

        final pages = [
          // ── Tab 0: Dashboard ──
          Scaffold(
            appBar: AppBar(title: const Text('Dashboard Helpdesk')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                          child: const Icon(Icons.support_agent, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoadingUser ? 'Loading...' : 'Selamat datang,',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Text(
                              _userName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: Helpdesk',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tiket Ditugaskan ke Saya',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hanya tiket yang ditugaskan kepada Anda',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsCard(
                      title: 'Total Ditugaskan',
                      value: TicketStore.instance.tickets
                          .where((t) => t.assignedTo == _userId)
                          .length
                          .toString(),
                      icon: Icons.assignment_ind,
                      color: const Color(0xFF0F766E),
                    ),
                    const SizedBox(height: 10),
                    _buildStatsCard(title: 'Send', value: _sendCount.toString(),
                        icon: Icons.send_outlined, color: Colors.blueGrey),
                    const SizedBox(height: 10),
                    _buildStatsCard(title: 'Open', value: _openCount.toString(),
                        icon: Icons.mark_email_unread_outlined, color: const Color(0xFF16A34A)),
                    const SizedBox(height: 10),
                    _buildStatsCard(title: 'Progress', value: _progressCount.toString(),
                        icon: Icons.hourglass_bottom, color: const Color(0xFFF59E0B)),
                    const SizedBox(height: 10),
                    _buildStatsCard(title: 'Done', value: _doneCount.toString(),
                        icon: Icons.check_circle_outline, color: const Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab 1: Antrian Tiket Saya ──
          Scaffold(
            appBar: AppBar(title: const Text('Tiket Saya')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: Column(
                children: [
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: _statusOptions.map((status) {
                        final isSelected =
                            (_statusFilter == null && status == 'Semua') ||
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('${myTickets.length} tiket ditugaskan ke saya',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: myTickets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  _isLoadingUser
                                      ? 'Memuat...'
                                      : 'Belum ada tiket yang ditugaskan',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (!_isLoadingUser)
                                  Text(
                                    'Admin akan menugaskan tiket ke Anda',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: myTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = myTickets[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(ticket.status)
                                        .withValues(alpha: 0.15),
                                    child: Icon(Icons.confirmation_number,
                                        color: _getStatusColor(ticket.status)),
                                  ),
                                  title: Text(ticket.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket.description.isEmpty
                                            ? 'Tanpa deskripsi'
                                            : ticket.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (ticket.assignedTo != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 12,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 2),
                                            Text(ticket.assignedTo!,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Chip(
                                    label: Text(ticket.status,
                                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: _getStatusColor(ticket.status),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HelpdeskTicketDetailScreen(ticket: ticket),
                                      ),
                                    ).then((_) => _loadTickets());
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

          // ── Tab 2: Chat ──
          Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: myTickets.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Belum ada tiket untuk di-chat',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: myTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = myTickets[index];
                        final preview = TicketStore.instance.latestMessagePreview(ticket.id);
                        final sender = TicketStore.instance.latestMessageSender(ticket.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                              child: const Icon(Icons.chat_bubble_outline),
                            ),
                            title: Text(ticket.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sender.isNotEmpty)
                                  Text(sender,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700)),
                                Text(preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(ticket.status,
                                  style: const TextStyle(color: Colors.white, fontSize: 10)),
                              backgroundColor: _getStatusColor(ticket.status),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HelpdeskTicketDetailScreen(ticket: ticket),
                                ),
                              ).then((_) => _loadTickets());
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),

          // ── Tab 3: Riwayat Aktivitas ──
          const HistoryScreen(isForHelpdesk: true),

          // ── Tab 4: Notifikasi ──
          const NotificationScreen(isForHelpdesk: true),

          // ── Tab 5: Profil ──
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.assignment_ind_outlined),
                  selectedIcon: Icon(Icons.assignment_ind), label: 'Tiket Saya'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history), label: 'Riwayat'),
              NavigationDestination(icon: Icon(Icons.notifications_none),
                  selectedIcon: Icon(Icons.notifications), label: 'Notif'),
              NavigationDestination(icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/ticket_store.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/ticket.dart';
import '../notification/notification_screen.dart';
import '../helpdesk/helpdesk_ticket_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../ticket/history_screen.dart';
import 'user_management_screen.dart';

// FR-007: Admin dapat melakukan manajemen tiket
// Flow: User buat tiket → Admin terima & assign → Helpdesk tangani → Selesai
// - Melihat semua tiket masuk
// - Assign tiket ke helpdesk (assigned_to = profiles.id / UUID)
// - Update status tiket
// - Memberikan respon
// - Mengelola daftar pengguna

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isLoadingUser = true;

  String _userName = 'Admin';
  String? _currentUserId;
  List<Map<String, dynamic>> _helpdeskList = [];

  // Filter state — pakai UUID untuk filter helpdesk
  String? _statusFilter;
  String? _helpdeskFilter; // UUID (profiles.id)

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
          _userName = profile['name'] ?? 'Admin';
          _currentUserId = profile['id'] as String?;
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
    _helpdeskList = await _userService.getHelpdeskList();
    if (mounted) setState(() => _isLoading = false);
  }

  /// Convert UUID → name untuk display
  String _helpdeskNameForId(String? id) {
    if (id == null) return 'Belum ditugaskan';
    try {
      final found = _helpdeskList.firstWhere((h) => h['id'] == id, orElse: () => {});
      return (found['name'] as String?) ?? 'Tidak dikenal';
    } catch (_) {
      return 'Tidak dikenal';
    }
  }

  /// Filter tickets — assignedTo di DB = UUID
  List<Ticket> get _filteredTickets {
    var tickets = TicketStore.instance.tickets;

    if (_statusFilter != null && _statusFilter != 'Semua') {
      tickets = tickets.where((t) => t.status == _statusFilter).toList();
    }

    if (_helpdeskFilter != null && _helpdeskFilter!.isNotEmpty) {
      tickets = tickets.where((t) => t.assignedTo == _helpdeskFilter).toList();
    }

    return tickets;
  }

  int get _sendCount => TicketStore.instance.tickets
      .where((t) => t.status.toLowerCase() == 'send').length;
  int get _openCount => TicketStore.instance.tickets
      .where((t) => t.status.toLowerCase() == 'open').length;
  int get _progressCount => TicketStore.instance.tickets
      .where((t) => t.status.toLowerCase() == 'progress').length;
  int get _doneCount => TicketStore.instance.tickets
      .where((t) => t.status.toLowerCase() == 'done').length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'send':    return Colors.blueGrey;
      case 'open':    return Colors.green;
      case 'progress': return Colors.orange;
      case 'done':    return Colors.blue;
      default:        return Colors.blueGrey;
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

  /// Show assign dialog — assigned_to = profiles.id (UUID)
  Future<void> _showAssignDialog(Ticket ticket) async {
    final formKey = GlobalKey<FormState>();
    final dropdownKey = GlobalKey<FormFieldState<String?>>();
    String? lastSelectedId;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Tugaskan Tiket #${ticket.id}'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.description.isEmpty ? 'Tanpa deskripsi' : ticket.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  FormField<String?>(
                    key: dropdownKey,
                    initialValue: ticket.assignedTo,
                    validator: (v) => null,
                    builder: (field) {
                      lastSelectedId = field.value;
                      return DropdownButtonFormField<String>(
                        value: field.value,
                        decoration: const InputDecoration(
                          labelText: 'Tugaskan ke Helpdesk',
                          prefixIcon: Icon(Icons.person_add_alt),
                        ),
                        items: _helpdeskList.map((h) {
                          final id = h['id'] as String?;
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(h['name'] as String? ?? '-'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          field.didChange(v);
                        },
                      );
                    },
                  ),
                  if (ticket.assignedTo != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        icon: const Icon(Icons.person_remove, color: Colors.red),
                        label: const Text('Lepas Penugasan',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final selectedId = lastSelectedId;
    debugPrint('DEBUG: selectedId=$selectedId, ticket.id=${ticket.id}');

    if (selectedId == null) {
      debugPrint('DEBUG: calling unassignTicket');
      await TicketStore.instance.unassignTicket(ticket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tiket #${ticket.id} dilepas dari penugasan'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint('DEBUG: calling assignTicket with $selectedId');
      final ok = await TicketStore.instance.assignTicket(ticket.id, selectedId);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menugaskan tiket. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tiket #${ticket.id} ditugaskan ke ${_helpdeskNameForId(selectedId)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TicketStore.instance,
      builder: (context, _) {
        final tickets = _filteredTickets;

        final pages = [
          // ── Tab 0: Dashboard ──
          Scaffold(
            appBar: AppBar(title: const Text('Dashboard Admin')),
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
                          backgroundColor: Colors.red.withValues(alpha: 0.15),
                          child: const Icon(Icons.admin_panel_settings, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoadingUser ? 'Loading...' : 'Selamat datang,',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Text(_userName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Role: Admin',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 20),
                    const Text('Ringkasan Tiket',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildStatsCard(
                      title: 'Total Tiket',
                      value: TicketStore.instance.tickets.length.toString(),
                      icon: Icons.confirmation_number_outlined,
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

          // ── Tab 1: Daftar Tiket + Assign ──
          Scaffold(
            appBar: AppBar(title: const Text('Semua Tiket')),
            body: RefreshIndicator(
              onRefresh: _loadTickets,
              child: Column(
                children: [
                  // Status filter chips
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
                            onSelected: (_) {
                              setState(() {
                                _statusFilter = status == 'Semua' ? null : status;
                              });
                            },
                            selectedColor: Colors.red.withValues(alpha: 0.15),
                            checkmarkColor: Colors.red,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Helpdesk filter chips — filter by UUID
                  if (_helpdeskList.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text(_helpdeskFilter == null
                                ? 'Semua Helpdesk'
                                : _helpdeskNameForId(_helpdeskFilter)),
                            selected: _helpdeskFilter != null,
                            onSelected: (_) {
                              setState(() => _helpdeskFilter = null);
                            },
                            selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                            checkmarkColor: const Color(0xFF0F766E),
                          ),
                          ..._helpdeskList.map((h) {
                            final id = h['id'] as String?;
                            final name = h['name'] as String?;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(name ?? '-'),
                                selected: _helpdeskFilter == id,
                                onSelected: (_) {
                                  setState(() => _helpdeskFilter = id);
                                },
                                selectedColor:
                                    const Color(0xFF0F766E).withValues(alpha: 0.15),
                                checkmarkColor: const Color(0xFF0F766E),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${tickets.length} tiket',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: tickets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('Belum ada tiket',
                                    style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: tickets.length,
                            itemBuilder: (context, index) {
                              final ticket = tickets[index];
                              final assignedName = _helpdeskNameForId(ticket.assignedTo);
                              final isAssigned = ticket.assignedTo != null;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showAssignDialog(ticket),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(ticket.title,
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '#${ticket.id}',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Chip(
                                              label: Text(ticket.status,
                                                  style: const TextStyle(
                                                      color: Colors.white, fontSize: 11)),
                                              backgroundColor:
                                                  _getStatusColor(ticket.status),
                                            ),
                                          ],
                                        ),
                                        if (ticket.description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(ticket.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 12, color: Colors.grey.shade700)),
                                        ],
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isAssigned
                                                ? const Color(0xFF0F766E).withValues(alpha: 0.1)
                                                : Colors.amber.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isAssigned
                                                    ? Icons.person
                                                    : Icons.person_off_outlined,
                                                size: 14,
                                                color: isAssigned
                                                    ? const Color(0xFF0F766E)
                                                    : Colors.amber.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                assignedName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isAssigned
                                                      ? const Color(0xFF0F766E)
                                                      : Colors.amber.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.touch_app, size: 12,
                                                color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text('Tap untuk assign / ubah helpdesk',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
              child: TicketStore.instance.tickets.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Belum ada tiket',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: TicketStore.instance.tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = TicketStore.instance.tickets[index];
                        final preview = TicketStore.instance.latestMessagePreview(ticket.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.withValues(alpha: 0.12),
                              child: const Icon(Icons.chat_bubble_outline),
                            ),
                            title: Text(ticket.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
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

          // ── Tab 4: Kelola Pengguna ──
          const UserManagementScreen(),

          // ── Tab 5: Notifikasi ──
          const NotificationScreen(isForHelpdesk: true),

          // ── Tab 6: Profil ──
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
              NavigationDestination(icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment), label: 'Tiket'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history), label: 'Riwayat'),
              NavigationDestination(icon: Icon(Icons.people_outlined),
                  selectedIcon: Icon(Icons.people), label: 'Pengguna'),
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

/// Mutable wrapper untuk hasil dialog assign
class _AssignDialogResult {
  bool confirmed = false;
  String? selectedId;
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/theme_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.roleLabel,
    this.displayName,
    this.email,
  });

  // Parameter opsional - jika tidak diisi, akan load dari database
  final String? roleLabel;
  final String? displayName;
  final String? email;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;

  // Data dari database
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _authService.getCurrentProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _displayName {
    if (widget.displayName != null) return widget.displayName!;
    return _profile?['name'] ?? 'User';
  }

  String get _email {
    if (widget.email != null) return widget.email!;
    // Build email from username for display
    final name = _profile?['name'] ?? 'user';
    return '$name@main.com';
  }

  String get _roleLabel {
    if (widget.roleLabel != null) return widget.roleLabel!;
    final role = _profile?['role'] as String? ?? 'user';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(_roleLabel).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getRoleColor(_roleLabel).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _roleLabel,
                              style: TextStyle(
                                color: _getRoleColor(_roleLabel),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Avatar
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: _getRoleColor(_roleLabel).withValues(alpha: 0.15),
                            child: Icon(
                              _getRoleIcon(_roleLabel),
                              size: 44,
                              color: _getRoleColor(_roleLabel),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          if (_profile?['created_at'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Bergabung: ${_formatDate(_profile!['created_at'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.brightness_6_outlined),
                          title: const Text("Tema"),
                          subtitle: Text(
                            ThemeManager.instance.isDarkMode
                                ? 'Dark Mode'
                                : 'Light Mode',
                          ),
                          trailing: Switch(
                            value: ThemeManager.instance.isDarkMode,
                            onChanged: (_) {
                              ThemeManager.instance.toggleTheme();
                              setState(() {});
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text("Notifikasi"),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Fitur notifikasi sedang dikembangkan"),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.security_outlined),
                          title: const Text("Keamanan"),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Fitur keamanan sedang dikembangkan"),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text("Bantuan & Dukungan"),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Hubungi helpdesk kami untuk bantuan"),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text("Tentang Aplikasi"),
                          subtitle: const Text("Versi 1.0.0"),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            _showAboutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      onPressed: () async {
                        // FR-002: Logout - Pengguna dapat logout dari aplikasi
                        await AuthService().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFDC2626); // Red
      case 'helpdesk':
        return const Color(0xFF2563EB); // Blue
      case 'user':
        return const Color(0xFF16A34A); // Green
      default:
        return const Color(0xFF0F766E); // Teal
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'helpdesk':
        return Icons.support_agent;
      case 'user':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tentang Aplikasi"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "E-Ticketing Mobile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text("Versi: 1.0.0"),
              SizedBox(height: 16),
              Text(
                "Aplikasi sistem manajemen tiket untuk memudahkan komunikasi antara user dan helpdesk dalam menangani permintaan layanan.",
              ),
              SizedBox(height: 16),
              Text(
                "© 2026 Universitas Airlangga",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}
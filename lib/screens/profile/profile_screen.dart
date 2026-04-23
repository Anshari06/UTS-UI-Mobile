import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../services/theme_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.roleLabel = 'User',
    this.displayName = 'Nama User',
    this.email = 'user@email.com',
  });

  final String roleLabel;
  final String displayName;
  final String email;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Chip(label: Text(widget.roleLabel)),
                    const SizedBox(height: 16),
                    const CircleAvatar(
                      radius: 42,
                      child: Icon(Icons.person, size: 44),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
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
                onPressed: () {
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

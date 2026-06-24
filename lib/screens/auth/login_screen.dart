import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../helpdesk/helpdesk_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

// FR-001: Login - Pengguna dapat login menggunakan username dan password
// FR-002: Logout - Pengguna dapat logout dari aplikasi
// FR-003: Register - Pengguna dapat melakukan pendaftaran aplikasi
// FR-004: Reset Password - Pengguna dapat reset password

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF6F5), Color(0xFFF6F8FB)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selamat Datang",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Masuk untuk melanjutkan ke sistem e-ticketing.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Login menggunakan akun yang terdaftar di database.",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username Field
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), 

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();

                          if (username.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Username dan password harus diisi!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          final error = await _authService.login(
                            username: username,
                            password: password,
                          );

                          if (!mounted) return;
                          setState(() => _isLoading = false);

                          if (error != null) {
                            String errorMessage;
                            final lowerError = error.toLowerCase();

                            // Cek email belum verifikasi
                            if (lowerError.contains('not confirmed') ||
                                lowerError.contains('email not confirmed')) {
                              errorMessage = 'Email belum diverifikasi. Cek inbox email Anda.';
                            }
                            // Cek rate limit
                            else if (lowerError.contains('rate limit') ||
                                lowerError.contains('too many')) {
                              errorMessage = 'Terlalu banyak percobaan. Tunggu sebentar.';
                            }
                            // Invalid login = username atau password salah
                            else if (lowerError.contains('invalid login credentials') ||
                                lowerError.contains('no user') ||
                                lowerError.contains('not found') ||
                                lowerError.contains('user not found')) {
                              errorMessage = 'Username atau password salah!';
                            }
                            // Fallback
                            else {
                              errorMessage = 'Login gagal. Pastikan username dan password benar.';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(errorMessage)),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            final profile = await _authService
                                .getCurrentProfile();

                            if (!mounted) return;

                            String role = 'user';

                            // If profile doesn't exist, create one
                            if (profile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Membuat profile baru...'),
                                ),
                              );
                              // Try to get role from user metadata or default to 'user'
                              role = 'user';
                            } else {
                              role = (profile['role'] as String?)
                                  ?.trim()
                                  .toLowerCase() ?? 'user';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login berhasil')),
                            );

                            if (role == 'helpdesk' || role == 'help') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpdeskHomeScreen(),
                                ),
                              );
                            } else if (role == 'admin') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminHomeScreen(),
                                ),
                              );
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DashboardScreen(),
                                ),
                              );
                            }
                          }
                        },
                        child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Login"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot Password & Register Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ResetPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lupa Password?",
                            style: TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Daftar Akun",
                            style: TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

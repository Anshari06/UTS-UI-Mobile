import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  int _currentStep = 0; // 0: Email, 1: Verification, 2: New Password
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lupa Password"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                    // Step Indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          _buildStepCircle(1, "Email"),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: _currentStep >= 1
                                  ? const Color(0xFF0F766E)
                                  : Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          _buildStepCircle(2, "Verifikasi"),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: _currentStep >= 2
                                  ? const Color(0xFF0F766E)
                                  : Colors.grey.shade300,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          _buildStepCircle(3, "Password"),
                        ],
                      ),
                    ),

                    if (_currentStep == 0) ...[
                      const Text(
                        "Masukkan Email",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Kami akan mengirimkan kode verifikasi ke email Anda",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: "nama@email.com",
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleEmailSubmit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("Kirim Kode Verifikasi"),
                          ),
                        ),
                      ),
                    ] else if (_currentStep == 1) ...[
                      const Text(
                        "Verifikasi Email",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Masukkan kode verifikasi yang dikirim ke ${emailController.text}",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: "Kode Verifikasi",
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                          hintText: "Contoh: 123456",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleVerificationSubmit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("Verifikasi"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 0),
                          child: const Text("Kembali"),
                        ),
                      ),
                    ] else if (_currentStep == 2) ...[
                      const Text(
                        "Buat Password Baru",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Masukkan password baru Anda",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: newPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: "Password Baru",
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
                          hintText: "Minimal 6 karakter",
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: "Konfirmasi Password",
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
                          hintText: "Masukkan ulang password",
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handlePasswordReset,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("Reset Password"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 1),
                          child: const Text("Kembali"),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Kembali ke Login",
                          style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildStepCircle(int step, String label) {
    final isActive = step <= _currentStep + 1;
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isActive
              ? const Color(0xFF0F766E)
              : Colors.grey.shade300,
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _handleEmailSubmit() async {
    // FR-004: Reset Password - Request password reset
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email harus diisi")));
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email tidak valid")));
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.requestPasswordReset(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kode verifikasi telah dikirim ke email")),
    );

    setState(() => _currentStep = 1);
  }

  void _handleVerificationSubmit() {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kode verifikasi harus diisi")),
      );
      return;
    }

    // Mock verification - in real app, verify with backend
    if (code.length >= 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email terverifikasi")));
      setState(() => _currentStep = 2);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kode tidak valid")));
    }
  }

  void _handlePasswordReset() async {
    // FR-004: Reset Password - Set new password
    final password = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password harus diisi")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 6 karakter")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password tidak cocok")));
      return;
    }

    setState(() => _isLoading = true);

    // Update password untuk user yang sedang login
    final error = await _authService.updatePassword(newPassword: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Password berhasil direset!")));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

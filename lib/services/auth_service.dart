import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  String _buildEmailFromUsername(String username) {
    final normalized = username.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '.',
    );
    return '$normalized@uts-mobile.local';
  }

  Future<String?> register({
    required String username,
    required String password,
  }) async {
    try {
      final email = _buildEmailFromUsername(username);

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'name': username,
          'role': 'user',
        });
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    try {
      final email = _buildEmailFromUsername(username);

      await supabase.auth.signInWithPassword(email: email, password: password);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // FR-004: Reset Password - Pengguna dapat reset password
  // Menggunakan Supabase Auth untuk reset password via email
  Future<String?> requestPasswordReset({required String email}) async {
    try {
      // Konversi username ke format email internal jika perlu
      String targetEmail = email;
      if (!email.contains('@')) {
        targetEmail = _buildEmailFromUsername(email);
      }

      // Kirim reset password email via Supabase
      await supabase.auth.resetPasswordForEmail(targetEmail);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Update password untuk user yang sedang login
  Future<String?> updatePassword({required String newPassword}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return 'User belum login';
      }

      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Get user role from database
  Future<String> getUserRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 'user';

      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return (profile['role'] as String?)?.toLowerCase() ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  // Create user with specific role (for admin to create helpdesk/admin)
  Future<String?> createUserWithRole({
    required String username,
    required String password,
    required String role,
    String? email,
  }) async {
    try {
      final userEmail = email ?? _buildEmailFromUsername(username);

      final response = await supabase.auth.signUp(
        email: userEmail,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'name': username,
          'role': role,
          'email': userEmail,
        });
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Update user profile
  Future<String?> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 'User belum login';

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;

      if (updates.isNotEmpty) {
        await supabase
            .from('profiles')
            .update(updates)
            .eq('id', user.id);
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

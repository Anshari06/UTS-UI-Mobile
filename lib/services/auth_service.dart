import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  String _buildEmailFromUsername(String username) {
    return '${username.trim().toLowerCase()}@mail.com';
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
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('getCurrentProfile: user is null');
        return null;
      }

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('getCurrentProfile error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

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

  /// Kirim email reset password via Supabase Auth
  Future<String?> sendResetPasswordEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email.toLowerCase().trim());
      return null;
    } catch (e) {
      debugPrint('sendResetPasswordEmail error: $e');
      return e.toString();
    }
  }

  Future<String?> updateProfile({
    String? name,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 'User belum login';

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;

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

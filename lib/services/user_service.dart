import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final supabase = Supabase.instance.client;

  /// Ambil semua user dari tabel profiles
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  /// Ambil daftar helpdesk (role = 'helpdesk') untuk dropdown assign
  Future<List<Map<String, dynamic>>> getHelpdeskList() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('role', 'helpdesk')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getHelpdeskList error: $e');
      return [];
    }
  }

  /// Update role user
  Future<String?> updateUserRole(String userId, String newRole) async {
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole.toLowerCase()})
          .eq('id', userId);
      return null;
    } catch (e) {
      debugPrint('updateUserRole error: $e');
      return e.toString();
    }
  }

  /// Update nama user
  Future<String?> updateUserName(String userId, String newName) async {
    try {
      await supabase
          .from('profiles')
          .update({'name': newName})
          .eq('id', userId);
      return null;
    } catch (e) {
      debugPrint('updateUserName error: $e');
      return e.toString();
    }
  }

  /// Hapus user (hapus dari profiles — auth user tetap ada tapi tak punya profile)
  Future<String?> deleteUser(String userId) async {
    try {
      await supabase.from('profiles').delete().eq('id', userId);
      return null;
    } catch (e) {
      debugPrint('deleteUser error: $e');
      return e.toString();
    }
  }

  /// Buat user baru via Supabase Auth + insert profile
  /// Email otomatis: username@mail.com
  Future<String?> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final email = '${username.trim().toLowerCase()}@mail.com';

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return 'Gagal membuat user';

      await supabase.from('profiles').insert({
        'id': user.id,
        'name': username,
        'role': role.toLowerCase(),
      });

      return null;
    } catch (e) {
      debugPrint('createUser error: $e');
      return e.toString();
    }
  }
}

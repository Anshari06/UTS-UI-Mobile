import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class CommentService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getComments(int ticketId) async {
    try {
      final response = await supabase
          .from('ticket_comments')
          .select('*, profiles(name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getComments error: $e');
      return [];
    }
  }

  // Get latest comment for each ticket (for preview)
  Future<Map<int, Map<String, dynamic>>> getLatestCommentsForTickets(
    List<int> ticketIds,
  ) async {
    final result = <int, Map<String, dynamic>>{};

    if (ticketIds.isEmpty) return result;

    try {
      for (final ticketId in ticketIds) {
        final response = await supabase
            .from('ticket_comments')
            .select('*, profiles(name)')
            .eq('ticket_id', ticketId)
            .order('created_at', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          result[ticketId] = response.first;
        }
      }
    } catch (e) {
      debugPrint('getLatestCommentsForTickets error: $e');
    }

    return result;
  }

  // Get latest comment for a single ticket
  Future<Map<String, dynamic>?> getLatestComment(int ticketId) async {
    try {
      final response = await supabase
          .from('ticket_comments')
          .select('*, profiles(name)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      debugPrint('getLatestComment error: $e');
      return null;
    }
  }

  Future<int?> addComment({
    required int ticketId,
    required String comment,
    String? attachment,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('ticket_comments')
          .insert({
            'ticket_id': ticketId,
            'user_id': user.id,
            'comment': comment,
            'attachment': attachment,
            'is_read': false,
          })
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('addComment error: $e');
      return null;
    }
  }

  Future<void> markAsRead(int commentId) async {
    try {
      await supabase
          .from('ticket_comments')
          .update({'is_read': true})
          .eq('id', commentId);
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsReadForTicket(int ticketId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('ticket_comments')
          .update({'is_read': true})
          .eq('ticket_id', ticketId)
          .neq('user_id', user.id);
    } catch (e) {
      debugPrint('markAllAsReadForTicket error: $e');
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketService {
  final supabase = Supabase.instance.client;

  Future<void> addHistory({
    required int ticketId,
    required String action,
    String? oldValue,
    String? newValue,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      await supabase.from('ticket_histories').insert({
        'ticket_id': ticketId,
        'action': action,
        'action_by': user.id,
        'old_value': oldValue,
        'new_value': newValue,
      });
    } catch (e) {
      // Handle error or print
    }
  }

  Future<String?> createTicket({
    required String title,
    required String description,
  }) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return 'User tidak login';
      }

      final response = await supabase
          .from('tickets')
          .insert({
            'user_id': user.id,
            'title': title,
            'description': description,
            'status': 'send',
            'priority': 'medium',
          })
          .select()
          .single();

      final ticketId = response['id'] as int;

      await addHistory(
        ticketId: ticketId,
        action: 'Membuat tiket',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getTicketHistories(int ticketId) async {
    try {
      final response = await supabase
          .from('ticket_histories')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Update ticket status in database
  Future<bool> updateTicketStatus(int ticketId, String status, {DateTime? completedAt}) async {
    try {
      final updateData = <String, dynamic>{'status': status.toLowerCase()};
      if (completedAt != null) {
        updateData['completed_at'] = completedAt.toIso8601String();
      }
      await supabase
          .from('tickets')
          .update(updateData)
          .eq('id', ticketId);
      return true;
    } catch (e) {
      debugPrint('updateTicketStatus error: $e');
      return false;
    }
  }

  // Update assigned_to in database
  Future<bool> assignTicketTo(int ticketId, String assignee) async {
    try {
      await supabase
          .from('tickets')
          .update({'assigned_to': assignee})
          .eq('id', ticketId);
      return true;
    } catch (e) {
      debugPrint('assignTicketTo error: $e');
      return false;
    }
  }

  // Unassign ticket in database
  Future<bool> unassignTicket(int ticketId) async {
    try {
      await supabase
          .from('tickets')
          .update({'assigned_to': null})
          .eq('id', ticketId);
      return true;
    } catch (e) {
      debugPrint('unassignTicket error: $e');
      return false;
    }
  }

  // Get all tickets without role check (for internal use)
  Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      final response = await supabase
          .from('tickets')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getAllTickets error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTickets() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('getTickets: user is null');
      return [];
    }

    try {
      // Check if profiles table has role column
      String? role;
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          role = (profile['role'] as String?)?.trim().toLowerCase();
          debugPrint('getTickets: user role = $role');
        }
      } catch (e) {
        debugPrint('getTickets: profiles query failed: $e');
        role = null;
      }

      if (role == 'helpdesk' || role == 'admin' || role == 'help') {
        final response = await supabase
            .from('tickets')
            .select()
            .order('created_at', ascending: false);
        debugPrint('getTickets: staff mode, ${response.length} tickets');
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint('getTickets: role check failed: $e');
    }

    // Default: Return only own tickets for regular user
    var response = await supabase
        .from('tickets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // Fallback: if own tickets empty, fetch all (for debugging)
    if (response.isEmpty) {
      debugPrint('getTickets: own tickets empty, fetching all tickets');
      response = await supabase
          .from('tickets')
          .select()
          .order('created_at', ascending: false);
    }

    debugPrint('getTickets: ${response.length} tickets');
    return List<Map<String, dynamic>>.from(response);
  }
}

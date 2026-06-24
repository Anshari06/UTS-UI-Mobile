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
      debugPrint('addHistory error: $e');
    }
  }

  Future<String?> createTicket({
    required String title,
    required String description,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 'User tidak login';

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
      await addHistory(ticketId: ticketId, action: 'Membuat tiket');

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

  Future<bool> updateTicketStatus(int ticketId, String status, {DateTime? completedAt}) async {
    try {
      final updateData = <String, dynamic>{'status': status.toLowerCase()};
      if (completedAt != null) {
        updateData['completed_at'] = completedAt.toIso8601String();
      }
      await supabase.from('tickets').update(updateData).eq('id', ticketId);
      return true;
    } catch (e) {
      debugPrint('updateTicketStatus error: $e');
      return false;
    }
  }

  Future<bool> assignTicketTo(int ticketId, String assignee) async {
    debugPrint('assignTicketTo: ticketId=$ticketId, assignee=$assignee');
    try {
      await supabase.from('tickets').update({'assigned_to': assignee}).eq('id', ticketId);

      // Verify
      final verify = await supabase
          .from('tickets')
          .select('assigned_to')
          .eq('id', ticketId)
          .maybeSingle();
      debugPrint('assignTicketTo verify: assigned_to = ${verify?['assigned_to']}');
      if (verify == null) {
        debugPrint('assignTicketTo: ticket not found after update');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('assignTicketTo error: $e');
      return false;
    }
  }

  Future<bool> unassignTicket(int ticketId) async {
    debugPrint('unassignTicket: ticketId=$ticketId');
    try {
      await supabase.from('tickets').update({'assigned_to': null}).eq('id', ticketId);

      final verify = await supabase
          .from('tickets')
          .select('assigned_to')
          .eq('id', ticketId)
          .maybeSingle();
      debugPrint('unassignTicket verify: assigned_to = ${verify?['assigned_to']}');
      return true;
    } catch (e) {
      debugPrint('unassignTicket error: $e');
      return false;
    }
  }

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
    if (user == null) return [];

    try {
      String? role;
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          role = (profile['role'] as String?)?.trim().toLowerCase();
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
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint('getTickets: role check failed: $e');
    }

    var response = await supabase
        .from('tickets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (response.isEmpty) {
      response = await supabase
          .from('tickets')
          .select()
          .order('created_at', ascending: false);
    }

    return List<Map<String, dynamic>>.from(response);
  }
}

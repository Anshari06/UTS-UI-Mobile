import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final supabase = Supabase.instance.client;

  // Get notifications for current user (for regular user)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final response = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getNotifications error: $e');
      return [];
    }
  }

  // Get all notifications (for helpdesk/admin - all notifications)
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getAllNotifications error: $e');
      return [];
    }
  }

  // Get notifications for helpdesk (messages from users and system notifications)
  Future<List<Map<String, dynamic>>> getHelpdeskNotifications() async {
    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .or('title.ilike.%user%,title.ilike.%pesan%,title.ilike.%chat%')
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getHelpdeskNotifications error: $e');
      // Fallback to all notifications
      return getAllNotifications();
    }
  }

  // Notify user (when helpdesk does something)
  Future<int?> notifyUser({
    required String userId,
    required String title,
    required String body,
    int? ticketId,
  }) async {
    try {
      final response = await supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': body,
            'ticket_id': ticketId,
            'is_read': false,
          })
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('notifyUser error: $e');
      return null;
    }
  }

  // Notify helpdesk (when user does something)
  Future<int?> notifyHelpdesk({
    required String title,
    required String body,
    int? ticketId,
    String? excludeUserId, // User who triggered the notification
  }) async {
    try {
      // Get all helpdesk and admin users
      final helpdeskResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'helpdesk');

      final adminResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin');

      final staffList = [...helpdeskResponse, ...adminResponse];

      if (staffList.isEmpty) return null;

      // Create notification for each staff member
      for (final staff in staffList) {
        // Skip if it's the same user (for excludeUserId)
        if (excludeUserId != null && staff['id'] == excludeUserId) {
          continue;
        }

        await supabase.from('notifications').insert({
          'user_id': staff['id'],
          'title': title,
          'message': body,
          'ticket_id': ticketId,
          'is_read': false,
        });
      }

      return 1; // Success
    } catch (e) {
      debugPrint('notifyHelpdesk error: $e');
      return null;
    }
  }

  Future<int?> addNotification({
    required String title,
    required String body,
    String? ticketId,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? supabase.auth.currentUser?.id;
      if (targetUserId == null) return null;

      final response = await supabase
          .from('notifications')
          .insert({
            'user_id': targetUserId,
            'title': title,
            'message': body,
            'ticket_id': ticketId != null ? int.tryParse(ticketId) : null,
            'is_read': false,
          })
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('addNotification error: $e');
      return null;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> markAllAsReadForAll() async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      debugPrint('markAllAsReadForAll error: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTotalUnreadCount() async {
    try {
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('deleteNotification error: $e');
    }
  }

  // Get ticket owner user_id
  Future<String?> getTicketOwnerId(int ticketId) async {
    try {
      final response = await supabase
          .from('tickets')
          .select('user_id')
          .eq('id', ticketId)
          .maybeSingle();

      return response?['user_id'] as String?;
    } catch (e) {
      debugPrint('getTicketOwnerId error: $e');
      return null;
    }
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../models/notification_model.dart';

// User notifications provider
final userNotificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final notifier = ref.read(notificationsProvider.notifier);
  return await notifier.fetchUserNotifications(user.id);
});

// Unread notifications count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);

  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// Notifications state provider
final notificationsProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<AppNotification>>
    >((ref) => NotificationsNotifier(ref));

final notificationsSubscriptionProvider = StreamProvider<AppNotification?>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final client = ref.watch(supabaseClientProvider);

  return client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at')
      .limit(1)
      .map((data) {
        if (data.isEmpty) return null;
        return AppNotification.fromJson(data.first);
      });
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final Ref _ref;
  late final SupabaseClient _client;
  RealtimeChannel? _subscription;

  NotificationsNotifier(this._ref) : super(const AsyncValue.data([])) {
    _client = _ref.read(supabaseClientProvider);
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    _subscription = _client
        .channel('notifications_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final notification = AppNotification.fromJson(payload.newRecord);
            _addNotification(notification);
          },
        )
        .subscribe();
  }

  void _addNotification(AppNotification notification) {
    final currentNotifications = state.value ?? [];
    state = AsyncValue.data([notification, ...currentNotifications]);
  }

  Future<List<AppNotification>> fetchUserNotifications(String userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      state = AsyncValue.data(notifications);
      return notifications;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      // Update local state
      final currentNotifications = state.value ?? [];
      final updatedNotifications = currentNotifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      state = AsyncValue.data(updatedNotifications);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      // Update local state
      final currentNotifications = state.value ?? [];
      final updatedNotifications = currentNotifications.map((n) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList();

      state = AsyncValue.data(updatedNotifications);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);

      // Update local state
      final currentNotifications = state.value ?? [];
      final updatedNotifications = currentNotifications
          .where((n) => n.id != notificationId)
          .toList();

      state = AsyncValue.data(updatedNotifications);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? reportId,
    String? childId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        reportId: reportId,
        childId: childId,
        data: data,
        createdAt: DateTime.now(),
      );

      await _client.from('notifications').insert(notification.toJson());
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  Future<void> sendReportNotification({
    required String userId,
    required String reportId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    await createNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
      reportId: reportId,
    );
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

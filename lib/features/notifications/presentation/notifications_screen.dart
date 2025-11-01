import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notifi_provider.dart';
import '../../../services/supabase_cleint.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref
          .read(notificationsProvider.notifier)
          .fetchUserNotifications(user.id);
    }
  }

  Future<void> _markAsRead(String id) async {
    await ref.read(notificationsProvider.notifier).markAsRead(id);
  }

  Future<void> _deleteNotification(String id) async {
    final success = await ref
        .read(notificationsProvider.notifier)
        .deleteNotification(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete All'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (isConfirmed == true) {
      // Delete all notifications for this user
      final notificationsAsync = ref.read(notificationsProvider);
      final notifications = notificationsAsync.value ?? [];

      for (var notification in notifications) {
        await ref
            .read(notificationsProvider.notifier)
            .deleteNotification(notification.id ?? '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final success = await ref
        .read(notificationsProvider.notifier)
        .markAllAsRead(user.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Delete All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Refresh'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete_all') {
                _deleteAllNotifications();
              } else if (value == 'refresh') {
                _loadNotifications();
              }
            },
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     ref
      //         .read(notificationsProvider.notifier)
      //         .createNotification(
      //           userId: ref.read(currentUserProvider)!.id,
      //           type: NotificationType.reportUpdated,
      //           title: 'ttttt',
      //           message: 'rrrr',
      //         );
      //   },
      //   child: const Icon(Icons.new_label),
      // ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.1),
                            const Color(0xFF059669).withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.notification,
                        size: isSmallScreen ? 48 : 64,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When you get notifications, they\'ll show up here',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: const Color(0xFF10B981),
            child: ListView.builder(
              itemCount: notifications.length,
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationItem(
                  notification: notification,
                  onTap: () => _markAsRead(notification.id ?? ''),
                  onDismissed: (_) =>
                      _deleteNotification(notification.id ?? ''),
                  isSmallScreen: isSmallScreen,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final DismissDirectionCallback onDismissed;
  final bool isSmallScreen;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
    required this.isSmallScreen,
  });

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.childFound:
        return Icons.location_on_rounded;
      case NotificationType.reportUpdated:
        return Icons.update_rounded;
      case NotificationType.staffAssigned:
        return Icons.message_rounded;
      case NotificationType.generalInfo:
        return Icons.warning_rounded;
      case NotificationType.reportUpdated:
        return Icons.check_circle_rounded;
      default:
        return Iconsax.notification;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.childFound:
        return const Color(0xFF10B981);
      case NotificationType.reportUpdated:
        return const Color(0xFF3B82F6);
      case NotificationType.generalInfo:
        return const Color(0xFF8B5CF6);
      case NotificationType.staffAssigned:
        return const Color(0xFFF59E0B);
      case NotificationType.reportUpdated:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = _formatTimeAgo(notification.createdAt);
    final iconColor = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Dismissible(
      key: Key(notification.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(
          bottom: isSmallScreen ? 8 : 12,
          left: 4,
          right: 4,
        ),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: onDismissed,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: notification.isRead
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.05),
                    const Color(0xFF059669).withOpacity(0.02),
                  ],
                ),
          color: notification.isRead ? null : null,
          border: Border.all(
            color: notification.isRead
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                : const Color(0xFF10B981).withOpacity(0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: notification.isRead
                  ? Colors.black.withOpacity(0.03)
                  : const Color(0xFF10B981).withOpacity(0.08),
              blurRadius: notification.isRead ? 4 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF10B981).withOpacity(0.08),
            highlightColor: const Color(0xFF059669).withOpacity(0.04),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor.withOpacity(0.2),
                          iconColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: notification.isRead
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF1F2937))
                                      : const Color(0xFF047857),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF4B5563),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Unread Indicator
                  if (!notification.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '${minutes}m';
    }
    if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '${hours}h';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days}d';
    }
    return DateFormat('MMM d').format(dateTime);
  }
}

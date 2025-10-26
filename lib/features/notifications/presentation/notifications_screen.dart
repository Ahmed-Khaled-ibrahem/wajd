import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wajd/app/const/colors.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime dateTime;
  final bool isRead;
  final IconData icon;
  final Color iconColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    this.isRead = false,
    required this.icon,
    required this.iconColor,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'New Message',
      message: 'You have a new message from the school',
      dateTime: DateTime.now().subtract(const Duration(minutes: 5)),
      icon: Iconsax.message_text_1,
      iconColor: AppColors.primaryColor,
    ),
    NotificationModel(
      id: '2',
      title: 'Event Reminder',
      message: 'Parent-teacher meeting tomorrow at 2 PM',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      icon: Iconsax.calendar_1,
      iconColor: Colors.orange,
    ),
    NotificationModel(
      id: '3',
      title: 'School Update',
      message: 'New school policy update available',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      icon: Iconsax.info_circle,
      iconColor: Colors.blue,
    ),
    NotificationModel(
      id: '4',
      title: 'Payment Received',
      message: 'Your payment for October has been received',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      icon: Iconsax.receipt,
      iconColor: Colors.green,
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you get notifications, they\'ll show up here',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: _notifications.length,
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _NotificationItem(
                    notification: notification,
                    onTap: () => _markAsRead(notification.id),
                    onDismissed: (_) => _deleteNotification(notification.id),
                  );
                },
              ),
            ),
      floatingActionButton: unreadCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Mark all as read
                setState(() {
                  for (var i = 0; i < _notifications.length; i++) {
                    if (!_notifications[i].isRead) {
                      _notifications[i] = _notifications[i].copyWith(
                        isRead: true,
                      );
                    }
                  }
                });
              },
              icon: const Icon(Iconsax.tick_circle),
              label: const Text('Mark all as read'),
              backgroundColor: AppColors.primaryColor,
            )
          : null,
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final DismissDirectionCallback onDismissed;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = _formatTimeAgo(notification.dateTime);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: onDismissed,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        elevation: 0,
        color: notification.isRead
            ? null
            : AppColors.primaryColor.withOpacity(0.05),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: notification.isRead
                                        ? null
                                        : AppColors.primaryColor,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    }
    if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(dateTime);
    }
    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    }
    return DateFormat('MMM d, y').format(dateTime);
  }
}

extension NotificationExtension on NotificationModel {
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      dateTime: dateTime,
      isRead: isRead ?? this.isRead,
      icon: icon,
      iconColor: iconColor,
    );
  }
}

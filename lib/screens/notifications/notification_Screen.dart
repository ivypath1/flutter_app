import 'package:flutter/material.dart';
import 'package:ivy_path/screens/notifications/detail_screen.dart';
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Notification> _notifications = [
    Notification(
      id: '1',
      title: 'New Forum Reply',
      message: 'John Doe replied to your post "Calculus Help Needed"',
      type: NotificationType.forum,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      payload: {'topicId': '123'},
    ),
    Notification(
      id: '2',
      title: 'Mock Test Graded',
      message: 'Your March 2025 Mock UTME has been graded - Score: 85%',
      type: NotificationType.test,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      payload: {'testId': '456'},
    ),
    Notification(
      id: '3',
      title: 'System Update',
      message: 'New features added to the practice module. Try them now!',
      type: NotificationType.system,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Notification(
      id: '4',
      title: 'Study Reminder',
      message: 'You have a scheduled study session for Physics in 30 minutes',
      type: NotificationType.study,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount.toString()),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: mediaSetup(mediaWidth, sm: 60, md: 72, lg: 80),
        ),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationListItem(
            notification: notification,
            onTap: () => _navigateToDetails(notification),
            onDismiss: () => _dismissNotification(notification.id),
          );
        },
      ),
    );
  }

  void _navigateToDetails(Notification notification) {
    // Mark as read when opened
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailsPage(notification: notification),
      ),
    );
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification dismissed')),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Filter Notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('All Notifications'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.markunread),
              title: const Text('Unread Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text('Forum'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Tests'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}

class NotificationListItem extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaWidth = MediaQuery.of(context).size.width;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDismiss(),
      child: ListTile(
        onTap: onTap,
        leading: _buildNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? const CircleAvatar(
                radius: 4,
                backgroundColor: Colors.blue,
              )
            : null,
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.forum:
        icon = Icons.forum;
        color = Colors.blue;
        break;
      case NotificationType.test:
        icon = Icons.assignment;
        color = Colors.green;
        break;
      case NotificationType.study:
        icon = Icons.school;
        color = Colors.orange;
        break;
      case NotificationType.system:
        icon = Icons.notifications;
        color = Colors.purple;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }
}

enum NotificationType { forum, test, study, system }

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.payload,
  });
}
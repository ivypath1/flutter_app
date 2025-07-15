import 'package:flutter/material.dart';
import 'package:ivy_path/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getNotificationColor(notification.type).withOpacity(0.2),
                  radius: 24,
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(notification.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  notification.message,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Data
            if (notification.data != null) ...[
              Text(
                'Additional Information',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notification.data!.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = notification.data!.entries.elementAt(index);
                    return ListTile(
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(entry.value.toString()),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_getActionButton(notification.type) != null)
                  ElevatedButton.icon(
                    onPressed: () => _handleAction(context),
                    icon: Icon(_getActionIcon(notification.type)),
                    label: Text(_getActionLabel(notification.type)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'forum':
        return Icons.forum;
      case 'practice':
        return Icons.assignment;
      case 'material':
        return Icons.book;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'forum':
        return Colors.blue;
      case 'practice':
        return Colors.green;
      case 'material':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget? _getActionButton(String type) {
    if (notification.data == null) return null;
    
    switch (type) {
      case 'forum':
      case 'practice':
      case 'material':
        return ElevatedButton(
          onPressed: () {},
          child: Text(_getActionLabel(type)),
        );
      default:
        return null;
    }
  }

  String _getActionLabel(String type) {
    switch (type) {
      case 'forum':
        return 'View Discussion';
      case 'practice':
        return 'Start Practice';
      case 'material':
        return 'View Material';
      default:
        return 'View';
    }
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'forum':
        return Icons.forum;
      case 'practice':
        return Icons.play_arrow;
      case 'material':
        return Icons.book;
      default:
        return Icons.arrow_forward;
    }
  }

  void _handleAction(BuildContext context) {
    if (notification.data == null) return;

    switch (notification.type) {
      case 'forum':
        if (notification.data!['topicId'] != null) {
          Navigator.pushNamed(
            context,
            '/forum/topic/${notification.data!['topicId']}',
          );
        }
        break;
      case 'practice':
        Navigator.pushNamed(context, '/practice');
        break;
      case 'material':
        if (notification.data!['materialId'] != null) {
          Navigator.pushNamed(
            context,
            '/materials/${notification.data!['materialId']}',
          );
        }
        break;
    }
  }
}
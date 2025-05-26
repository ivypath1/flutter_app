import 'package:flutter/material.dart';
import 'package:ivy_path/screens/forum/forum_topic_page.dart';
import 'package:ivy_path/screens/notifications/notification_Screen.dart';
import 'package:ivy_path/screens/notifications/notification_Screen.dart' as note;
import 'package:ivy_path/utitlity/responsiveness.dart';
import 'package:timeago/timeago.dart' as timeago;


class NotificationDetailsPage extends StatelessWidget {
  final note.Notification notification;

  const NotificationDetailsPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildNotificationIcon(notification.type, context, mediaWidth),
                SizedBox(width: mediaSetup(mediaWidth, sm: 12, md: 16, lg: 20)),
                Text(
                  notification.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 16, md: 24, lg: 32)),
            Text(
              timeago.format(notification.createdAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant,
              child: Padding(
                padding: EdgeInsets.all(mediaSetup(mediaWidth, sm: 16, md: 20, lg: 24)),
                child: Text(
                  notification.message,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            SizedBox(height: mediaSetup(mediaWidth, sm: 24, md: 32, lg: 40)),
            if (notification.payload != null) ...[
              Text(
                'Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mediaSetup(mediaWidth, sm: 8, md: 12, lg: 16)),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, BuildContext context, mediaWidth) {
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
      radius: mediaSetup(mediaWidth, sm: 20, md: 24, lg: 28),
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: mediaSetup(mediaWidth, sm: 20, md: 24, lg: 28), color: color),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (notification.type) {
      case NotificationType.forum:
        return ElevatedButton(
          onPressed: () {
            // Navigate to forum topic
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ForumTopicPage(
                  topicId: notification.payload!['topicId'],
                ),
              ),
            );
          },
          child: const Text('View Discussion'),
        );
      case NotificationType.test:
        return ElevatedButton(
          onPressed: () {
            // Navigate to test results
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => TestResultsPage(
            //       testId: notification.payload!['testId'],
            //     ),
            //   ),
            // );
          },
          child: const Text('View Test Results'),
        );
      case NotificationType.study:
        return ElevatedButton(
          onPressed: () {
            // Navigate to study session
          },
          child: const Text('Start Study Session'),
        );
      case NotificationType.system:
        return ElevatedButton(
          onPressed: () {
            // Check new features
          },
          child: const Text('Explore Features'),
        );
    }
  }
}
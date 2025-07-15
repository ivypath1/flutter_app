import 'package:flutter/material.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/notifications/detail_screen.dart';
import 'package:ivy_path/services/notification_service.dart';
import 'package:ivy_path/widgets/layout_widget.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationService _notificationService;
  
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.authData?.user;
    _notificationService = NotificationService(auth: auth, user: user as dynamic);
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= 1100;
    final isTablet = mediaWidth >= 600;

    return Scaffold(
      drawer: !isDesktop ? const AppDrawer(activeIndex: 6) : null,
      body: Row(
        children: [
          if (isDesktop) const AppDrawer(activeIndex: 6),
          if (isTablet && !isDesktop) const IvyNavRail(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                IvyAppBar(
                  title: 'Notifications',
                  showMenuButton: !isDesktop,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.done_all),
                      onPressed: () {
                        // Mark all as read functionality
                      },
                    ),
                  ],
                ),
                StreamBuilder<List<NotificationItem>>(
                  stream: _notificationService.getNotificationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final notifications = snapshot.data!;

                    if (notifications.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text('No notifications'),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notification = notifications[index];
                          return Dismissible(
                            key: Key(notification.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _notificationService.deleteNotification(notification.id);
                            },
                            child: NotificationTile(
                              notification: notification,
                              onTap: () {
                                if (!notification.isRead) {
                                  _notificationService.markAsRead(notification.id);
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationDetailScreen(
                                      notification: notification,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: notifications.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getNotificationColor(notification.type).withOpacity(0.2),
        child: Icon(
          _getNotificationIcon(notification.type),
          color: _getNotificationColor(notification.type),
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            timeago.format(notification.createdAt),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
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
}
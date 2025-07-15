import 'package:firebase_database/firebase_database.dart';
import 'package:ivy_path/models/user_model.dart' as user_model;
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class NotificationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // static final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Notification channel constants
  static const String _channelId = 'ivypath_default_channel';
  static const String _channelName = 'IvyPath Notifications';
  static const String _channelDescription = 'Default notification channel for IvyPath';

  final dynamic auth;
  final user_model.User user;

  NotificationService({
    required this.auth,
    required this.user,
  });

  static Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    // Initialize local notifications
    // const AndroidInitializationSettings initializationSettingsAndroid =
    //     AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // const DarwinInitializationSettings initializationSettingsIOS =
    //     DarwinInitializationSettings(
    //       requestAlertPermission: true,
    //       requestBadgePermission: true,
    //       requestSoundPermission: true,
    //     );

    // const InitializationSettings initializationSettings =
    //     InitializationSettings(
    //   android: initializationSettingsAndroid,
    //   iOS: initializationSettingsIOS,
    // );

    // await _localNotifications.initialize(
    //   initializationSettings,
    //   onDidReceiveNotificationResponse: _onNotificationTap,
    // );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    // const AndroidNotificationChannel channel = AndroidNotificationChannel(
    //   _channelId,
    //   _channelName,
    //   description: _channelDescription,
    //   importance: Importance.high,
    //   playSound: true,
    //   enableVibration: true,
    //   showBadge: true,
    // );

    // await _localNotifications
    //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //     ?.createNotificationChannel(channel);
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // const AndroidNotificationDetails androidDetails =
      //     AndroidNotificationDetails(
      //   _channelId,
      //   _channelName,
      //   channelDescription: _channelDescription,
      //   importance: Importance.high,
      //   priority: Priority.high,
      //   showWhen: true,
      //   enableVibration: true,
      //   playSound: true,
      //   icon: '@mipmap/ic_launcher',
      //   color: Color(0xFF6200EE), // Your app's primary color
      // );

      // const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      //   presentAlert: true,
      //   presentBadge: true,
      //   presentSound: true,
      //   interruptionLevel: InterruptionLevel.active,
      // );

      // const NotificationDetails platformDetails = NotificationDetails(
      //   android: androidDetails,
      //   iOS: iOSDetails,
      // );

      // Use a unique ID for each notification
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // await _localNotifications.show(
      //   notificationId,
      //   message.notification?.title ?? 'IvyPath',
      //   message.notification?.body ?? 'You have a new notification',
      //   platformDetails,
      //   payload: _encodePayload(message.data),
      // );

      print('Local notification shown successfully');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  static String _encodePayload(Map<String, dynamic> data) {
    // Convert data to a simple string format
    // You can use JSON encoding if needed
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  static Map<String, String> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    
    try {
      final Map<String, String> result = {};
      final pairs = payload.split('|');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          result[keyValue[0]] = keyValue[1];
        }
      }
      return result;
    } catch (e) {
      print('Error decoding payload: $e');
      return {};
    }
  }

  // static void _onNotificationTap(NotificationResponse response) {
  //   print('Notification tapped with payload: ${response.payload}');
    
  //   final data = _decodePayload(response.payload);
    
  //   // Handle notification tap based on payload data
  //   // You can use a global navigator key or event bus to navigate
  //   // For now, just print the data
  //   print('Decoded notification data: $data');
  // }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Database notification methods
  Stream<List<NotificationItem>> getNotificationsStream() {
    final userId = user.id;
    return _database
        .child('notifications')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      return data.entries.map((entry) {
        return NotificationItem.fromMap({
          'id': entry.key,
          ...entry.value as Map<dynamic, dynamic>,
        });
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _database
          .child('notifications')
          .child(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _database
          .child('notifications')
          .child(notificationId)
          .remove();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Save FCM token to database
  Future<void> saveTokenToDatabase(String token) async {
    try {
      final userId = user.id;
      await _database
          .child('user_tokens')
          .child(userId.toString())
          .set({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
            'platform': Platform.isAndroid ? 'android' : 'ios',
          });
      print('Token saved to database successfully');
    } catch (e) {
      print('Error saving token to database: $e');
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final int userId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
    this.data,
    required this.userId,
  });

  factory NotificationItem.fromMap(Map<dynamic, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      type: map['type'] as String, 
      isRead: map['isRead'] as bool? ?? false,
      data: map['data'] != null 
          ? Map<String, dynamic>.from(map['data'] as Map)
          : null,
      userId: map['userId'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'data': data,
      'userId': userId,
    };
  }
}
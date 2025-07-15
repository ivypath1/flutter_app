import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ivy_path/firebase_options.dart';
import 'package:ivy_path/models/auth_model.dart';
import 'package:ivy_path/models/material_model.dart';
import 'package:ivy_path/models/result_model.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/models/user_model.dart';
import 'package:ivy_path/providers/practice_subject.dart';
import 'package:ivy_path/screens/forum/cat_instance_screen.dart';
import 'package:ivy_path/screens/forum/forum_cats_screen.dart';
import 'package:ivy_path/screens/forum/forum_topic_page.dart';
import 'package:ivy_path/screens/materials/material_screen.dart';
import 'package:ivy_path/screens/notifications/notification_Screen.dart';
import 'package:ivy_path/screens/performance_screen.dart';
import 'package:ivy_path/screens/practice_config_screen.dart';
import 'package:ivy_path/screens/profile_screen.dart';
import 'package:ivy_path/services/subject_service.dart';
import 'package:ivy_path/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/login_screen.dart';
import 'package:ivy_path/screens/dashboard_screen.dart';
import 'package:ivy_path/theme/app_theme.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase with options for background handler
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
  
  // You can perform additional background tasks here
  // Note: Keep this lightweight as execution time is limited
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize notification service
    await NotificationService.initialize();

    // License registration is no longer required for Syncfusion

    final ivypathDir = Directory('${appDocDir.path}/Ivypath');
    if (!await ivypathDir.exists()) {
      await ivypathDir.create(recursive: true);
    }
    
    await Hive.initFlutter(ivypathDir.path);
    Hive.registerAdapter(AuthResponseAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(SectionAdapter());
    Hive.registerAdapter(QuestionAdapter());
    Hive.registerAdapter(MaterialAdapter());
    Hive.registerAdapter(PracticeRecordAdapter());
    Hive.registerAdapter(ResultAdapter());
    Hive.registerAdapter(AcademicsAdapter());

    await Hive.openBox<PracticeRecord>('results');
    await Hive.openBox<Subject>('subjects');
    await Hive.openBox<AuthResponse>('auth');

    if (Platform.isAndroid) {
      Future.microtask(() async {
        try {
          await ScreenshotBlocker.enable();
        } catch (e) {
          print('Screenshot blocker failed: $e');
        }
      });
    }

    runApp(const MyApp());
  } catch (error, stackTrace) {
    print('Initialization error: $error');
    print('Stack trace: $stackTrace');

    // Delete the box if it exists
    await Hive.deleteBoxFromDisk('auth');
    // Then open a fresh box
    await Hive.openBox<AuthResponse>('auth');
    
    // Run app with error screen
    runApp(ErrorApp(error: error.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Initialization Error',
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'The app failed to initialize properly. Please restart the app.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Exit App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => PracticeConfigProvider(
            subjectService: SubjectService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'IvyPath',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isInitialized 
              ? auth.isAuthenticated 
                ? const AppWithNotifications() 
                : const LoginScreen()
              : const Center(child: CircularProgressIndicator());
          },
        ),
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '');

          if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'forum') {
            final id = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (context) => ForumCategoryPage(categoryId: id),
            );
          }

          if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'topic') {
            final id = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (context) => ForumTopicPage(topicId: id),
            );
          }

          switch (settings.name) {
            case '/dashboard':
              return MaterialPageRoute(builder: (context) => const DashboardScreen());
            case '/practice':
              return MaterialPageRoute(builder: (context) => const QuestionsPage());
            case '/materials':
              return MaterialPageRoute(builder: (context) => const MaterialsPage());
            case '/forum':
              return MaterialPageRoute(builder: (context) => const ForumPage());
            case '/profile':
              return MaterialPageRoute(builder: (context) => const ProfilePage());
            case '/notifications':
              return MaterialPageRoute(builder: (context) => const NotificationsPage());
            case '/performance':
              return MaterialPageRoute(builder: (context) => const PerformancePage());
          }

          return null;
        },
      ),
    );
  }
}

// New wrapper widget to handle notification setup after authentication
class AppWithNotifications extends StatefulWidget {
  const AppWithNotifications({Key? key}) : super(key: key);

  @override
  State<AppWithNotifications> createState() => _AppWithNotificationsState();
}

class _AppWithNotificationsState extends State<AppWithNotifications> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // Handle notification that launched the app (when app was killed)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get and store FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // TODO: Send token to your server to associate with user
      // await _sendTokenToServer(token);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('FCM Token refreshed: $token');
      // TODO: Send new token to your server
      // await _sendTokenToServer(token);
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    // Handle different notification types
    final data = message.data;
    if (data.containsKey('route')) {
      Navigator.pushNamed(context, data['route']);
    } else if (data.containsKey('type')) {
      switch (data['type']) {
        case 'forum':
          Navigator.pushNamed(context, '/forum');
          break;
        case 'performance':
          Navigator.pushNamed(context, '/performance');
          break;
        default:
          Navigator.pushNamed(context, '/notifications');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}

class ScreenshotBlocker {
  static const _channel = MethodChannel('screenshot_blocker');

  static Future<void> enable() async {
    await _channel.invokeMethod('enableSecure');
  }

  static Future<void> disable() async {
    await _channel.invokeMethod('disableSecure');
  }
}
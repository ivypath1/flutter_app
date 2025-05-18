import 'package:flutter/material.dart';
import 'package:ivy_path/screens/practice_config_screen.dart';
import 'package:ivy_path/screens/session_screen.dart';
import 'package:provider/provider.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/login_screen.dart';
import 'package:ivy_path/screens/dashboard_screen.dart';
import 'package:ivy_path/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'IvyPath',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const LoginScreen(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/practice': (context) => const QuestionsPage(),
          // '/session': (context) => const SessionPage(),
        },
      ),
    );
  }
}
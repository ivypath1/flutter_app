import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ivy_path/screens/practice_config_screen.dart';
import 'package:ivy_path/screens/session_screen.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/login_screen.dart';
import 'package:ivy_path/screens/dashboard_screen.dart';
import 'package:ivy_path/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'IvyPath',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: authState.when(
        data: (auth) => auth == null ? const LoginScreen() : const DashboardScreen(),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, __) => const LoginScreen(),
      ),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/practice': (context) => const QuestionsPage(),
      },
    );
  }
}
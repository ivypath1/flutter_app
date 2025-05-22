import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ivy_path/models/subject_model.dart';
import 'package:ivy_path/providers/practice_subject.dart';
import 'package:ivy_path/screens/forum/cat_instance_screen.dart';
import 'package:ivy_path/screens/forum/forum_cats_screen.dart';
import 'package:ivy_path/screens/materials/material_screen.dart';
import 'package:ivy_path/screens/practice_config_screen.dart';
import 'package:ivy_path/services/subject_service.dart';
import 'package:provider/provider.dart';
import 'package:ivy_path/providers/auth_provider.dart';
import 'package:ivy_path/screens/login_screen.dart';
import 'package:ivy_path/screens/dashboard_screen.dart';
import 'package:ivy_path/theme/app_theme.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(SectionAdapter());

  runApp(const MyApp());
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
            return  auth.isInitialized ? auth.isAuthenticated ? const DashboardScreen() : const LoginScreen() : 
            const CircularProgressIndicator();
          },
        ),
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '');

          if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'forum') {
            final id = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (context) => CategoryPage(categoryId: id),
            );
          }

          // Static routes fallback
          switch (settings.name) {
            case '/dashboard':
              return MaterialPageRoute(builder: (context) => const DashboardScreen());
            case '/practice':
              return MaterialPageRoute(builder: (context) => const QuestionsPage());
            case '/materials':
              return MaterialPageRoute(builder: (context) => const MaterialsPage());
            case '/forum':
              return MaterialPageRoute(builder: (context) => const ForumPage());
          }

          return null;
        },
      ),
    );
  }
}
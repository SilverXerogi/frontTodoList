// Исправленный файл: main.dart
import 'package:flutter/material.dart';
import 'package:front_todo/screens/UserProfileScreen.dart';
import 'package:front_todo/screens/task_detail_screen.dart';
import 'package:front_todo/screens/upload_image_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/task_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? token;

  @override
  void initState() {
    super.initState();
    checkToken();
  }

  Future<void> checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    setState(() {
      token = savedToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      locale: const Locale('ru'),
      supportedLocales: const [
        Locale('en'), // английский
        Locale('ru'), // русский
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: token == null ? '/login' : '/tasks',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/tasks': (context) => const TaskListScreen(),
        '/task_detail': (context) => const TaskDetailScreen(),
        '/upload_image': (context) => const UploadImageScreen(),
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return UserProfileScreen(username: args);
          } else {
            return const Scaffold(
              body: Center(child: Text('Ошибка: имя пользователя не передано')),
            );
          }
        },
      },
    );
  }
}

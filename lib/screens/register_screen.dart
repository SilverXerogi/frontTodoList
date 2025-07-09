import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String username = '';
  String displayName = '';
  String password = '';
  String role = 'User';

  bool loading = false;
  String message = '';

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      message = '';
    });

    final user = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "userName": username,
      "displayName": displayName,
      "profilePicture": "",
      "password": password,
      "role": role,
    };

    final result = await ApiService.register(user);
    setState(() {
      message = result["message"];
    });
    if (result["success"]) {
      Navigator.pushReplacementNamed(context, '/login');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Логин'),
              onChanged: (val) => username = val,
              validator: (val) =>
              val == null || val.isEmpty ? 'Введите логин' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Отображаемое имя'),
              onChanged: (val) => displayName = val,
              validator: (val) =>
              val == null || val.isEmpty ? 'Введите имя' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
              onChanged: (val) => password = val,
              validator: (val) => val == null || val.length < 6
                  ? 'Пароль минимум 6 символов'
                  : null,
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: register,
              child: const Text('Зарегистрироваться'),
            ),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Уже есть аккаунт? Войти'),
            ),
          ]),
        ),
      ),
    );
  }
}

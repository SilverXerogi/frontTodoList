import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<Map<String, dynamic>> _userFuture;
  final _usernameController = TextEditingController();
  final _roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userFuture = ApiService.fetchUserByUsername(widget.username);
    _userFuture.then((user) {
      _usernameController.text = user['username'];
      _roleController.text = user['role'];
    });
  }

  Future<void> _saveChanges() async {
    final updated = await ApiService.updateUserByUsername(
      widget.username,
      {
        "username": _usernameController.text,
        "role": _roleController.text,
      },
    );

    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Данные обновлены")),
      );
      // Обновим username в SharedPreferences, если он изменился
      if (_usernameController.text != widget.username) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context, _usernameController.text);
      } else {
        Navigator.pop(context); // просто выйти
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка при обновлении")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Имя пользователя')),
                TextField(controller: _roleController, decoration: const InputDecoration(labelText: 'Роль')),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _saveChanges, child: const Text('Сохранить')),
              ],
            ),
          );
        },
      ),
    );
  }
}

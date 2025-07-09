import 'package:flutter/material.dart';
import '../models/task.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController statusCtrl;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.task.title);
    descCtrl = TextEditingController(text: widget.task.description);
    statusCtrl = TextEditingController(text: widget.task.status);
  }

  void saveChanges() async {
    final res = await http.put(
      Uri.parse('http://<ip>:5000/update/${widget.task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'status': statusCtrl.text,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка при обновлении")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Редактировать задачу")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Заголовок")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Описание")),
            TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: "Статус")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: saveChanges, child: const Text("Сохранить")),
          ],
        ),
      ),
    );
  }
}

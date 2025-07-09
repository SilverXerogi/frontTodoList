import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Future<Task> _taskFuture;
  late int taskId;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assigneesController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _completedController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    taskId = ModalRoute.of(context)!.settings.arguments as int;
    _taskFuture = ApiService.fetchTask(taskId);
  }

  void _pickDeadlineDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_deadlineController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ru'),
    );
    if (pickedDate != null) {
      setState(() {
        _deadlineController.text =
        '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveChanges(Task originalTask) async {
    final updatedTask = Task(
      id: originalTask.id,
      title: _titleController.text,
      description: _descController.text,
      status: originalTask.status, // статус не меняем вручную
      dateCreated: originalTask.dateCreated,
      dateDeadline: _deadlineController.text,
      dateCompleted: originalTask.status == 'Выполнено'
          ? DateTime.now().toString().split(' ')[0]
          : '',
      assignees: _assigneesController.text,
    );

    final success = await ApiService.updateTask(updatedTask);

    if (success && mounted) {
      Navigator.pop(context, true); // <-- ВОТ ЭТО
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задача обновлена')),
      );
  } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении')),
      );
    }
  }

  // 👇 Функция очистки строки исполнителей
  String cleanAssignees(String raw) {
    final regex = RegExp(r"[(')\[\]]");
    return raw.replaceAll(regex, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Детали задачи')),
      body: FutureBuilder<Task>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Задача не найдена'));
          } else {
            final task = snapshot.data!;

            _titleController.text = task.title;
            _descController.text = task.description;
            _assigneesController.text = cleanAssignees(task.assignees);
            _deadlineController.text = task.dateDeadline;
            _completedController.text = task.dateCompleted ?? '';

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Описание'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _assigneesController,
                    decoration: const InputDecoration(labelText: 'Исполнители'),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDeadlineDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _deadlineController,
                        decoration: const InputDecoration(
                          labelText: 'Срок выполнения (выберите)',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (task.status == 'Выполнено')
                    Text(
                      'Дата завершения будет установлена автоматически: ${DateTime.now().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 10),
                  Text('Создано: ${task.dateCreated}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _saveChanges(task),
                    child: const Text('Сохранить изменения'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

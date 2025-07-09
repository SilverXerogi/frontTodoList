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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    taskId = ModalRoute.of(context)!.settings.arguments as int;
    _taskFuture = ApiService.fetchTask(taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали задачи'),
      ),
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
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text('Название: ${task.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Описание: ${task.description}'),
                  const SizedBox(height: 10),
                  Text('Исполнители: ${task.assignees}'),
                  const SizedBox(height: 10),
                  Text('Статус: ${task.status}'),
                  const SizedBox(height: 10),
                  Text('Дата создания: ${task.dateCreated}'),
                  const SizedBox(height: 10),
                  Text('Срок выполнения: ${task.dateDeadline}'),
                  if (task.dateCompleted != null && task.dateCompleted!.isNotEmpty)
                    Text('Дата завершения: ${task.dateCompleted}'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

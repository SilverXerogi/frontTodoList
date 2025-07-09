import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _tasksFuture;
  Map<String, List<Task>> tasksByStatus = {
    "Пулл": [],
    "В работе": [],
    "Тестирование": [],
    "Выполнено": [],
  };

  @override
  void initState() {
    super.initState();
    _tasksFuture = ApiService.fetchTasks();
    _tasksFuture.then((tasks) {
      setState(() {
        _groupTasksByStatus(tasks);
      });
    });
  }

  void _groupTasksByStatus(List<Task> allTasks) {
    tasksByStatus = {
      "Пулл": [],
      "В работе": [],
      "Тестирование": [],
      "Выполнено": [],
    };

    for (var task in allTasks) {
      // Приводим статус к нужному виду с большой буквы, например
      String normalizedStatus = _normalizeStatus(task.status);
      if (tasksByStatus.containsKey(normalizedStatus)) {
        tasksByStatus[normalizedStatus]!.add(task);
      } else {
        // Если статус новый — можно добавить или игнорировать
        tasksByStatus[normalizedStatus] = [task];
      }
    }
  }

  String _normalizeStatus(String status) {
    // Пример: первый символ заглавный, остальные строчные
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список задач'),
      ),
      body: _tasksFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Задачи не найдены'));
          } else {
            return Row(
              children: [
                buildColumn('Пулл'),
                buildColumn('В работе'),
                buildColumn('Тестирование'),
                buildColumn('Выполнено'),
              ],
            );
          }
        },
      ),
    );
  }


  Widget buildColumn(String status) {
    final tasks = tasksByStatus[status] ?? [];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: DragTarget<Task>(
                onWillAccept: (task) => task?.status != status,
                onAccept: (task) async {
                  String oldStatus = task.status;

                  setState(() {
                    tasksByStatus[oldStatus]?.remove(task);
                    task.status = status;
                    tasksByStatus[status]?.add(task);
                  });
                  print(task);
                  final success = await ApiService.updateTask(task);
                  if (!success) {
                    setState(() {
                      tasksByStatus[oldStatus]?.removeWhere((t) => t.id.toString() == task.id.toString());
                      task.status = oldStatus;
                      tasksByStatus[oldStatus]?.add(task);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ошибка при обновлении задачи на сервере')),
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text('Пусто'));
                  }
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Draggable<Task>(
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.8,
                            child: SizedBox(
                              width: 300,
                              child: buildTaskCard(task),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: buildTaskCard(task),
                        ),
                        child: buildTaskCard(task),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.pushNamed(context, '/task_detail', arguments: task.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                task.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text('Срок: ${task.dateDeadline}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Исполнители: ${task.assignees}', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

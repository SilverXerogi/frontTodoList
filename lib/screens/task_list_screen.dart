import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'AddTaskDialog.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String currentUsername = '';
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
    _loadUsername();
    _refreshTasks();
    _tasksFuture.then((tasks) {
      setState(() {
        _groupTasksByStatus(tasks);
      });
    });
  }
  Color getCardColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'Пулл':
        return const Color(0xFFE3F2FD); // светло-синий
      case 'В работе':
        return const Color(0xFFFFF9C4); // светло-жёлтый
      case 'Тестирование':
        return const Color(0xFFF8BBD0); // светло-розовый
      case 'Выполнено':
        return const Color(0xFFC8E6C9); // светло-зелёный
      default:
        return Colors.white;
    }
  }

  Future<void> _refreshTasks() async {
    final tasks = await ApiService.fetchTasks();
    setState(() {
      _groupTasksByStatus(tasks);
      _tasksFuture = Future.value(tasks); // обновим future
    });
  }
  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString('username') ?? 'Пользователь';
    });
  }

  Future<void> _openUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null && username.isNotEmpty) {
      final result = await Navigator.pushNamed(context, '/profile', arguments: username);
      // если пользователь обновил имя и вернулся назад
      if (result is String && result != currentUsername) {
        prefs.setString('username', result); // обновим локально
        setState(() {
          currentUsername = result;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не найден')),
      );
    }
  }

  void _groupTasksByStatus(List<Task> allTasks) {
    tasksByStatus = {
      "Пулл": [],
      "В работе": [],
      "Тестирование": [],
      "Выполнено": [],
    };

    for (var task in allTasks) {
      String normalizedStatus = _normalizeStatus(task.status);
      if (tasksByStatus.containsKey(normalizedStatus)) {
        tasksByStatus[normalizedStatus]!.add(task);
      } else {
        tasksByStatus[normalizedStatus] = [task];
      }
    }
  }

  String _normalizeStatus(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  void _handleTaskAdded(Task newTask) {
    setState(() {
      tasksByStatus[newTask.status]?.add(newTask);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Список задач', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(onTaskAdded: _handleTaskAdded),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const Spacer(),
            Text(
              currentUsername,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.black),
              onPressed: _openUserProfile,
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Task>>(
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
                  final success = await ApiService.updateTask(task);
                  if (!success) {
                    setState(() {
                      tasksByStatus[status]?.remove(task);
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
      color: getCardColor(task.status),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final updated = await Navigator.pushNamed(context, '/task_detail', arguments: task.id);
          if (updated == true) {
            _refreshTasks(); // перезагружаем список
          }
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

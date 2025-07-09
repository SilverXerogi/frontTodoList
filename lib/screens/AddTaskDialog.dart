import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';

class AddTaskDialog extends StatefulWidget {
  final void Function(Task) onTaskAdded;

  const AddTaskDialog({super.key, required this.onTaskAdded});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _assigneesController = TextEditingController();
  String _selectedStatus = 'Пулл';
  void _pickDeadlineDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить задачу'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Описание')),
            GestureDetector(
              onTap: _pickDeadlineDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: _deadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Срок (выберите дату)',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),

            TextField(controller: _assigneesController, decoration: const InputDecoration(labelText: 'Исполнители (через запятую)')),
            DropdownButton<String>(
              value: _selectedStatus,
              items: ['Пулл', 'В работе', 'Тестирование', 'Выполнено'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Отмена'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Добавить'),
          onPressed: () async {
            final allTasks = await ApiService.fetchTasks();
            final nextId = allTasks.map((t) => t.id).fold(0, max) + 1;

            final newTask = Task(
              id: nextId,
              title: _titleController.text,
              description: _descController.text,
              dateCreated: DateTime.now().toString().split(' ')[0],
              dateDeadline: _deadlineController.text,
              dateCompleted: '',
              status: _selectedStatus,
              assignees: _assigneesController.text,
            );
            final created = await ApiService.createTask(newTask);
            if (created != null) {
              widget.onTaskAdded(created);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка при добавлении задачи')),
              );
            }
          },
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../baseurl.dart';
import '../models/task.dart';

class ApiService {

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userName": username, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user),
      );

      final data = jsonDecode(response.body);

      return {
        "success": response.statusCode == 200,
        "message": data["message"] ?? "Неизвестная ошибка"
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Ошибка сети: $e"
      };
    }
  }

  static Future<Task?> createTask(Task task) async {
    final url = Uri.parse('$baseUrl/insert');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id": task.id,
        "title": task.title,
        "description": task.description,
        "status": task.status,
        "dateCreated": task.dateCreated,
        "dateDeadline": task.dateDeadline,
        "dateCompleted": task.dateCompleted,
        "assignees": task.assignees.split(',').map((s) => s.trim()).toList(),
      }),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      print("Ошибка при создании: ${response.body}");
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchUserByUsername(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/user_by_username/$username'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Не удалось загрузить пользователя');
    }
  }

  static Future<bool> updateUserByUsername(String username, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user_by_username/$username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return response.statusCode == 200;
  }


  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/select_all'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }
  // В ApiService
  static Future<bool> updateTask(Task task) async {
    final url = Uri.parse('$baseUrl/update/${task.id}');
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": task.id,
        "title": task.title,
        "description": task.description,
        "status": task.status,
        "dateCreated": task.dateCreated,
        "dateDeadline": task.dateDeadline,
        "dateCompleted": task.dateCompleted ?? "",
        "assignees": task.assignees,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Ошибка обновления задачи: ${response.body}');
      return false;
    }
  }

  static Future<Task> fetchTask(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/get_task/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return Task.fromJson(json);
    } else {
      throw Exception('Failed to load task');
    }
  }
}

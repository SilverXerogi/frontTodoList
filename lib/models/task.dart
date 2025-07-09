class Task {
  final int id;
  final String assignees;
  final String title;
  final String description;
  final String dateCreated;
  final String dateDeadline;
  final String? dateCompleted;
  String status;

  Task({
    required this.id,
    required this.assignees,
    required this.title,
    required this.description,
    required this.dateCreated,
    required this.dateDeadline,
    this.dateCompleted,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    assignees: json['assignees'],
    title: json['title'],
    description: json['description'],
    dateCreated: json['dateCreated'],
    dateDeadline: json['dateDeadline'],
    dateCompleted: json['dateCompleted'],
    status: json['status'],
  );
}

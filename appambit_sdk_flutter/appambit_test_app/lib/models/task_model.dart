class TaskModel {
  final int? id;
  final String? title;
  final int? isCompleted;
  final String? priority;
  final String? dueDate;

  const TaskModel({
    this.id,
    this.title,
    this.isCompleted,
    this.priority,
    this.dueDate,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: _toInt(map['id']),
      title: map['title']?.toString(),
      isCompleted: _toInt(map['is_completed']),
      priority: map['priority']?.toString(),
      dueDate: map['due_date']?.toString(),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

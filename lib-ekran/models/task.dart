// klasa koja drzi model profila to-do taska
class Task {
  String id;
  String title;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.isCompleted = false,
  });

  // convertaj task u mapu
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  // kreiraj task iz firebase dokumenta
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

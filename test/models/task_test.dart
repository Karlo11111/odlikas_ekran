import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/models/task.dart';

void main() {
  group('Task.toMap', () {
    test('serializes all fields', () {
      final date = DateTime(2026, 6, 10);
      final task = Task(id: '1', title: 'Study math', dueDate: date, isCompleted: true);
      final map = task.toMap();
      expect(map['id'], '1');
      expect(map['title'], 'Study math');
      expect(map['dueDate'], date.millisecondsSinceEpoch);
      expect(map['isCompleted'], true);
    });

    test('serializes null dueDate as null', () {
      final task = Task(id: '2', title: 'No date');
      final map = task.toMap();
      expect(map['dueDate'], isNull);
    });
  });

  group('Task.fromMap', () {
    test('deserializes all fields', () {
      final date = DateTime(2026, 6, 10);
      final map = {
        'id': '1',
        'title': 'Study math',
        'dueDate': date.millisecondsSinceEpoch,
        'isCompleted': true,
      };
      final task = Task.fromMap(map);
      expect(task.id, '1');
      expect(task.title, 'Study math');
      expect(task.dueDate?.millisecondsSinceEpoch, date.millisecondsSinceEpoch);
      expect(task.isCompleted, true);
    });

    test('defaults isCompleted to false when missing', () {
      final task = Task.fromMap({'id': '1', 'title': 'X', 'dueDate': null});
      expect(task.isCompleted, false);
    });

    test('deserializes null dueDate as null', () {
      final task = Task.fromMap({'id': '1', 'title': 'X', 'dueDate': null});
      expect(task.dueDate, isNull);
    });

    test('roundtrip toMap then fromMap preserves data', () {
      final original = Task(
        id: 'abc',
        title: 'Test',
        dueDate: DateTime(2026, 1, 15),
        isCompleted: false,
      );
      final restored = Task.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(
        restored.dueDate?.millisecondsSinceEpoch,
        original.dueDate?.millisecondsSinceEpoch,
      );
      expect(restored.isCompleted, original.isCompleted);
    });
  });
}

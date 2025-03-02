import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odlikas_ekran/models/task.dart';

class TaskService {
  final String userEmail;

  TaskService(this.userEmail);

  // Reference to the user's document
  DocumentReference<Map<String, dynamic>> get _userDocRef =>
      FirebaseFirestore.instance.collection('tasks').doc(userEmail);

  // Reference to the user's tasks collection
  CollectionReference<Map<String, dynamic>> get _userTasksRef =>
      _userDocRef.collection('tasks');

  Future<void> addTask(Task task) {
    return _userTasksRef.doc(task.id).set(task.toMap());
  }

  Future<void> updateTask(Task task) {
    return _userTasksRef.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) {
    return _userTasksRef.doc(taskId).delete();
  }

  Stream<List<Task>> getTasks() {
    return _userTasksRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data());
      }).toList();
    });
  }
}

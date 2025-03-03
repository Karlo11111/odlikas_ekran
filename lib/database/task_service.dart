import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odlikas_ekran/models/task.dart';

class TaskService {
  final String userEmail;

  TaskService(this.userEmail);

  // referenca na user dokument u firebaseu
  DocumentReference<Map<String, dynamic>> get _userDocRef =>
      FirebaseFirestore.instance.collection('tasks').doc(userEmail);

  // referenca na user task dokument
  CollectionReference<Map<String, dynamic>> get _userTasksRef =>
      _userDocRef.collection('tasks');

  // funkcija koja dodaje task u firebase
  Future<void> addTask(Task task) {
    return _userTasksRef.doc(task.id).set(task.toMap());
  }

  // funkcija koja updatea task u firebase
  Future<void> updateTask(Task task) {
    return _userTasksRef.doc(task.id).update(task.toMap());
  }

  // funkcija koja brise task u firebase
  Future<void> deleteTask(String taskId) {
    return _userTasksRef.doc(taskId).delete();
  }

  // funkcija koja fetcha taskove iz firebasea
  Stream<List<Task>> getTasks() {
    return _userTasksRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data());
      }).toList();
    });
  }
}

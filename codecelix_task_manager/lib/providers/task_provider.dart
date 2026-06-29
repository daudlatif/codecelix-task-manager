import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  final CollectionReference _taskRef =
      FirebaseFirestore.instance.collection('tasks');

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Task>> getTasks() {
    return _taskRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Task.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addTask(Task task) async {
    await _taskRef.add(task.toMap());
  }

  Future<void> updateTask(Task task) async {
    await _taskRef.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _taskRef.doc(id).delete();
  }

  Future<void> toggleComplete(Task task) async {
    await _taskRef.doc(task.id).update({'isCompleted': !task.isCompleted});
  }
}
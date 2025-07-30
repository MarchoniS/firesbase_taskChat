import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Assign a task to a single user with server timestamps
  Future<void> assignTask({
    required String task,
    required String assignedToUserId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final taskData = {
      'task': task,
      'assignedToUserId': assignedToUserId,
      'assignedByUserId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    await _firestore.collection('assigned_tasks').add(taskData);
  }

  /// Assign the same task to multiple users with batch write
  Future<void> assignTaskToMultipleUsers({
    required String task,
    required List<String> userIds,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final batch = _firestore.batch();
    final collection = _firestore.collection('assigned_tasks');

    for (String userId in userIds) {
      final docRef = collection.doc();
      final taskData = {
        'task': task,
        'assignedToUserId': userId,
        'assignedByUserId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };
      batch.set(docRef, taskData);
    }

    await batch.commit();
  }

  /// Fetch tasks assigned to the current user (with limit for scalability)
  Future<List<AssignedTask>> getTasksAssignedToMe(String uid, {int limit = 50}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final snapshot = await _firestore
        .collection('assigned_tasks')
        .where('assignedToUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) =>
        AssignedTask.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Fetch tasks assigned by the current user (for admins, with limit)
  Future<List<AssignedTask>> getTasksAssignedByMe({int limit = 50}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final snapshot = await _firestore
        .collection('assigned_tasks')
        .where('assignedByUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) =>
        AssignedTask.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Stream tasks assigned to a user (for live lists)
  Stream<List<AssignedTask>> streamTasksForUser(String userId) {
    return _firestore
        .collection('assigned_tasks')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        AssignedTask.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  /// Update the task status, safely handling errors and using server time
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _firestore.collection('assigned_tasks').doc(taskId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update task status: $e');
      rethrow;
    }
  }

  /// Delete a task, safely handling errors
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('assigned_tasks').doc(taskId).delete();
    } catch (e) {
      print('Failed to delete task: $e');
      rethrow;
    }
  }
}

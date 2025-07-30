import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedTask {
  final String id;
  final String task;
  final String assignedToUserId;
  final String assignedByUserId;
  final String? assignedByUsername;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;

  AssignedTask({
    required this.id,
    required this.task,
    required this.assignedToUserId,
    required this.assignedByUserId,
    this.assignedByUsername,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'pending',
  });

  // factory AssignedTask.fromFirestore(String id, Map<String, dynamic> data) {
  //   return AssignedTask(
  //     id: id,
  //     task: data['task'] ?? '',
  //     assignedToUserId: data['assignedToUserId'] ?? '',
  //     assignedByUserId: data['assignedByUserId'] ?? '',
  //     createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  //     updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  //     status: data['status'] ?? 'pending',
  //   );
  // }

  factory AssignedTask.fromFirestore(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'];
    final rawUpdatedAt = data['updatedAt'];

    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now(); // fallback
    }

    return AssignedTask(
      id: id,
      task: data['task'] ?? '',
      assignedToUserId: data['assignedToUserId'] ?? '',
      assignedByUserId: data['assignedByUserId'] ?? '',
        assignedByUsername: data['assignedByUsername'],
      createdAt: parseTimestamp(rawCreatedAt),
      updatedAt: parseTimestamp(rawUpdatedAt),
      status: data['status'] ?? 'pending',
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      'task': task,
      'assignedToUserId': assignedToUserId,
      'assignedByUserId': assignedByUserId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String phone;
  final String username;

  UserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.username,
  });

  Map<String, dynamic> toMap() =>
      {
        'uid': uid,
        'email': email,
        'phone': phone,
        'username': username,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) =>
      UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        username: map['username'] ?? '',
      );

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'],
      phone: data['phone'],
      username: data['username'] ?? 'Unnamed',
    );
  }
}

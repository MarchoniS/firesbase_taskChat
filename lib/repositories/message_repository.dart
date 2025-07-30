import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageRepository {
  final _messagesRef = FirebaseFirestore.instance
      .collection('groups')
      .doc('group_chat')
      .collection('messages');

  /// Listen to all messages (real-time stream)
  Stream<List<MessageModel>> getMessagesStream() {
    return _messagesRef
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  /// Optionally fetch messages once (not real-time)
  Future<List<MessageModel>> fetchMessages() async {
    final snap = await _messagesRef.orderBy('timestamp', descending: false).get();
    return snap.docs
        .map((doc) => MessageModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}

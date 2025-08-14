import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';

import '../repositories/user_repository.dart';
import '../repositories/task_repository.dart';
import '../models/user_model.dart';

class HighlightedMessage extends StatelessWidget {
  final String text;
  final void Function(String)? onMentionTap;

  HighlightedMessage({required this.text, this.onMentionTap});

  @override
  Widget build(BuildContext context) {
    final pattern = RegExp(r'(\btask\b:?)|(@\w+)', caseSensitive: false);

    final spans = <TextSpan>[];
    int start = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final matchText = match.group(0)!;
      if (matchText.toLowerCase().startsWith('task')) {
        final displayed = matchText.toUpperCase();
        spans.add(TextSpan(
          text: displayed,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (matchText.startsWith('@')) {
        spans.add(TextSpan(
          text: matchText,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
          recognizer: onMentionTap != null
              ? (TapGestureRecognizer()
            ..onTap = () => onMentionTap!(matchText.substring(1)))
              : null,
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        children: spans,
      ),
    );
  }
}

class GlobalChatPage extends StatefulWidget {
  final UserRepository userRepository;
  final TaskRepository taskRepository;

  const GlobalChatPage({
    Key? key,
    required this.userRepository,
    required this.taskRepository,
  }) : super(key: key);

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference messagesRef = FirebaseFirestore.instance
      .collection('groups')
      .doc('global_chat')
      .collection('messages');

  String? senderName;
  bool loading = true;
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  bool showUserSuggestions = false;
  int suggestionsStart = 0;

  final DateFormat timeFormat = DateFormat.jm();
  final DateFormat dateFormat = DateFormat.yMMMMd();

  @override
  void initState() {
    super.initState();
    _initSenderName();
    _loadUsers();
  }

  Future<void> _initSenderName() async {
    if (user != null) {
      final userModel = await widget.userRepository.getUserById(user!.uid);
      setState(() {
        senderName = userModel?.username ?? user!.email;
        loading = false;
      });
    } else {
      setState(() {
        senderName = 'User';
        loading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    final users = await widget.userRepository.getAllUsers();
    setState(() {
      allUsers = users;
    });
  }

  Color _generateColorFromUsername(String username) {
    final hash = username.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  void _handleInputChanged(String text) {
    final cursorPos = _controller.selection.baseOffset;
    final value = cursorPos > 0 && cursorPos <= text.length
        ? text.substring(0, cursorPos)
        : text;
    int atIndex = value.lastIndexOf('@');

    if (atIndex != -1) {
      final partial = value.substring(atIndex + 1);
      filteredUsers = partial.isEmpty
          ? allUsers
          : allUsers
          .where((u) =>
          u.username.toLowerCase().startsWith(partial.toLowerCase()))
          .toList();
      setState(() {
        showUserSuggestions = filteredUsers.isNotEmpty;
        suggestionsStart = atIndex;
      });
    } else {
      setState(() {
        showUserSuggestions = false;
      });
    }
  }

  void _onUserSelected(String username) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    final value = cursorPos > 0 && cursorPos <= text.length
        ? text.substring(0, cursorPos)
        : text;
    final atIndex = value.lastIndexOf('@');
    if (atIndex == -1) return;

    int mentionEnd = cursorPos;
    while (mentionEnd < text.length &&
        RegExp(r'\w').hasMatch(text[mentionEnd])) {
      mentionEnd++;
    }

    final newText = text.replaceRange(atIndex, mentionEnd, '@$username ');
    _controller.text = newText;
    _controller.selection =
        TextSelection.collapsed(offset: atIndex + username.length + 2);

    setState(() {
      showUserSuggestions = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final currentUser = user;

    if (text.isEmpty || currentUser == null || senderName == null) return;

    if (text.toLowerCase().startsWith('task:')) {
      final regex = RegExp(r'@(\w+)', caseSensitive: false);
      final mentions = regex
          .allMatches(text)
          .map((m) => m.group(1)?.toLowerCase())
          .whereType<String>()
          .toList();

      final taskText = text
          .replaceFirst(RegExp(r'^task:\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'@\w+', caseSensitive: false), '')
          .trim();

      if (taskText.isEmpty || mentions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('Please enter a task and mention at least one user')),
        );
        return;
      }

      final mentionedUsers = allUsers
          .where((u) => mentions.contains(u.username.toLowerCase()))
          .toList();

      if (mentionedUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentioned user(s) not found')),
        );
        return;
      }

      try {
        final userIds = mentionedUsers.map((u) => u.uid).toList();
        await widget.taskRepository.assignTaskToMultipleUsers(
          task: taskText,
          userIds: userIds,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Task assigned to: ${mentionedUsers.map((u) => u.username).join(", ")}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign task: $e')),
        );
      }
    }

    await messagesRef.add({
      'senderId': currentUser.uid,
      'senderName': senderName!,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    setState(() {
      showUserSuggestions = false;
    });

    _scrollToBottom(animated: true);
  }

  void _scrollToBottom({bool animated = false}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  bool _isSameDate(Timestamp? t1, Timestamp? t2) {
    if (t1 == null || t2 == null) return false;
    final d1 = t1.toDate();
    final d2 = t2.toDate();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Chat", style: TextStyle(fontSize: 20)),
            SizedBox(height: 4),
            Text(
              "Type Task: To assign Task to user with @mention)",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: messagesRef
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    final currentUserId = user?.uid;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: docs.length,
                      reverse: false, // latest at bottom
                      itemBuilder: (context, index) {
                        final data =
                        docs[index].data()! as Map<String, dynamic>;
                        final isMe = data['senderId'] == currentUserId;

                        Widget? dateSeparator;
                        if (index == 0 ||
                            !_isSameDate(docs[index].get('timestamp'),
                                docs[index - 1].get('timestamp'))) {
                          Timestamp? ts = docs[index].get('timestamp');
                          String dateString =
                          ts != null ? dateFormat.format(ts.toDate()) : '';
                          dateSeparator = Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  dateString,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          );
                        }

                        String timeString = '';
                        if (data['timestamp'] != null) {
                          final ts = data['timestamp'] as Timestamp;
                          timeString = timeFormat.format(ts.toDate());
                        }

                        final sender = data['senderName'] ?? 'Unknown';

                        return Column(
                          children: [
                            if (dateSeparator != null) dateSeparator,
                            Container(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Container(
                                  padding:
                                  const EdgeInsets.fromLTRB(12, 8, 12, 18),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xffDCF8C6)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(12),
                                      topRight: const Radius.circular(12),
                                      bottomLeft:
                                      Radius.circular(isMe ? 12 : 0),
                                      bottomRight:
                                      Radius.circular(isMe ? 0 : 12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        offset: const Offset(0, 1),
                                        blurRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, bottom: 2),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius.circular(12)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 1,
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            child: Text(
                                              sender,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color:
                                                _generateColorFromUsername(
                                                    sender),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 60),
                                            child: HighlightedMessage(
                                              text: data['text'] ?? '',
                                              onMentionTap: (username) {
                                                print(
                                                    'Tapped on mention: $username');
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10),
                                              child: Text(
                                                timeString,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              _buildMessageInput(),
            ],
          ),
          if (showUserSuggestions) _buildUserSuggestions(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: "Type a message",
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 5,
                      onChanged: _handleInputChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSuggestions() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 70,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 220,
          child: ListView(
            shrinkWrap: true,
            children: filteredUsers
                .take(6)
                .map(
                  (user) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  _generateColorFromUsername(user.username)
                      .withOpacity(0.1),
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: TextStyle(
                      color: _generateColorFromUsername(user.username),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('@${user.username}'),
                onTap: () => _onUserSelected(user.username),
              ),
            )
                .toList(),
          ),
        ),
      ),
    );
  }
}

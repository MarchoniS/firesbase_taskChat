import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../controllers/auth_controller.dart';
import '../repositories/user_repository.dart';
import '../repositories/task_repository.dart';
import '../models/task_model.dart';
import 'app_drawer.dart';
import 'chat_page.dart';
import 'update_downloader.dart';

class HomePage extends StatefulWidget {
  final AuthController authController;
  final UserRepository userRepository;
  final TaskRepository taskRepository;

  const HomePage({
    Key? key,
    required this.authController,
    required this.userRepository,
    required this.taskRepository,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? username;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);

    final user = await widget.userRepository.getCurrentUser();
    final uid = widget.authController.currentUser?.uid;

    if (user != null && uid != null) {
      final tasks = await widget.taskRepository.getTasksAssignedToMe(uid);
      setState(() {
        username = user.username;
        loading = false;
      });
    } else {
      setState(() {
        username = 'User';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FC),
      appBar: AppBar(
        title: Text('Welcome, $username'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await widget.authController.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // Removed system_update button
        ],
      ),
      drawer: AppDrawer(
        username: username ?? 'User',
        userRepository: widget.userRepository,
        taskRepository: widget.taskRepository,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Team Chat",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GlobalChatPage(
                      userRepository: widget.userRepository,
                      taskRepository: widget.taskRepository,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

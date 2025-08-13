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
        // pendingTasks = tasks.where((t) => t.status == 'pending').toList();
        // newTasks = tasks.where((t) => t.status == 'new').toList();
        loading = false;
      });
    } else {
      setState(() {
        username = 'User';
        loading = false;
      });
    }
  }

  // void _showNewTasksDialog() {
  //   if (newTasks.isEmpty) {
  //     // No action if no new tasks
  //     return;
  //   }

  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: Text("New Assigned Tasks (${newTasks.length})"),
  //       content: SizedBox(
  //         width: double.maxFinite,
  //         child: ListView.separated(
  //           shrinkWrap: true,
  //           itemCount: newTasks.length,
  //           separatorBuilder: (context, index) => const Divider(),
  //           itemBuilder: (context, index) {
  //             final task = newTasks[index];
  //             return ListTile(
  //               title: Text(task.task ?? 'No description'),
  //               subtitle: Text('Assigned by: ${task.assignedByUsername ?? 'Unknown'}'),
  //               trailing: Text(task.status ?? ''),
  //             );
  //           },
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           child: const Text("Close"),
  //           onPressed: () => Navigator.of(ctx).pop(),
  //         ),
  //         ElevatedButton(
  //           child: const Text("Mark All as Read"),
  //           onPressed: () {
  //             // Example logic: mark all new tasks as pending locally
  //             setState(() {
  //               pendingTasks = [...pendingTasks, ...newTasks];
  //               newTasks.clear();
  //             });
  //             Navigator.of(ctx).pop();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
          IconButton(
            icon: const Icon(Icons.system_update),
            tooltip: 'Check for Update',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Download Update?"),
                  content: const Text("Would you like to download the latest version?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Download"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final response = await http.get(
                      Uri.parse("https://task-management-1455a.web.app/version.json"));
                  if (response.statusCode == 200) {
                    final jsonData = json.decode(response.body);
                    final apkUrl = jsonData['apkUrl'];

                    if (apkUrl != null) {
                      UpdateDownloader.registerPort();
                      await UpdateDownloader.downloadApk(context, apkUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid update URL")),
                      );
                    }
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to fetch update URL")),
                  );
                }
              }
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        username: username ?? 'User',
        userRepository: widget.userRepository,
        taskRepository: widget.taskRepository,
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     if (newTasks.isNotEmpty) {
      //       _showNewTasksDialog();
      //     }
      //     // else do nothing
      //   },
      //   backgroundColor: Colors.indigo,
      //   tooltip: 'Show New Assigned Tasks',
      //   child: Stack(
      //     alignment: Alignment.center,
      //     children: [
      //       const Icon(Icons.task),
      //       if (newTasks.isNotEmpty)
      //         Positioned(
      //           right: 0,
      //           top: 0,
      //           child: Container(
      //             padding: const EdgeInsets.all(6),
      //             decoration: BoxDecoration(
      //               color: Colors.redAccent,
      //               shape: BoxShape.circle,
      //               border: Border.all(color: Colors.white, width: 1.5),
      //             ),
      //             constraints: const BoxConstraints(
      //               minWidth: 20,
      //               minHeight: 20,
      //             ),
      //             child: Text(
      //               newTasks.length.toString(),
      //               style: const TextStyle(
      //                 color: Colors.white,
      //                 fontSize: 12,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //               textAlign: TextAlign.center,
      //             ),
      //           ),
      //         ),
      //     ],
      //   ),
      // ),

      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Team Chat",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

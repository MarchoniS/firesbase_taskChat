// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:task/pages/assign_task_page.dart';
import 'package:task/pages/all_task_page.dart';
import 'package:task/pages/task_page.dart';
import 'package:task/pages/users_page.dart';
import 'package:task/pages/chat_page.dart';
import 'update_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../repositories/user_repository.dart';
import '../repositories/task_repository.dart';

class AppDrawer extends StatelessWidget {
  final String username;
  final UserRepository userRepository;
  final TaskRepository taskRepository;

  const AppDrawer({
    Key? key,
    required this.username,
    required this.userRepository,
    required this.taskRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const SizedBox(height: 10),
                _buildUserHeader(),
                const SizedBox(height: 10),
                _buildActionButton(
                  context,
                  icon: Icons.add_task,
                  label: 'Assign New Task',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D67E4), Color(0xFF4ACBCC)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignTaskPage(
                        taskRepository: taskRepository,
                        userRepository: userRepository,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  icon: Icons.task_alt,
                  label: 'My Assigned Tasks',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF53E2AE), Color(0xFF8AE563)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignedTasksPage(
                        taskRepository: taskRepository,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  icon: Icons.task,
                  label: 'All Assigned Tasks',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF189F6E), Color(0xFF67BC44)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllTasksPage(
                        taskRepository: taskRepository,
                        userRepository: userRepository,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  icon: Icons.chat_bubble_rounded,
                  label: 'Group Chat',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A63E5), Color(0xFF42AEEC)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GlobalChatPage(
                        userRepository: userRepository,
                        taskRepository: taskRepository,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  icon: Icons.people_outline,
                  label: 'View All Users',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42AEEC), Color(0xFF53E2AE)],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UsersPage(
                        userRepository: userRepository,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60), // spacing for bottom button
              ],
            ),
          ),
          // Modern Update Button at Bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.system_update, size: 24),
                label: const Text(
                  'Check for Update',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800, // dark grey

                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await OTAUpdateManager.instance.checkForUpdate(
                    context,
                    "https://task-management-1455a.web.app/version.json",
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 110,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 25,
            child: Icon(Icons.person, color: Colors.deepPurpleAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Welcome, $username",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required LinearGradient gradient,
        required VoidCallback onTap,
      }) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.18),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onTap,
      ),
    );
  }
}

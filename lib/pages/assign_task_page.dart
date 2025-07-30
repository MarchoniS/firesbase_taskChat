import 'package:flutter/material.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

class AssignTaskPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final UserRepository userRepository;

  const AssignTaskPage({
    Key? key,
    required this.taskRepository,
    required this.userRepository,
  }) : super(key: key);

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _taskController = TextEditingController();
  Set<String> selectedUserIds = {};
  bool _loading = false;
  bool _usersLoading = true;
  List<UserModel> allUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _usersLoading = true);
    try {
      allUsers = await widget.userRepository.getAllUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    } finally {
      setState(() => _usersLoading = false);
    }
  }

  Future<void> _assignTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty || selectedUserIds.isEmpty) return;

    setState(() => _loading = true);

    try {
      if (selectedUserIds.length == 1) {
        await widget.taskRepository.assignTask(
          task: text,
          assignedToUserId: selectedUserIds.first,
        );
      } else {
        await widget.taskRepository.assignTaskToMultipleUsers(
          task: text,
          userIds: selectedUserIds.toList(),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Task assigned successfully!')),
      );

      _taskController.clear();
      setState(() => selectedUserIds.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to assign task: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _usersLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Task',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _taskController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Task Description',
                    hintText: 'Enter task details...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Assign to Users',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: allUsers.map((user) {
                    final isSelected = selectedUserIds.contains(user.uid);
                    return FilterChip(
                      label: Text(user.username),
                      selected: isSelected,
                      selectedColor: Colors.indigo.shade100,
                      checkmarkColor: Colors.indigo,
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedUserIds.add(user.uid);
                          } else {
                            selectedUserIds.remove(user.uid);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send,color: Colors.white,),
                    label: const Text(
                      'Assign Task',
                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loading ? null : _assignTask,
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

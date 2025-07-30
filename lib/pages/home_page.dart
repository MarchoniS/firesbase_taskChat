import 'package:flutter/material.dart';
import 'package:task/pages/users_page.dart';
import '../controllers/auth_controller.dart';
import '../repositories/user_repository.dart';
import '../pages/chat_page.dart';
import '../pages/task_page.dart';
import '../repositories/task_repository.dart';
import 'assign_task_page.dart';
import 'all_task_page.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

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
  bool loadingTasks = true;
  bool showTasks = true;
  List<AssignedTask> pendingTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await widget.userRepository.getCurrentUser();
    final uid = widget.authController.currentUser?.uid;

    if (user != null && uid != null) {
      final tasks = await widget.taskRepository.getTasksAssignedToMe(uid);
      setState(() {
        username = user.username;
        pendingTasks = tasks.where((t) => t.status == 'pending').toList();
        loading = false;
        loadingTasks = false;
      });
    } else {
      setState(() {
        username = 'User';
        loading = false;
        loadingTasks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final limitedTasks = pendingTasks.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FC),
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent.shade200,
        elevation: 3,
        title: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Colors.deepPurpleAccent.shade200,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TaskChat',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.7,
                  ),
                ),
                Text(
                  'Welcome, $username',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.91),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            tooltip: 'Logout',
            onPressed: () async {
              await widget.authController.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            if (loadingTasks)
              const Center(child: CircularProgressIndicator())
            else ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    showTasks = !showTasks;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Pending Tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      Icon(
                        showTasks ? Icons.expand_less : Icons.expand_more,
                        color: Colors.deepPurpleAccent,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: limitedTasks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No pending tasks.',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                      )
                    : SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: limitedTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final task = limitedTasks[index];
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                double cardWidth = constraints.maxWidth * 0.90;
                                cardWidth = cardWidth < 360 ? cardWidth : 360;

                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final TextEditingController
                                        taskController = TextEditingController(
                                          text: task.task,
                                        );
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          title: const Text(
                                            'Update Task',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                TextField(
                                                  controller: taskController,
                                                  readOnly: true,
                                                  maxLines: 3,
                                                  decoration: InputDecoration(
                                                    labelText: 'Task',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    disabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                              ),
                                                        ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.timelapse,
                                                  ),
                                                  label: const Text(
                                                    "Mark as In Progress",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    minimumSize:
                                                        const Size.fromHeight(
                                                          50,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    elevation: 4,
                                                    shadowColor: Colors
                                                        .blueAccent
                                                        .withOpacity(0.4),
                                                  ),
                                                  onPressed: () async {
                                                    await widget.taskRepository
                                                        .updateTaskStatus(
                                                          task.id,
                                                          'in_progress',
                                                        );
                                                    Navigator.pop(context);
                                                    _loadUserData();
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                  ),
                                                  label: const Text(
                                                    "Mark as Completed",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    minimumSize:
                                                        const Size.fromHeight(
                                                          50,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    elevation: 4,
                                                    shadowColor: Colors.green
                                                        .withOpacity(0.4),
                                                  ),
                                                  onPressed: () async {
                                                    await widget.taskRepository
                                                        .updateTaskStatus(
                                                          task.id,
                                                          'completed',
                                                        );
                                                    Navigator.pop(context);
                                                    _loadUserData();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text(
                                                'Close',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ],
                                          actionsPadding: const EdgeInsets.only(
                                            bottom: 12,
                                            right: 16,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: cardWidth,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurple.withOpacity(
                                            0.12,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.deepPurple.shade100,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.deepPurple
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.assignment_outlined,
                                                color: Colors.deepPurple,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              "Task",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          task.task,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '📅 ${DateFormat('dd MMM yyyy').format((task.updatedAt != null && task.updatedAt != task.createdAt) ? task.updatedAt! : task.createdAt!)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: task.status == 'pending'
                                                    ? Colors.orange
                                                    : task.status ==
                                                          'in_progress'
                                                    ? Colors.blue
                                                    : Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        (task.status ==
                                                                    'pending'
                                                                ? Colors.orange
                                                                : task.status ==
                                                                      'in_progress'
                                                                ? Colors.blue
                                                                : Colors.green)
                                                            .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                task.status == 'pending'
                                                    ? 'Pending'
                                                    : task.status ==
                                                          'in_progress'
                                                    ? 'In Progress'
                                                    : 'Completed',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                crossFadeState: showTasks
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 20),
            ],
            Card(
              elevation: 10,
              margin: const EdgeInsets.only(bottom: 32),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.add_task,
                      label: 'Assign New Task',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D67E4), Color(0xFF4ACBCC)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignTaskPage(
                              taskRepository: widget.taskRepository,
                              userRepository: widget.userRepository,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildActionButton(
                      icon: Icons.task_alt,
                      label: 'My Assigned Tasks',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF53E2AE), Color(0xFF8AE563)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignedTasksPage(
                              taskRepository: widget.taskRepository,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildActionButton(
                      icon: Icons.task_alt,
                      label: 'All Assigned Tasks',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF189F6E), Color(0xFF67BC44)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllTasksPage(
                              taskRepository: widget.taskRepository,
                              userRepository: widget.userRepository, // Add this
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    _buildActionButton(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Group Chat',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A63E5), Color(0xFF42AEEC)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GlobalChatPage(
                              userRepository: widget.userRepository,

                              taskRepository:
                                  widget.taskRepository ?? TaskRepository(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildActionButton(
                      icon: Icons.people_outline,
                      label: 'View All Users',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42AEEC), Color(0xFF53E2AE)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UsersPage(
                              userRepository: widget.userRepository,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.18),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 30, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onTap,
      ),
    );
  }
}

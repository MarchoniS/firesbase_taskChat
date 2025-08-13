import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../pages/assign_task_page.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class DraggableTaskBubble extends StatefulWidget {
  final int newTaskCount;
  final List<AssignedTask> newTasks;
  final TaskRepository taskRepository;
  final UserRepository userRepository;
  final VoidCallback? onPressed;

  const DraggableTaskBubble({
    Key? key,
    required this.newTaskCount,
    required this.newTasks,
    required this.taskRepository,
    required this.userRepository,
    this.onPressed,
  }) : super(key: key);

  @override
  State<DraggableTaskBubble> createState() => _DraggableTaskBubbleState();
}

class _DraggableTaskBubbleState extends State<DraggableTaskBubble>
    with TickerProviderStateMixin {
  Offset position = Offset.zero;
  late double screenWidth;
  late double screenHeight;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool isVisible = true;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _snapToEdge() {
    final snapX = (position.dx > screenWidth / 2)
        ? screenWidth - 70
        : 10;

    setState(() {
      position = Offset(snapX.toDouble(), position.dy);
      isDragging = false;
    });
  }

  void _checkDismiss() {
    final isBottom = position.dy >= screenHeight - 100;
    final isMiddle = position.dx >= (screenWidth / 2 - 50) &&
        position.dx <= (screenWidth / 2 + 50);

    if (isBottom && isMiddle) {
      setState(() => isVisible = false);
    } else {
      _snapToEdge();
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Tasks"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.newTasks.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final task = widget.newTasks[index];
              return ListTile(
                title: Text(task.task ?? 'No description'),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignTaskPage(
                        taskRepository: widget.taskRepository,
                        userRepository: widget.userRepository,
                        // Optionally pass selected task if needed
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        screenWidth = constraints.maxWidth;
        screenHeight = constraints.maxHeight;

        double defaultX = screenWidth - 70;
        double defaultY = screenHeight - 150;

        final x = (position.dx == 0) ? defaultX : position.dx;
        final y = (position.dy == 0) ? defaultY : position.dy;

        return Stack(
          children: [
            if (isDragging)
              Positioned(
                bottom: 40,
                left: screenWidth / 2 - 24,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: x.clamp(0, screenWidth - 56),
              top: y.clamp(
                kToolbarHeight + MediaQuery.of(context).padding.top,
                screenHeight - 56,
              ),
              child: GestureDetector(
                onPanStart: (_) => setState(() => isDragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    position += details.delta;
                  });
                },
                onPanEnd: (_) => _checkDismiss(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.deepPurpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.task, color: Colors.white, size: 20),
                          SizedBox(height: 2),
                          Text(
                            "Tasks",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      if (widget.newTaskCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.redAccent.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  "+${widget.newTaskCount}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Positioned.fill(
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _showDialog,
                          ),
                        ),
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
  }
}

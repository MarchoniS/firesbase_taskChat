import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedTasksPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final String? initialTaskId;

  const AssignedTasksPage({
    Key? key,
    required this.taskRepository,
    this.initialTaskId,
  }) : super(key: key);

  @override
  State<AssignedTasksPage> createState() => _AssignedTasksPageState();
}

class _AssignedTasksPageState extends State<AssignedTasksPage> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  List<AssignedTask> allTasks = [];
  List<AssignedTask> filteredTasks = [];
  Set<String> assignerIds = {};
  String? selectedAssigner;
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _taskSuggestions = [];
  bool _showCompleted = false;
  Map<String, String> assignerNames = {};
  AssignedTask? _task;

  // highlight feature
  final ScrollController _scrollController = ScrollController();
  String? _highlightTaskId;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _applyFilters();
    }
  }

  @override
  void initState() {
    super.initState();
    _highlightTaskId = widget.initialTaskId;

    if (widget.initialTaskId != null) {
      widget.taskRepository.getAssignedTaskById(widget.initialTaskId!).then((task) {
        setState(() {
          _task = task;
        });
      });
    } else {
      _refreshTasks();
    }

    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    setState(() {
      filteredTasks = allTasks.where((task) {
        final matchesDate = (startDate == null ||
            task.createdAt.isAfter(startDate!)) &&
            (endDate == null ||
                task.createdAt.isBefore(endDate!.add(const Duration(days: 1))));
        final matchesAssigner =
            selectedAssigner == null || task.assignedByUserId == selectedAssigner;
        final matchesSearch = task.task.toLowerCase().contains(query);
        return matchesDate && matchesAssigner && matchesSearch;
      }).toList();

      _taskSuggestions = allTasks
          .map((task) => task.task)
          .where((title) => title.toLowerCase().contains(query))
          .toSet()
          .toList();
    });

    // if highlighting a task, scroll to it once filters are applied
    if (_highlightTaskId != null && filteredTasks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final index = filteredTasks.indexWhere((t) => t.id == _highlightTaskId);
        if (index != -1) {
          _scrollController.animateTo(
            index * 92.0, // approximate height per card
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );

          // const highlightDuration = Duration(seconds: 10);
          //
          // Future.delayed(highlightDuration, () {
          //   if (mounted) {
          //     setState(() {
          //       _highlightTaskId = null;
          //     });
          //   }
          // });
        }
      });
    }
  }

  Future<void> _refreshTasks() async {
    if (_uid == null) return;
    final tasks = await widget.taskRepository.getTasksAssignedToMe(_uid);
    assignerIds = tasks.map((t) => t.assignedByUserId).toSet();
    assignerNames = await _fetchAssignerNames(assignerIds);
    setState(() {
      allTasks = tasks;
      _highlightTaskId = null; // Clear highlight only when refreshed
    });
    _applyFilters();
  }

  Future<Map<String, String>> _fetchAssignerNames(Set<String> ids) async {
    Map<String, String> result = {};
    for (var id in ids) {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(id).get();
      result[id] = doc.data()?['username'] ?? id;
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // single task view
    // if (widget.initialTaskId != null && _task != null && allTasks.isEmpty) {
    //   return Scaffold(
    //     appBar: AppBar(title: Text(_task!.task)),
    //     body: Padding(
    //       padding: const EdgeInsets.all(16.0),
    //       child: Text(
    //           "Status: ${_task!.status}\nAssigned by: ${_task!.assignedByUserId}"),
    //     ),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Tasks'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: _uid == null
          ? const Center(child: Text("You must be logged in"))
          : RefreshIndicator(
        onRefresh: _refreshTasks,
        child: FutureBuilder<List<AssignedTask>>(
          future: widget.taskRepository.getTasksAssignedToMe(_uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (allTasks.isEmpty) {
              allTasks = snapshot.data ?? [];
              assignerIds = allTasks.map((t) => t.assignedByUserId).toSet();

              _fetchAssignerNames(assignerIds).then((names) {
                assignerNames = names;
                _applyFilters();
              });
            }

            final completedTasks =
            filteredTasks.where((t) => t.status == 'completed').toList();
            final pendingTasks =
            filteredTasks.where((t) => t.status != 'completed').toList();

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  _buildAssignerAndDateFilters(),
                  const SizedBox(height: 12),
                  _buildStatusToggle(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                      _showCompleted ? completedTasks.length : pendingTasks.length,
                      itemBuilder: (context, index) {
                        final task = _showCompleted
                            ? completedTasks[index]
                            : pendingTasks[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 5000),
                          color: task.id == _highlightTaskId
                              ? Colors.grey.withOpacity(0.4)
                              : Colors.transparent,
                          child: _buildTaskCard(task),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search tasks',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _applyFilters();
              },
            )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_searchQuery.isNotEmpty && _taskSuggestions.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            height: 150,
            child: ListView.builder(
              itemCount: _taskSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _taskSuggestions[index];
                return ListTile(
                  title: Text(suggestion),
                  onTap: () {
                    _searchController.text = suggestion;
                    _searchQuery = suggestion;
                    _applyFilters();
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAssignerAndDateFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedAssigner,
            hint: const Text("Filter by Assigner"),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text("All Assigners"),
              ),
              ...assignerIds.map((id) {
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(assignerNames[id] ?? "Assigner ID: $id"),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                selectedAssigner = value;
              });
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.date_range),
          label: const Text("Filter by Date"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _showCompleted = false),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            !_showCompleted ? Colors.indigo : Colors.grey.shade300,
            foregroundColor: !_showCompleted ? Colors.white : Colors.black,
          ),
          child: const Text('Pending Tasks'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _showCompleted = true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            _showCompleted ? Colors.indigo : Colors.grey.shade300,
            foregroundColor: _showCompleted ? Colors.white : Colors.black,
          ),
          child: const Text('Completed Tasks'),
        ),
      ],
    );
  }

  Widget _buildTaskCard(AssignedTask task) {
    final isCompleted = task.status == 'completed';
    final assignerName = assignerNames[task.assignedByUserId] ?? task.assignedByUserId;

    // full card color change if highlighted
    final cardColor = task.id == _highlightTaskId
        ? Colors.grey.withOpacity(0.3) // highlighted full card color
        : Colors.white; // default card color

    return Card(
      color: cardColor, // apply color here
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.pending_actions,
          color: isCompleted ? Colors.green : Colors.orange,
        ),
        title: Text(
          task.task,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${task.status.toUpperCase()}',
              style: TextStyle(
                color: isCompleted ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('Assigned by: $assignerName', style: const TextStyle(fontSize: 12)),
            Text(
              'Assigned on: ${DateFormat('dd MMM yyyy').format(task.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: isCompleted
            ? null
            : IconButton(
          icon: const Icon(Icons.check),
          tooltip: "Mark as complete",
          color: Colors.blue,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: const Text('Mark Task as Completed'),
                content: const Text(
                    'Are you sure you want to mark this task as completed?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await widget.taskRepository.updateTaskStatus(task.id, 'completed');
              _refreshTasks();
            }
          },
        ),
      ),
    );
  }

}

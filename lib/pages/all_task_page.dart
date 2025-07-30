import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class AllTasksPage extends StatefulWidget {
  final TaskRepository taskRepository;
  final UserRepository userRepository;

  const AllTasksPage({
    Key? key,
    required this.taskRepository,
    required this.userRepository,
  }) : super(key: key);

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  List<AssignedTask> allTasks = [];
  Map<String, String> userNames = {}; // uid -> username
  bool loading = true;

  String searchQuery = '';
  String? statusFilter;
  String? assignedToFilter;
  String? assignedByFilter;
  DateTimeRange? dateRange;

  bool filtersExpanded = false; // collapsed by default

  @override
  void initState() {
    super.initState();
    _loadTasksAndUsers();
  }

  Future<void> _loadTasksAndUsers() async {
    setState(() => loading = true);
    try {
      final users = await widget.userRepository.getAllUsers();
      final tasksAssignedBy = await widget.taskRepository.getTasksAssignedByMe();
      final tasksAssignedTo = await widget.taskRepository.getTasksAssignedToMe("", limit: 100);

      final all = [...tasksAssignedBy, ...tasksAssignedTo];

      userNames = {for (var u in users) u.uid: u.username};

      setState(() {
        allTasks = all;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  bool get _isFilterApplied =>
      searchQuery.trim().isNotEmpty ||
          statusFilter != null ||
          assignedToFilter != null ||
          assignedByFilter != null ||
          dateRange != null;

  List<AssignedTask> get filteredTasks {
    final lowerQuery = searchQuery.trim().toLowerCase();
    return allTasks.where((task) {
      if (!_isFilterApplied) return true;

      final taskMatch = task.task.toLowerCase().contains(lowerQuery);
      final assignedToMatch = userNames[task.assignedToUserId]?.toLowerCase().contains(lowerQuery) ?? false;
      final assignedByMatch = userNames[task.assignedByUserId]?.toLowerCase().contains(lowerQuery) ?? false;

      final statusMatch = statusFilter == null || task.status == statusFilter;
      final assignedToFilterMatch = assignedToFilter == null || task.assignedToUserId == assignedToFilter;
      final assignedByFilterMatch = assignedByFilter == null || task.assignedByUserId == assignedByFilter;

      final createdAt = task.createdAt;
      final dateMatch = dateRange == null ||
          ((createdAt.isAtSameMomentAs(dateRange!.start) || createdAt.isAfter(dateRange!.start)) &&
              (createdAt.isAtSameMomentAs(dateRange!.end) || createdAt.isBefore(dateRange!.end)));

      return (taskMatch || assignedToMatch || assignedByMatch) &&
          statusMatch &&
          assignedToFilterMatch &&
          assignedByFilterMatch &&
          dateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = userNames.entries.toList();

    final tasksToShow = filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: Colors.indigo,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Collapsible filter section
          ExpansionTile(
            title: const Text(
              "Filters",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            initiallyExpanded: filtersExpanded,
            onExpansionChanged: (val) => setState(() => filtersExpanded = val),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: _buildFilters(users),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear Filters"),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      statusFilter = null;
                      assignedToFilter = null;
                      assignedByFilter = null;
                      dateRange = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 0),
          Expanded(
            child: tasksToShow.isEmpty
                ? const Center(
              child: Text(
                "No results found",
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            )
                : _isFilterApplied
                ? _buildGroupedTaskList(users, tasksToShow)
                : _buildAllTasksList(tasksToShow),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<MapEntry<String, String>> users) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by task or username...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          controller: TextEditingController(text: searchQuery),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: statusFilter,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) => setState(() => statusFilter = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: assignedToFilter,
                decoration: InputDecoration(
                  labelText: 'Assigned To',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...users.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                ],
                onChanged: (val) => setState(() => assignedToFilter = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: assignedByFilter,
                decoration: InputDecoration(
                  labelText: 'Assigned By',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...users.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                ],
                onChanged: (val) => setState(() => assignedByFilter = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.indigo.shade700,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black87,
                          ),
                          datePickerTheme: DatePickerThemeData(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
                                  (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.white;
                                } else if (states.contains(WidgetState.disabled)) {
                                  return Colors.grey;
                                }
                                return Colors.black87;
                              },
                            ),
                            dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                  (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.indigo.shade700;
                                } else if (states.contains(WidgetState.hovered)) {
                                  return Colors.indigo.shade50;
                                }
                                return Colors.transparent;
                              },
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) setState(() => dateRange = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateRange == null
                              ? 'Filter by Date'
                              : "${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: dateRange == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      if (dateRange != null)
                        GestureDetector(
                          onTap: () => setState(() => dateRange = null),
                          child: const Icon(Icons.close, color: Colors.redAccent),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupedTaskList(List<MapEntry<String, String>> users, List<AssignedTask> tasks) {
    return ListView(
      children: [
        ...users.map((entry) {
          final userId = entry.key;
          final userName = entry.value;

          final assignedToUser = tasks.where((t) => t.assignedToUserId == userId).toList();
          final assignedByUser = tasks.where((t) => t.assignedByUserId == userId).toList();

          if (assignedToUser.isEmpty && assignedByUser.isEmpty) return const SizedBox();

          return ExpansionTile(
            key: ValueKey(userId),
            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              if (assignedToUser.isNotEmpty)
                _buildGroupedSection("Assigned To $userName", assignedToUser),
              if (assignedByUser.isNotEmpty)
                _buildGroupedSection("Assigned By $userName", assignedByUser),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAllTasksList(List<AssignedTask> tasks) {
    // Sort tasks descending by updatedAt if present or createdAt
    final sortedTasks = List<AssignedTask>.from(tasks)
      ..sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt;
        final dateB = b.updatedAt ?? b.createdAt;
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final assignedTo = userNames[task.assignedToUserId] ?? task.assignedToUserId;
        final assignedBy = userNames[task.assignedByUserId] ?? task.assignedByUserId;

        Color statusColor;
        IconData statusIcon;
        String statusLabel;

        switch (task.status) {
          case 'completed':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusLabel = 'Completed';
            break;
          case 'in_progress':
            statusColor = Colors.orange;
            statusIcon = Icons.timelapse;
            statusLabel = 'In Progress';
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.pending;
            statusLabel = 'Pending';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        task.task,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      backgroundColor: statusColor.withOpacity(0.15),
                      avatar: Icon(statusIcon, color: statusColor, size: 18),
                      label: Text(statusLabel,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Assigned To / By
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Assigned to: $assignedTo',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Assigned by: $assignedBy',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Created and Updated dates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Created: ${DateFormat('dd MMM yyyy').format(task.createdAt)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      task.updatedAt != null
                          ? 'Updated: ${DateFormat('dd MMM yyyy').format(task.updatedAt)}'
                          : '',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedSection(String title, List<AssignedTask> tasks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final assignedTo = userNames[task.assignedToUserId] ?? task.assignedToUserId;
            final assignedBy = userNames[task.assignedByUserId] ?? task.assignedByUserId;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  task.status == 'completed'
                      ? Icons.check_circle
                      : task.status == 'in_progress'
                      ? Icons.timelapse
                      : Icons.pending,
                  color: task.status == 'completed'
                      ? Colors.green
                      : task.status == 'in_progress'
                      ? Colors.orange
                      : Colors.grey,
                ),
                title: Text(task.task),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: ${task.status.toUpperCase()}"),
                    Text("Assigned to: $assignedTo"),
                    Text("Assigned by: $assignedBy"),
                    Text("Created: ${DateFormat('dd MMM yyyy').format(task.createdAt)}"),
                    if (task.updatedAt != null)
                      Text("Updated: ${DateFormat('dd MMM yyyy').format(task.updatedAt!)}"),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

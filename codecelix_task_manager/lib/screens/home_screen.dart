import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = 'All';

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFE5484D);
      case 'Medium':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF4CAF82);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: ['All', 'Pending', 'Completed'].map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selected
                            ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: taskProvider.getTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var tasks = snapshot.data!;
                if (filter == 'Pending') tasks = tasks.where((t) => !t.isCompleted).toList();
                if (filter == 'Completed') tasks = tasks.where((t) => t.isCompleted).toList();

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No tasks yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Tap + to add your first task', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    final pColor = _priorityColor(task.priority);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => taskProvider.toggleComplete(task),
                            child: Container(
                              width: 24, height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: task.isCompleted ? primary : Colors.transparent,
                                border: Border.all(color: task.isCompleted ? primary : Colors.grey.shade300, width: 2),
                              ),
                              child: task.isCompleted
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: task.isCompleted ? Colors.grey.shade400 : const Color(0xFF2D2A4A),
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: pColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(task.priority,
                                          style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.dueDate.toLocal().toString().split(' ')[0],
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 19, color: Colors.grey.shade500),
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task))),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFE5484D)),
                                onPressed: () => taskProvider.deleteTask(task.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddEditTaskScreen())),
        backgroundColor: primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
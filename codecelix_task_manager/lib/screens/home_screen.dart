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

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Pending', 'Completed'].map((f) {
                return ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() => filter = f),
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
                  return const Center(child: Text('No tasks yet. Tap + to add one.'));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return ListTile(
                      title: Text(task.title, style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
                      subtitle: Text('${task.priority} • Due: ${task.dueDate.toLocal().toString().split(' ')[0]}'),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => taskProvider.toggleComplete(task),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task))),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => taskProvider.deleteTask(task.id),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
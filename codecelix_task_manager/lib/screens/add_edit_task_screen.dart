import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({super.key, this.task});
  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime dueDate = DateTime.now();
  String priority = 'Low';

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titleCtrl.text = widget.task!.title;
      descCtrl.text = widget.task!.description;
      dueDate = widget.task!.dueDate;
      priority = widget.task!.priority;
    }
  }

  void _save() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title is required')));
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (widget.task == null) {
      final newTask = Task(
        id: '', title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
        dueDate: dueDate, priority: priority, userId: uid,
      );
      await taskProvider.addTask(newTask);
      await NotificationService.scheduleTaskReminder(
          DateTime.now().millisecondsSinceEpoch ~/ 1000, titleCtrl.text.trim(), dueDate);
    } else {
      widget.task!.title = titleCtrl.text.trim();
      widget.task!.description = descCtrl.text.trim();
      widget.task!.dueDate = dueDate;
      widget.task!.priority = priority;
      await taskProvider.updateTask(widget.task!);
      await NotificationService.scheduleTaskReminder(
          widget.task!.id.hashCode, widget.task!.title, dueDate);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? 'Add Task' : 'Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Due: ${dueDate.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => dueDate = picked);
              },
            ),
            DropdownButton<String>(
              value: priority,
              items: ['Low', 'Medium', 'High']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => priority = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save Task')),
          ],
        ),
      ),
    );
  }
}
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
  bool saving = false;

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

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFE5484D);
      case 'Medium':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF4CAF82);
    }
  }

  void _save() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Title is required'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => saving = true);
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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text(widget.task == null ? 'Add Task' : 'Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_rounded)),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text('Due: ${dueDate.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: ['Low', 'Medium', 'High'].map((p) {
                final selected = priority == p;
                final color = _priorityColor(p);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => priority = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? color : Colors.grey.shade200, width: 1.5),
                      ),
                      child: Text(p,
                          style: TextStyle(
                              color: selected ? color : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.task == null ? 'Save Task' : 'Update Task'),
            ),
          ],
        ),
      ),
    );
  }
}
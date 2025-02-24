// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_schedule_generator/services/gemini_service.dart';

import '../models/tasks.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Task> tasks = [];
  bool isLoading = false;
  String scheduleResult = "";
  String? priority;
  final taskController = TextEditingController();
  final durationController = TextEditingController();
  final deadlineController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Generator"),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildInputField(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4,
                child: _buildTaskList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            const SizedBox(height: 20),
            _buildScheduleResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Column(
      children: [
        TextField(
          controller: taskController ,
          decoration: InputDecoration(
            labelText: "Task Name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: durationController,
          decoration: InputDecoration(
            labelText: "Duration (minutes)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: deadlineController,
          decoration: InputDecoration(
            labelText: "Deadline",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: priority,
          decoration: InputDecoration(
            labelText: "Priority",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: const ["High", "Medium", "Low"]
              .map((priority) => DropdownMenuItem(
            value: priority,
            child: Text(priority),
          ))
              .toList(),
          onChanged: (value) => setState(() => priority = value),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _addTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(
                horizontal: 50, vertical: 15),
          ),
          child: const Text("Add Task",
              style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  void _addTask() {
    if(taskController.text.isNotEmpty && durationController.text.isNotEmpty && deadlineController.text.isNotEmpty && priority != null) {
      setState(() {
        tasks.add(Task(
          name: taskController.text,
          priority: priority!,
          duration: int.tryParse(durationController.text) ?? 5,
          deadline: deadlineController.text,
        ));
      });
      _clearInputs();
    }
  }

  void _clearInputs() {
    taskController.clear();
    durationController.clear();
    deadlineController.clear();
    setState(() {
      priority = null;
    });
  }

  Future<void> _generateSchedule() async {
    setState(() {
      isLoading = true;
    });
    try {
      String schedule = await GeminiService().generateSchedule(tasks);
      setState(() {
        scheduleResult = schedule;
      });
    } catch(e) {
      setState(() {
        scheduleResult = "Failed to Generate Schedule: $e";
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildTaskList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: tasks.length, // Contoh jumlah task
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text(task.name,
                  style:
                  const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Priority: ${task.priority} | Duration: ${task.duration} minutes | Deadline: ${task.deadline}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    tasks.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenerateButton() {

    return isLoading ? const CircularProgressIndicator() : ElevatedButton(
      onPressed: _generateSchedule,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding:
        const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      child: const Text("Generate Schedule",
          style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildScheduleResult() {
    return  scheduleResult.isNotEmpty
    ?   Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              scheduleResult,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ) : Container();
  }
}

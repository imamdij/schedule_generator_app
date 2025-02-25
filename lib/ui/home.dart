import 'package:flutter/material.dart';
import 'package:flutter_schedule_generator/services/gemini_service.dart';
import '../models/tasks.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Task> tasks = [];
  bool isLoading = false;
  String scheduleResult = "";
  String? priority;
  TimeOfDay? selectedTime;
  final taskController = TextEditingController();
  final durationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Warna-warna baru
  final Color primaryColor = const Color(0xFF2D3E50);
  final Color secondaryColor = const Color(0xFF546E7A);
  final Color buttonColor = const Color(0xFF37474F);
  final Color borderColor = const Color(0xFFB0BEC5);

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _scheduleNotification(Task task) async {
    final time = _parseTimeOfDay(task.deadline);
    if (time != null) {
      tz.initializeTimeZones(); // Inisialisasi zona waktu

      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        importance: Importance.max,
        priority: Priority.high,
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.hashCode,
        'Task Reminder',
        'You have a task: ${task.name}',
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AstraPlan",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2D3E50),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.import_export, color: Colors.white,),
            onPressed: _exportSchedule,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              const Color(0xFFECEFF1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputCard(),
              const SizedBox(height: 24),
              _buildTaskListCard(),
              const SizedBox(height: 24),
              _buildGenerateButton(),
              const SizedBox(height: 24),
              _buildScheduleResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_task, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  "New Task",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: taskController,
              label: "Task Name",
              icon: Icons.edit_note,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: durationController,
              label: "Duration (minutes)",
              icon: Icons.timer,
              isNumeric: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTimePickerField(),
            const SizedBox(height: 16),
            _buildPrioritySelector(),
            const SizedBox(height: 24),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool isNumeric = false,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: secondaryColor),
        prefixIcon: Icon(icon, color: primaryColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
      ),
    );
  }

  Widget _buildTimePickerField() {
    return InkWell(
      onTap: () async {
        final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() => selectedTime = time);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
          color: const Color(0xFFF5F5F5),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: primaryColor),
            const SizedBox(width: 12),
            Text(
              selectedTime != null
                  ? selectedTime!.format(context)
                  : "Select Deadline Time",
              style: TextStyle(
                color: selectedTime != null ? Colors.black : secondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return DropdownButtonFormField<String>(
      value: priority,
      decoration: InputDecoration(
        labelText: "Priority",
        prefixIcon: Icon(Icons.flag, color: primaryColor),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      hint: const Text("Select Priority"),
      items: ["High", "Medium", "Low"].map((priorityValue) {
        Color priorityColor;
        switch (priorityValue) {
          case "High":
            priorityColor = Colors.red;
            break;
          case "Medium":
            priorityColor = Colors.orange;
            break;
          default:
            priorityColor = Colors.green;
        }
        return DropdownMenuItem(
          value: priorityValue,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(priorityValue),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => priority = value),
      validator: (value) {
        if (value == null) {
          return 'Please select a priority';
        }
        return null;
      },
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Validasi form terlebih dahulu
          if (_formKey.currentState!.validate() && selectedTime != null) {
            // Jika valid, tambahkan tugas
            _addTask();
          } else {
            if (selectedTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select a deadline time'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(20),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Add Task",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    setState(() {
      tasks.add(Task(
        name: taskController.text,
        priority: priority!,
        duration: int.tryParse(durationController.text) ?? 5,
        deadline: selectedTime!.format(context),
      ));
      _scheduleNotification(tasks.last);
    });
    _clearInputs();
  }

  void _clearInputs() {
    taskController.clear();
    durationController.clear();
    setState(() {
      selectedTime = null;
      priority = null;
    });
  }

  Widget _buildTaskListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: primaryColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Your Tasks",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          tasks.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.note_add,
                        size: 48,
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No tasks added yet",
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    Color priorityColor;
                    switch (task.priority) {
                      case "High":
                        priorityColor = Colors.red;
                        break;
                      case "Medium":
                        priorityColor = Colors.orange;
                        break;
                      default:
                        priorityColor = Colors.green;
                    }
                    return Container(
                      key: Key('$index'),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF5F5F5),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(
                          task.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${task.duration} min",
                                  style: TextStyle(color: secondaryColor),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.deadline,
                                  style: TextStyle(color: secondaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: secondaryColor,
                              ),
                              onPressed: () {
                                _showEditDialog(task, index);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  tasks.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final Task task = tasks.removeAt(oldIndex);
                      tasks.insert(newIndex, task);
                    });
                  },
                ),
        ],
      ),
    );
  }

  void _showEditDialog(Task task, int index) {
    final editTaskController = TextEditingController(text: task.name);
    final editDurationController =
    TextEditingController(text: task.duration.toString());
    String? editPriority = task.priority;
    TimeOfDay? editTime = _parseTimeOfDay(task.deadline);

    showDialog(
      context: context,
      builder: (context) {
        final _editFormKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text(
            "Edit Task",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // Lebar modal
            child: Form(
              key: _editFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity, // Lebar penuh
                      child: TextFormField(
                        controller: editTaskController,
                        decoration: InputDecoration(
                          labelText: "Task Name",
                          prefixIcon: Icon(Icons.edit_note, color: primaryColor),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter task name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, // Lebar penuh
                      child: TextFormField(
                        controller: editDurationController,
                        decoration: InputDecoration(
                          labelText: "Duration (minutes)",
                          prefixIcon: Icon(Icons.timer, color: primaryColor),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, // Lebar penuh
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: editTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => editTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFFF5F5F5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                editTime != null
                                    ? editTime!.format(context)
                                    : "Select Deadline Time",
                                style: TextStyle(
                                  color: editTime != null
                                      ? Colors.black
                                      : secondaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, // Lebar penuh
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(0xFFF5F5F5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: editPriority,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.flag, color: primaryColor),
                              border: InputBorder.none,
                            ),
                            hint: const Text("Select Priority"),
                            items: ["High", "Medium", "Low"].map((priorityValue) {
                              Color priorityColor;
                              switch (priorityValue) {
                                case "High":
                                  priorityColor = Colors.red;
                                  break;
                                case "Medium":
                                  priorityColor = Colors.orange;
                                  break;
                                default:
                                  priorityColor = Colors.green;
                              }
                              return DropdownMenuItem(
                                value: priorityValue,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: priorityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(priorityValue),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => editPriority = value),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a priority';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: secondaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_editFormKey.currentState!.validate() && editTime != null) {
                  setState(() {
                    tasks[index] = Task(
                      name: editTaskController.text,
                      priority: editPriority!,
                      duration: int.tryParse(editDurationController.text) ?? 5,
                      deadline: editTime!.format(context),
                    );
                  });
                  Navigator.pop(context);
                } else {
                  if (editTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Please select a deadline time'),
                      backgroundColor: Colors.red[400],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      margin: const EdgeInsets.all(20),
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _generateSchedule,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Generate Schedule",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one task'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final geminiService = GeminiService();
      final result = await geminiService.generateSchedule(tasks);
      setState(() {
        scheduleResult = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating schedule: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  Widget _buildScheduleResult() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: primaryColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Generated Schedule",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            scheduleResult.isEmpty
                ? "No schedule generated yet"
                : scheduleResult,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSchedule() async {
    if (scheduleResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No schedule to export'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/schedule.pdf');
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(scheduleResult),
          );
        },
      ),
    );

    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Schedule exported to PDF'),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final format = DateFormat("HH:mm"); // Sesuaikan format dengan input waktu
      final dateTime = format.parse(timeString);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return null; // Jika gagal, kembalikan null agar tidak menyebabkan error
    }
  }
}

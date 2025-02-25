import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/tasks.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
  final String apiKey;
  GeminiService() :apiKey = dotenv.env["GEMINI_API_KEY"] ?? "" {
    if (apiKey.isEmpty) {
      throw ArgumentError("API key is missing");
    }
  }

  Future<String> generateSchedule(List<Task> tasks) async {
    _validateTasks(tasks);
    final prompt = _buildPrompt(tasks);

    try {
      print("Prompt: \n$prompt");
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$apiKey"),
        headers: {
          "Content-Type" : "application/json"
        },
        body: jsonEncode({
          "contents": [{
            "role": "user",
            "parts":[ {"text": prompt }
            ]
          }]
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ArgumentError("Failed to generate schedule: $e");
    }
  }

  String _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw ArgumentError("Invalid API Key or Unauthorized Access");
    } else if (response.statusCode == 429) {
      throw ArgumentError("Rate Limit Exceeded");
    } else if (response.statusCode == 500) {
      throw ArgumentError("Internal Server Error");
    } else if (response.statusCode == 503) {
      throw ArgumentError("Service Unavailable");
    } else if (response.statusCode == 200) {
      if (data["candidates"] != null &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0]["content"] != null &&
          data["candidates"][0]["content"]["parts"] != null &&
          data["candidates"][0]["content"]["parts"].isNotEmpty &&
          data["candidates"][0]["content"]["parts"][0]["text"] != null) {

        String scheduleText = data["candidates"][0]["content"]["parts"][0]["text"];
        return _formatScheduleText(scheduleText);
      } else {
        throw ArgumentError("Response format is invalid or missing required fields.");
      }
    } else {
      throw ArgumentError("Unknown Error: ${response.body}");
    }
  }

  String _formatScheduleText(String text) {
    // Split text into lines
    List<String> lines = text.split('\n');
    List<String> formattedLines = [];

    for (String line in lines) {
      // Check if line contains time range
      if (RegExp(r'\d{1,2}:\d{2}\s*(?:AM|PM)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM)').hasMatch(line)) {
        // Find the time range part
        RegExp timeRangeRegex = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM)\s*-\s*\d{1,2}:\d{2}\s*(?:AM|PM))(.*)');
        var match = timeRangeRegex.firstMatch(line);

        if (match != null) {
          // Wrap time range in bold tags
          String timeRange = match.group(1) ?? "";
          String restOfLine = match.group(2) ?? "";
          formattedLines.add("**$timeRange:**$restOfLine");
        } else {
          formattedLines.add(line);
        }
      } else {
        formattedLines.add(line);
      }
    }

    return formattedLines.join('\n');
  }

  String _buildPrompt(List<Task> tasks) {
    final tasksList = tasks.map((task) =>
    "${task.name} (Priority: ${task.priority}, Duration: ${task.duration} minutes, Deadline: ${task.deadline})"
    ).join("\n");

    return """
Buatkan jadwal harian yang optimal berdasarkan task berikut:
$tasksList

Format output harus seperti ini:
7:00 PM - 8:00 PM: [activity name]
(Priority: High/Medium/Low, Duration: X minutes, Deadline: HH:MM)

Catatan:
- Gunakan format 12 jam (AM/PM)
- Setiap aktivitas harus ada detail priority, duration, dan deadline
- Tambahkan jeda/istirahat antara aktivitas
- Berikan catatan tambahan jika diperlukan di bagian akhir dengan format **Catatan:**
""";
  }

  void _validateTasks(List<Task> tasks) {
    if(tasks.isEmpty) throw ArgumentError("Tasks cannot be Empty");
  }
}
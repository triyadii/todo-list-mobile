import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'task_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  static const String _geminiApiKeyPref = 'gemini_api_key';
  String? _geminiApiKey;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString(_geminiApiKeyPref);
  }

  String? get geminiApiKey => _geminiApiKey;

  Future<void> setGeminiApiKey(String? key) async {
    _geminiApiKey = key?.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
      await prefs.remove(_geminiApiKeyPref);
    } else {
      await prefs.setString(_geminiApiKeyPref, _geminiApiKey!);
    }
  }

  /// Process user prompt and generate intelligent response.
  /// If Gemini API key is configured, uses Gemini 1.5 Flash.
  /// Otherwise, uses the built-in Smart Task Assistant with context awareness.
  Future<String> generateResponse(String userPrompt) async {
    final taskService = TaskService();
    final tasks = taskService.tasks;

    if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
      try {
        return await _callGeminiApi(userPrompt, tasks);
      } catch (e) {
        // Fallback to internal assistant if external API fails
        return await _generateBuiltInResponse(userPrompt, tasks);
      }
    } else {
      return await _generateBuiltInResponse(userPrompt, tasks);
    }
  }

  Future<String> _callGeminiApi(String userPrompt, List<TaskModel> tasks) async {
    final taskSummary = _buildTaskSummary(tasks);
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final systemInstruction = '''
Anda adalah Asisten AI Cerdas untuk aplikasi Todo List.
Waktu sekarang: $now.
Berikut daftar tugas/aktivitas pengguna saat ini:
$taskSummary

Tugas Anda:
1. Membantu pengguna mengelola, memprioritaskan, dan menyelesaikan daftar kegiatan mereka.
2. Memberikan saran produktivitas yang ramah, ringkas, dan memotivasi dalam Bahasa Indonesia.
3. JIKA INPUT PENGGUNA TIDAK JELAS, AMBIGU, ATAU KURANG LENGKAP:
   - Jelaskan dengan ramah apa yang belum dipahami atau informasi apa yang masih kurang.
   - Jelaskan konsep format penginputan yang dibutuhkan (Judul, Tanggal, Jam mulai-selesai, Prioritas).
   - Berikan contoh format kalimat yang bisa langsung digunakan pengguna.
4. Jika pengguna meminta membuat tugas baru dan informasinya sudah lengkap, rangkumkan detailnya dengan jelas (Judul, Tanggal, Jam mulai, Jam selesai, Prioritas).
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$systemInstruction\n\nPesan Pengguna:\n$userPrompt'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? 'Tidak ada respons dari AI.';
        }
      }
    }
    throw Exception('Gemini API Error (${response.statusCode}): ${response.body}');
  }

  Future<String> _generateBuiltInResponse(String prompt, List<TaskModel> tasks) async {
    final lower = prompt.toLowerCase();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final pending = tasks.where((t) => t.isPending).toList();
    final inProgress = tasks.where((t) => t.isInProgress).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();
    final highPriority = tasks.where((t) => t.priority.toLowerCase() == 'high' && !t.isCompleted).toList();
    final todayTasks = tasks.where((t) => t.dueDate == today).toList();

    // 1. Task Creation intention
    if (lower.contains('buat task') || lower.contains('tambah task') || lower.contains('ingatkan saya') || lower.contains('bikin to do')) {
      return '''Saya siap membantu membuat task baru! 📝
Anda bisa menekan tombol '+' (Tambah) di layar Dashboard, atau beri tahu saya rincian tugasnya:
• **Judul Kegiatan:** ...
• **Tanggal:** (Contoh: $today)
• **Jam:** (Contoh: 09:00 - 10:00)
• **Prioritas:** Rendah / Sedang / Tinggi

Contoh format: *"Buat task Belajar Flutter besok jam 09:00 prioritas tinggi"*''';
    }

    // 2. Schedule summary / Hari ini
    if (lower.contains('hari ini') || lower.contains('jadwal') || lower.contains('agenda')) {
      if (todayTasks.isEmpty) {
        return '📅 **Jadwal Hari Ini ($today):**\nBelum ada task yang dijadwalkan untuk hari ini. Waktu yang tepat untuk merencanakan tugas baru atau istirahat sejenak!';
      }
      final buffer = StringBuffer('📅 **Jadwal Task Hari Ini ($today):**\n\n');
      for (var i = 0; i < todayTasks.length; i++) {
        final t = todayTasks[i];
        final icon = t.isCompleted ? '✅' : (t.isInProgress ? '⏳' : '📌');
        buffer.writeln('${i + 1}. $icon **${t.title}** (${t.startTime} - ${t.endTime}) [${t.priority.toUpperCase()}]');
      }
      return buffer.toString();
    }

    // 3. High priority check
    if (lower.contains('prioritas') || lower.contains('penting') || lower.contains('utama')) {
      if (highPriority.isEmpty) {
        return '🌟 Hebat! Saat ini tidak ada task dengan prioritas **Tinggi** yang tertunda. Anda bisa fokus pada task lainnya!';
      }
      final buffer = StringBuffer('⚡ **Task Prioritas Tinggi yang Perlu Perhatian Segera:**\n\n');
      for (var i = 0; i < highPriority.length; i++) {
        final t = highPriority[i];
        buffer.writeln('${i + 1}. 🔴 **${t.title}** - Jatuh tempo: ${t.dueDate} (${t.startTime})');
        if (t.description.isNotEmpty) {
          buffer.writeln('   _${t.description}_');
        }
      }
      buffer.writeln('\n💡 *Saran AI:* Selesaikan tugas berprioritas tinggi di awal hari saat energi Anda masih optimal!');
      return buffer.toString();
    }

    // 4. Status / Statistics query
    if (lower.contains('status') || lower.contains('ringkasan') || lower.contains('berapa task') || lower.contains('progress')) {
      return '''📊 **Ringkasan Aktivitas Anda:**
• 📌 Menunggu: ${pending.length} task
• ⏳ Sedang Berjalan: ${inProgress.length} task
• ✅ Selesai: ${completed.length} task
• ⚡ Prioritas Tinggi: ${highPriority.length} task

Total seluruh task: ${tasks.length}. ${completed.isNotEmpty ? 'Pertahankan produktivitas Anda!' : 'Mari mulai menyelesaikan task pertama Anda hari ini!'}''';
    }

    // 5. Productivity Tips
    if (lower.contains('tips') || lower.contains('motivasi') || lower.contains('fokus') || lower.contains('saran')) {
      return '''💡 **Tips Manajemen Waktu & Produktivitas AI:**
1. **Teknik Pomodoro:** Fokus kerja 25 menit, lalu istirahat 5 menit.
2. **Eat The Frog:** Selesaikan task paling sulit atau prioritas tinggi terlebih dahulu di pagi hari.
3. **Bagi Menjadi Sub-Tugas:** Pecah tugas besar menjadi langkah-langkah kecil agar terasa lebih ringan.
4. **Gunakan Reminder:** Pasang pengingat pada task penting agar tidak terlewat.''';
    }

    // 6. Response when input is unclear, ambiguous, or incomplete (panduan konsep penginputan)
    return '''Halo! Saya belum memahami maksud atau permintaan Anda secara lengkap. 🤔

Agar saya dapat membantu Anda dengan optimal, berikut panduan konsep penginputan yang dapat Anda gunakan:

📌 **1. Konsep Membuat Tugas Baru (Task):**
Sebutkan detail tugas dengan informasi berikut:
• **Judul:** Apa kegiatan yang ingin dilakukan
• **Tanggal:** Kapan dilaksanakan (contoh: *Hari ini*, *Besok*, atau *2026-10-29*)
• **Waktu/Jam:** (contoh: *09:00 - 11:00*)
• **Prioritas:** *Rendah* / *Sedang* / *Tinggi*

👉 *Contoh:* **"Buatkan task Meeting Tim besok jam 14:00 prioritas tinggi"**

⏰ **2. Konsep Memasang Pengingat (Reminder):**
👉 *Contoh:* **"Ingatkan saya bayar tagihan listrik jam 7 malam"**

📋 **3. Mengecek Aktivitas & Produktivitas:**
• *"Apa jadwal tugas saya hari ini?"*
• *"Tampilkan task dengan prioritas tinggi"*
• *"Berapa ringkasan tugas saya yang belum selesai?"*
• *"Beri tips fokus kerja"*

Silakan ketik atau gunakan tombol mikrofon 🎙️ untuk berbicara sesuai contoh di atas!''';
  }

  String _buildTaskSummary(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 'Tidak ada task saat ini.';
    final buffer = StringBuffer();
    for (var t in tasks) {
      buffer.writeln(
        '- [${t.status}] ${t.title} (Prioritas: ${t.priority}, Tanggal: ${t.dueDate}, Waktu: ${t.startTime}-${t.endTime}) : ${t.description}',
      );
    }
    return buffer.toString();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../config/theme.dart';
import '../../services/chat_service.dart';
import 'widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Speech to text continuous
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _userExplicitlyListening = false;
  String _selectedLocaleId = 'id_ID';
  String _baseCommittedText = '';

  // Timer for long speech duration
  Timer? _speechDurationTimer;
  int _speechDurationSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _quickSuggestions = [
    '📅 Jadwal hari ini',
    '⚡ Prioritas tinggi',
    '📊 Status ringkasan',
    '💡 Tips fokus kerja',
    '➕ Buat task baru',
  ];

  @override
  void initState() {
    super.initState();
    _chatService.addListener(_onChatUpdated);
    _chatService.fetchMessages();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
      if (available) {
        final locales = await _speechToText.locales();
        final indonesian = locales.where((l) => l.localeId.toLowerCase().startsWith('id')).toList();
        if (indonesian.isNotEmpty) {
          _selectedLocaleId = indonesian.first.localeId;
        } else {
          final system = await _speechToText.systemLocale();
          if (system != null) {
            _selectedLocaleId = system.localeId;
          }
        }
      }
      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _speechEnabled = false;
        });
      }
    }
  }

  void _onSpeechStatus(String status) {
    // If Android recognizer slice ends, and user still wants listening, seamlessly re-arm session!
    if (status == 'notListening' || status == 'done') {
      if (_userExplicitlyListening && !_chatService.isSending && mounted) {
        _baseCommittedText = _textController.text.trim();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (_userExplicitlyListening && !_chatService.isSending && mounted) {
            _listenSession();
          }
        });
      } else if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    // Ignore harmless pauses/timeouts in continuous mode unless user stopped or sending
    if (_userExplicitlyListening && !_chatService.isSending && mounted) {
      _baseCommittedText = _textController.text.trim();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_userExplicitlyListening && !_chatService.isSending && mounted) {
          _listenSession();
        }
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // Crucial: Reject any trailing callbacks if user has already sent message or stopped recording
    if (!mounted || !_userExplicitlyListening || _chatService.isSending) {
      return;
    }

    final recognized = result.recognizedWords.trim();
    if (recognized.isNotEmpty) {
      final combined = _baseCommittedText.isEmpty
          ? recognized
          : '$_baseCommittedText $recognized';
      _textController.text = combined;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: combined.length),
      );

      if (result.finalResult) {
        _baseCommittedText = combined;
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening || _userExplicitlyListening) {
      await _stopListening();
    } else {
      await _startContinuousListening();
    }
  }

  Future<void> _startContinuousListening() async {
    if (!_speechEnabled) {
      final available = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );
      setState(() {
        _speechEnabled = available;
      });
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin mikrofon diperlukan atau Speech Recognition tidak tersedia.'),
              backgroundColor: AppTheme.priorityHigh,
            ),
          );
        }
        return;
      }
    }

    _userExplicitlyListening = true;
    _baseCommittedText = _textController.text.trim();
    _speechDurationSeconds = 0;
    _speechDurationTimer?.cancel();
    _speechDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _userExplicitlyListening) {
        setState(() {
          _speechDurationSeconds++;
        });
      }
    });

    await _listenSession();
  }

  Future<void> _listenSession() async {
    if (!_userExplicitlyListening) return;

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false, // Keep continuous listening even with pauses
          listenMode: stt.ListenMode.confirmation, // Fast real-time recognition without dictation buffer lag
          localeId: _selectedLocaleId,
          listenFor: const Duration(minutes: 60), // Up to 60 minutes
          pauseFor: const Duration(seconds: 10), // Responsive pause handling
        ),
      );
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } catch (_) {
      if (_userExplicitlyListening) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_userExplicitlyListening && mounted) {
            _listenSession();
          }
        });
      }
    }
  }

  Future<void> _stopListening() async {
    _userExplicitlyListening = false;
    _speechDurationTimer?.cancel();
    await _speechToText.cancel();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _chatService.removeListener(_onChatUpdated);
    _speechDurationTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void _onChatUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    // Guard: Prevent sending while AI is still responding (anti-spam / anti-blank)
    if (_chatService.isSending || _chatService.isLoading) return;

    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty) return;

    // Immediately stop listening & drop audio buffer so no trailing text reappears
    _userExplicitlyListening = false;
    _speechDurationTimer?.cancel();
    _speechToText.cancel();

    // Clear input field and text buffer immediately
    _textController.clear();
    _baseCommittedText = '';

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    _chatService.sendMessage(text);
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text('Semua percakapan dengan Assistant akan dihapus dari server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.priorityHigh),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatService.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = _chatService.messages;
    final isSending = _chatService.isSending;
    final isLoading = _chatService.isLoading;
    final isRecordingActive = _isListening || _userExplicitlyListening;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, size: 22, color: AppTheme.secondary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Asisten Produktivitas Pribadi',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: theme.textTheme.bodySmall?.color),
              tooltip: 'Hapus Chat',
              onPressed: _confirmClearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.support_agent, size: 40, color: AppTheme.secondary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Mulai Chat dengan Assistant',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanyakan agenda hari ini, minta ringkasan tugas, atau rekam suara panjang dengan menekan tombol mikrofon di bawah.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return ChatBubble(message: messages[index]);
                        },
                      ),
          ),

          // Sending loading indicator with Cancel button
          if (isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assistant sedang merespon...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: theme.textTheme.bodySmall?.color ?? Colors.grey[600],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _chatService.cancelSending(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ),

          // Continuous Long-Speech status banner
          if (isRecordingActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B1E2B) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Mendengarkan...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatDuration(_speechDurationSeconds),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Bicara bebas & selama yang diinginkan tanpa terputus',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _stopListening,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _sendMessage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kirim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Quick suggestion chips
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: isSending ? null : () => _sendMessage(suggestion),
                );
              },
            ),
          ),

          // Input field row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Microphone / Continuous Voice input button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final scale = isRecordingActive ? _pulseAnimation.value : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isRecordingActive
                                ? Colors.redAccent
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isRecordingActive ? Icons.mic : Icons.mic_none,
                              color: isRecordingActive ? Colors.white : AppTheme.secondary,
                              size: 22,
                            ),
                            tooltip: isRecordingActive ? 'Berhenti merekam suara' : 'Ketik dengan suara (Speech-to-Text)',
                            onPressed: isSending ? null : _toggleListening,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Text input (Multiline: expands downward vertically instead of scrolling sideways)
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !isSending,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: isSending
                            ? 'Mohon tunggu, Assistant sedang merespon...'
                            : (isRecordingActive
                                ? 'Bicara sekarang (rekam panjang)...'
                                : 'Tanyakan sesuatu pada Assistant...'),
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isSending
                              ? const Color(0xFF64748B)
                              : (isRecordingActive ? Colors.redAccent : const Color(0xFF94A3B8)),
                        ),
                        filled: true,
                        fillColor: isSending
                            ? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFE2E8F0))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSending
                          ? AppTheme.secondary.withValues(alpha: 0.5)
                          : AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Colors.white),
                            tooltip: 'Kirim pesan',
                            onPressed: () => _sendMessage(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

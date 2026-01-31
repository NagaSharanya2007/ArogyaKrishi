import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chatbot_service.dart';
import '../models/chat_message.dart';
import '../utils/constants.dart';

/// Chat screen with text and voice support
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  String _currentLanguage = 'en';
  String? _recordingPath;

  final Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'te': 'తెలుగు',
  };

  final Map<String, String> _speechLocales = {
    'en': 'en_US',
    'hi': 'hi_IN',
    'te': 'te_IN',
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadLanguage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    await _speechToText.initialize();
    await _flutterTts.setLanguage(_speechLocales[_currentLanguage] ?? 'en_US');
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(AppConstants.prefLanguageCode) ?? 'en';
    setState(() {
      _currentLanguage = lang;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _chatbotService.sendTextMessage(
        message: text,
        language: _currentLanguage,
      );

      setState(() {
        _messages = _chatbotService.messageHistory;
      });

      _scrollToBottom();

      // Auto-play TTS for response
      await _speakText(response.reply);
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
      });
    } else {
      _showError('Microphone permission denied');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;

    await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isLoading = true;
    });

    try {
      if (_recordingPath != null) {
        final audioFile = File(_recordingPath!);

        final response = await _chatbotService.sendVoiceMessage(
          audioFile: audioFile,
          language: _currentLanguage,
        );

        setState(() {
          _messages = _chatbotService.messageHistory;
        });

        _scrollToBottom();

        // Auto-play TTS for response
        await _speakText(response.reply);
      }
    } catch (e) {
      _showError('Failed to send voice message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.setLanguage(
        _speechLocales[_currentLanguage] ?? 'en_US',
      );
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  Future<void> _playAudioUrl(String url) async {
    try {
      setState(() {
        _isPlayingAudio = true;
      });
      await _audioPlayer.play(UrlSource(url));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      _showError('Failed to play audio: $e');
    } finally {
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _chatbotService.clearSession();
              setState(() {
                _messages = [];
              });
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languageNames.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(AppConstants.prefLanguageCode, value);
                  setState(() {
                    _currentLanguage = value;
                  });
                  await _flutterTts.setLanguage(
                    _speechLocales[value] ?? 'en_US',
                  );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agricultural Assistant'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _changeLanguage,
            tooltip: 'Change Language',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about farming!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Voice button
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecordingAndSend(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _isRecording
                          ? 'Recording...'
                          : 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    enabled: !_isRecording,
                    onSubmitted: (_) => _sendTextMessage(),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.green,
                  onPressed: _isLoading || _isRecording
                      ? null
                      : _sendTextMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.green,
              child: const Icon(Icons.agriculture, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.green[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  if (!isUser && message.audioUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        icon: Icon(
                          _isPlayingAudio
                              ? Icons.volume_up
                              : Icons.volume_up_outlined,
                          color: Colors.green,
                        ),
                        onPressed: () => _playAudioUrl(message.audioUrl!),
                        tooltip: 'Play audio',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

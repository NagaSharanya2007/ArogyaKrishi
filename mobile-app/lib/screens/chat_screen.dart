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
import '../theme/app_theme.dart';

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
        title: Row(
          children: [
            const Icon(Icons.smart_toy, size: 24),
            const SizedBox(width: AppTheme.paddingS),
            const Text('AI Assistant'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        elevation: 0,
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingXL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.paddingXL),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.accentGreen,
                                  AppTheme.primaryLightGreen,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              size: 64,
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.paddingXL),
                          Text(
                            'Hi! I\'m your AI Farming Assistant',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.charcoal,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.paddingM),
                          Text(
                            'Ask me anything about crops, diseases, remedies, or farming practices!',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.mediumGrey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.paddingXL),
                          Wrap(
                            spacing: AppTheme.paddingS,
                            runSpacing: AppTheme.paddingS,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildSuggestionChip('How to treat leaf spots?'),
                              _buildSuggestionChip('Best fertilizers for rice'),
                              _buildSuggestionChip('Pest control tips'),
                            ],
                          ),
                        ],
                      ),
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
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Row(
              children: [
                // Voice button with proper handlers
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (!_isRecording) {
                        await _startRecording();
                        // Show snackbar with instruction
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Recording... Tap again to send',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppTheme.dangerRed,
                          ),
                        );
                      } else {
                        await _stopRecordingAndSend();
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isRecording
                            ? const LinearGradient(
                                colors: [AppTheme.dangerRed, Colors.redAccent],
                              )
                            : const LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  AppTheme.primaryLightGreen,
                                ],
                              ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? AppTheme.dangerRed
                                        : AppTheme.primaryGreen)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppTheme.paddingM),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingM),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _isRecording
                          ? 'Recording... Tap mic to stop'
                          : 'Ask me anything...',
                      hintStyle: TextStyle(color: AppTheme.mediumGrey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingL,
                        vertical: AppTheme.paddingM,
                      ),
                    ),
                    enabled: !_isRecording,
                    onSubmitted: (_) => _sendTextMessage(),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingS),

                // Send button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryLightGreen,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: AppTheme.white,
                    onPressed: _isLoading || _isRecording
                        ? null
                        : _sendTextMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendTextMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingL,
          vertical: AppTheme.paddingM,
        ),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
            color: AppTheme.accentGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGreen, AppTheme.primaryLightGreen],
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(AppTheme.paddingS),
              child: const Icon(
                Icons.smart_toy,
                color: AppTheme.white,
                size: 20,
              ),
            ),
          const SizedBox(width: AppTheme.paddingS),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryLightGreen,
                        ],
                      )
                    : null,
                color: isUser ? null : AppTheme.lightGrey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusL),
                  topRight: Radius.circular(AppTheme.radiusL),
                  bottomLeft: isUser
                      ? Radius.circular(AppTheme.radiusL)
                      : Radius.circular(AppTheme.radiusS),
                  bottomRight: isUser
                      ? Radius.circular(AppTheme.radiusS)
                      : Radius.circular(AppTheme.radiusL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? AppTheme.white : AppTheme.charcoal,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser && message.audioUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.paddingS),
                      child: IconButton(
                        icon: Icon(
                          _isPlayingAudio
                              ? Icons.volume_up
                              : Icons.volume_up_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                        onPressed: () => _playAudioUrl(message.audioUrl!),
                        tooltip: 'Play audio',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.paddingS),
          if (isUser)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryLightGreen],
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(AppTheme.paddingS),
              child: const Icon(Icons.person, color: AppTheme.white, size: 20),
            ),
        ],
      ),
    );
  }
}

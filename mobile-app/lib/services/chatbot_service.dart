import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_request.dart';
import '../models/chat_response.dart';
import '../models/chat_message.dart';
import '../utils/constants.dart';

/// Exception for chatbot API errors
class ChatApiException implements Exception {
  final String message;
  final int statusCode;

  ChatApiException(this.message, this.statusCode);

  @override
  String toString() => 'ChatApiException: $message (Status: $statusCode)';
}

/// Service for chatbot text and voice interactions
class ChatbotService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  String? _sessionId;
  final List<ChatMessage> _messageHistory = [];

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Get message history
  List<ChatMessage> get messageHistory => List.unmodifiable(_messageHistory);

  /// Clear session and message history
  void clearSession() {
    _sessionId = null;
    _messageHistory.clear();
  }

  /// Send text message to chatbot
  ///
  /// Parameters:
  /// - [message]: User's text message
  /// - [language]: Language code (en, hi, te)
  ///
  /// Returns: ChatResponse with bot reply and optional audio URL
  Future<ChatResponse> sendTextMessage({
    required String message,
    required String language,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat/text');

      final request = ChatTextRequest(
        message: message,
        language: language,
        sessionId: _sessionId,
      );

      print('🤖 Chat Text Request: POST ${uri.toString()}');
      print('📝 Message: $message');
      print('🌐 Language: $language');
      print('🔑 Session: $_sessionId');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final chatResponse = ChatResponse.fromJson(jsonData);

        // Update session ID
        _sessionId = chatResponse.sessionId;

        // Add messages to history
        _addToHistory(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: message,
            isUser: true,
            timestamp: DateTime.now(),
            language: language,
          ),
        );

        _addToHistory(
          ChatMessage(
            id: chatResponse.messageId,
            content: chatResponse.reply,
            isUser: false,
            timestamp: DateTime.now(),
            audioUrl: chatResponse.audioUrl,
            language: chatResponse.language,
          ),
        );

        return chatResponse;
      } else {
        throw ChatApiException(
          'Failed to send message: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Chat API Error: $e');
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Network error: $e', 0);
    }
  }

  /// Send voice message to chatbot
  ///
  /// Parameters:
  /// - [audioFile]: Audio file containing user's voice
  /// - [language]: Language code (en, hi, te)
  ///
  /// Returns: ChatResponse with bot reply and optional audio URL
  Future<ChatResponse> sendVoiceMessage({
    required File audioFile,
    required String language,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat/voice');

      print('🤖 Chat Voice Request: POST ${uri.toString()}');
      print('🎤 Audio path: ${audioFile.path}');
      print('🌐 Language: $language');
      print('🔑 Session: $_sessionId');

      var request = http.MultipartRequest('POST', uri);

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: http.MediaType('audio', 'wav'),
        ),
      );

      // Add form fields
      request.fields['language'] = language;
      if (_sessionId != null) {
        request.fields['session_id'] = _sessionId!;
      }

      print('📤 Sending voice request...');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final chatResponse = ChatResponse.fromJson(jsonData);

        // Update session ID
        _sessionId = chatResponse.sessionId;

        // Add voice message placeholder to history
        _addToHistory(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '[Voice message]',
            isUser: true,
            timestamp: DateTime.now(),
            language: language,
          ),
        );

        _addToHistory(
          ChatMessage(
            id: chatResponse.messageId,
            content: chatResponse.reply,
            isUser: false,
            timestamp: DateTime.now(),
            audioUrl: chatResponse.audioUrl,
            language: chatResponse.language,
          ),
        );

        return chatResponse;
      } else {
        throw ChatApiException(
          'Failed to send voice message: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Voice Chat API Error: $e');
      if (e is ChatApiException) rethrow;
      throw ChatApiException('Network error: $e', 0);
    }
  }

  /// Add message to history with size limit
  void _addToHistory(ChatMessage message) {
    _messageHistory.add(message);

    // Keep only last 100 messages to prevent memory issues
    if (_messageHistory.length > 100) {
      _messageHistory.removeAt(0);
    }
  }
}

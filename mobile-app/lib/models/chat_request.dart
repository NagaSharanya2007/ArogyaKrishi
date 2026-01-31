/// Request model for text chat
class ChatTextRequest {
  final String message;
  final String language;
  final String? sessionId;

  ChatTextRequest({
    required this.message,
    required this.language,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'language': language,
      if (sessionId != null) 'session_id': sessionId,
    };
  }
}

/// Request model for voice chat
class ChatVoiceRequest {
  final String audioBase64;
  final String language;
  final String? sessionId;

  ChatVoiceRequest({
    required this.audioBase64,
    required this.language,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'audio': audioBase64,
      'language': language,
      if (sessionId != null) 'session_id': sessionId,
    };
  }
}

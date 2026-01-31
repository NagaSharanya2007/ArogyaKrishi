/// Response model for chat API
class ChatResponse {
  final String reply;
  final String? audioUrl;
  final String sessionId;
  final String language;
  final String messageId;

  ChatResponse({
    required this.reply,
    this.audioUrl,
    required this.sessionId,
    required this.language,
    required this.messageId,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] as String,
      audioUrl: json['audio_url'] as String?,
      sessionId: json['session_id'] as String,
      language: json['language'] as String? ?? 'en',
      messageId: json['message_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'audio_url': audioUrl,
      'session_id': sessionId,
      'language': language,
      'message_id': messageId,
    };
  }
}

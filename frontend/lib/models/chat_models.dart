import 'package:flutter/foundation.dart';

// Model untuk menampung seluruh riwayat chat dari API
class ChatHistory {
  final String? userId; // Bisa jadi null jika API tidak mengirimkannya
  final List<MessageModel> messages;

  ChatHistory({
    this.userId,
    required this.messages,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    // Mengekstrak list 'messages' dari JSON
    var messageList = json['messages'] as List? ?? [];

    // Mengubah setiap item di list JSON menjadi objek MessageModel
    List<MessageModel> messages = messageList
        .map((messageJson) => MessageModel.fromJson(messageJson))
        .toList();

    return ChatHistory(
      userId: json[
          'user_id'], // Sesuaikan jika API mengirimkan user_id di level ini
      messages: messages,
    );
  }
}

// Model untuk satu pesan tunggal
class MessageModel {
  final String content;
  final bool isUser;
  final String timestamp;
  final List<dynamic> attachments; // Walaupun kosong, tetap kita definisikan

  MessageModel({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.attachments =
        const [], // PERBAIKAN: Dibuat opsional dengan nilai default
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      content: json['content'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      attachments: List<dynamic>.from(json['attachments'] ?? []),
    );
  }
}

// Model untuk respons dari API saat mengirim pesan
class ChatResponse {
  final String response;
  final String userId;
  final List<String> suggestions; // PERBAIKAN: Menambahkan field suggestions

  ChatResponse({
    required this.response,
    required this.userId,
    this.suggestions = const [], // PERBAIKAN: Menambahkan ke constructor
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] ?? 'No response from server.',
      userId: json['user_id'] ?? '',
      // PERBAIKAN: Mem-parsing suggestions dari JSON
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

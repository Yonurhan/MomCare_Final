import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Ganti dengan path proyek Anda
import 'package:pregnancy_app/services/api_service.dart';
import 'package:pregnancy_app/models/chat_models.dart';
import 'package:pregnancy_app/theme/app_theme.dart';
import 'package:pregnancy_app/services/auth_service.dart';
import 'chat_history_screen.dart'; // Impor halaman riwayat baru

class ChatScreen extends StatefulWidget {
  final String userId;
  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  final List<MessageModel> _messages = [];
  List<String> _suggestions = [];

  bool _isSending = false;
  // _isHistoryLoading sekarang tidak lagi relevan, tapi kita set false saja.
  bool _isHistoryLoading = false;
  late AnimationController _typingAnimController;

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadInitialChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  // --- FUNGSI INI TELAH DIMODIFIKASI ---
  Future<void> _loadInitialChat() async {
    // Langsung tampilkan pesan sapaan awal tanpa memuat riwayat dari API.
    if (mounted) {
      setState(() {
        _isHistoryLoading = false;

        // Karena _messages selalu kosong di awal, blok ini akan selalu dijalankan.
        if (_messages.isEmpty) {
          final username = Provider.of<AuthService>(context, listen: false)
                  .currentUser
                  ?.username ??
              'Pengguna';
          _messages.add(MessageModel(
            content:
                'Halo $username! Saya GITA, asisten virtual Anda. Apa yang ingin Anda ketahui?',
            isUser: false,
            timestamp: DateTime.now().toIso8601String(),
          ));
          _suggestions = [
            'Apa itu stunting?',
            'Makanan untuk trimester pertama',
            'Tanda-tanda bahaya kehamilan'
          ];
        }
      });
      _scrollToBottom(milliseconds: 400);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isSending = true;
      _messages.add(MessageModel(
        content: text,
        isUser: true,
        timestamp: DateTime.now().toIso8601String(),
      ));
      _suggestions = [];
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _apiService.sendChatMessage(
          message: text, userId: widget.userId);
      if (mounted) {
        setState(() {
          _messages.add(MessageModel(
            content: response.response,
            isUser: false,
            timestamp: DateTime.now().toIso8601String(),
          ));
          _suggestions = response.suggestions;
        });
      }
    } catch (e) {
      if (mounted) {
        _messages.add(MessageModel(
          content: 'Maaf, terjadi kesalahan koneksi. Silakan coba lagi.',
          isUser: false,
          timestamp: DateTime.now().toIso8601String(),
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom({int milliseconds = 300}) {
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten GITA'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lihat Riwayat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatHistoryScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isHistoryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isSending && index == _messages.length) {
                          return _buildLoadingBubble();
                        }
                        final message = _messages[index];
                        final showSuggestions = !_isSending &&
                            index == _messages.length - 1 &&
                            _suggestions.isNotEmpty;
                        return _buildMessageBubble(message, showSuggestions);
                      },
                    ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool showSuggestions) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userInitial = authService.currentUser?.username.isNotEmpty == true
        ? authService.currentUser!.username[0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isUser)
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.health_and_safety,
                      color: Colors.white, size: 22),
                ),
              Flexible(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                      message.isUser ? 45 : 10, 4, message.isUser ? 10 : 45, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        message.isUser ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _FormattedMessageContent(
                    text: message.content,
                    isUser: message.isUser,
                    timestamp: message.timestamp,
                  ),
                ),
              ),
              if (message.isUser)
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: Text(userInitial,
                      style: const TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (showSuggestions) _buildSuggestionsChipList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsChipList() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 50, right: 16, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((suggestion) {
          return InkWell(
            onTap: () => _sendMessage(suggestion),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(suggestion,
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.health_and_safety, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: (_typingAnimController.value * 2 - index * 0.5)
                            .clamp(0.2, 1.0),
                        child: const CircleAvatar(
                            radius: 4, backgroundColor: AppTheme.primaryColor),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
        BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 5,
            color: Colors.black.withOpacity(0.05))
      ]),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan Anda...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: _isSending ? null : (val) => _sendMessage(val),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: AppTheme.primaryColor,
              onPressed: _isSending
                  ? null
                  : () => _sendMessage(_messageController.text),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget khusus untuk mem-parsing dan menampilkan konten pesan yang diformat
class _FormattedMessageContent extends StatelessWidget {
  final String text;
  final bool isUser;
  final String timestamp;

  const _FormattedMessageContent({
    Key? key,
    required this.text,
    required this.isUser,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isUser ? Colors.white : Colors.black87;
    final boldTextColor = isUser ? Colors.white : AppTheme.primaryColor;
    final timeColor = isUser ? Colors.white70 : Colors.grey.shade600;

    final boldStyle = TextStyle(
        fontWeight: FontWeight.bold, color: boldTextColor, fontSize: 16);
    final regularStyle = TextStyle(color: textColor, fontSize: 16, height: 1.4);

    List<Widget> contentWidgets = [];
    final paragraphs = text.split(RegExp(r'\n\n+'));

    for (var paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      // Cek untuk judul utama
      if (paragraph.contains('Selamat!') ||
          paragraph.contains('Berikut adalah')) {
        contentWidgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            paragraph.replaceAll('**', '').trim(),
            style: regularStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ));
        continue;
      }

      // Cek untuk sub-judul
      if (paragraph.contains('Nutrisi Penting') ||
          paragraph.contains('Rekomendasi Makanan') ||
          paragraph.contains('Tips Tambahan') ||
          paragraph.contains('Contoh Menu Harian') ||
          paragraph.contains('Penting untuk diingat')) {
        contentWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(
            paragraph.replaceAll('**', '').trim(),
            style: boldStyle,
          ),
        ));
        continue;
      }

      // Cek untuk daftar berpoin
      if (paragraph.trim().startsWith('*')) {
        final items = paragraph.trim().split(RegExp(r'\n\s*\*\s*'));
        for (var item in items) {
          contentWidgets.add(_buildListItem(
              item.replaceAll('*', '').trim(), regularStyle, boldStyle));
        }
      } else {
        // Paragraf biasa
        contentWidgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: RichText(
              text: _buildTextSpan(paragraph, regularStyle, boldStyle)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...contentWidgets,
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.bottomRight,
          child: Text(
            DateFormat('HH:mm').format(DateTime.parse(timestamp)),
            style: TextStyle(color: timeColor, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(
      String text, TextStyle regularStyle, TextStyle boldStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 16, color: AppTheme.primaryColor)),
          Expanded(
              child: RichText(
                  text: _buildTextSpan(text, regularStyle, boldStyle))),
        ],
      ),
    );
  }

  TextSpan _buildTextSpan(
      String text, TextStyle regularStyle, TextStyle boldStyle) {
    final List<TextSpan> children = [];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      children.add(TextSpan(
        text: parts[i],
        style: i.isEven ? regularStyle : boldStyle,
      ));
    }
    return TextSpan(children: children);
  }
}

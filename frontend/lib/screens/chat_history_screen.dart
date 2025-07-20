import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pregnancy_app/models/chat_models.dart';
import 'package:pregnancy_app/services/api_service.dart';
import 'package:pregnancy_app/theme/app_theme.dart';

class ChatHistoryScreen extends StatefulWidget {
  final String userId;
  const ChatHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ApiService _apiService = ApiService();
  // Future sekarang bisa di-update
  late Future<ChatHistory> _historyFuture;

  @override
  void initState() {
    super.initState();
    // Panggil method untuk memuat data untuk pertama kali
    _refreshHistory();
    // Tambahkan print untuk memastikan userId yang diterima benar
    print('ChatHistoryScreen initialized with userId: ${widget.userId}');
  }

  // Method terpusat untuk memuat atau me-refresh data
  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _apiService.getChatHistory(widget.userId);
    });
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Hari Ini';
    } else if (dateToCompare == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    }
  }

  List<Widget> _buildGroupedHistory(List<MessageModel> messages) {
    if (messages.isEmpty) {
      // Widget ini akan ditampilkan jika list pesan benar-benar kosong
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Riwayat Kosong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarik ke bawah untuk memuat ulang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        )
      ];
    }

    List<Widget> groupedItems = [];
    DateTime? lastDate;

    for (var message in messages) {
      final messageDate = DateTime.parse(message.timestamp);
      if (lastDate == null ||
          messageDate.day != lastDate!.day ||
          messageDate.month != lastDate!.month ||
          messageDate.year != lastDate!.year) {
        lastDate = messageDate;
        groupedItems.add(_DateHeader(text: _formatDateHeader(lastDate!)));
      }
      groupedItems.add(_HistoryMessageBubble(message: message));
    }
    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Percakapan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Tombol refresh manual
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistory,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: FutureBuilder<ChatHistory>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat: ${snapshot.error}'));
          }

          // Kita tidak perlu lagi cek !snapshot.hasData karena FutureBuilder menanganinya
          // Cukup cek jika data messages di dalamnya kosong.
          final messages = snapshot.data?.messages ?? [];

          // --- PERBAIKAN UTAMA: MENGGUNAKAN RefreshIndicator ---
          return RefreshIndicator(
            onRefresh: _refreshHistory,
            color: AppTheme.primaryColor,
            child: ListView(
              // Physics ditambahkan agar bisa scroll bahkan saat item sedikit
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: _buildGroupedHistory(messages),
            ),
          );
        },
      ),
    );
  }
}

// Widget untuk header tanggal (Dibuat lebih menarik)
class _DateHeader extends StatelessWidget {
  final String text;
  const _DateHeader({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Widget untuk gelembung chat di halaman riwayat (Dibuat lebih menarik)
class _HistoryMessageBubble extends StatelessWidget {
  final MessageModel message;
  const _HistoryMessageBubble({Key? key, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: message.isUser ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(DateTime.parse(message.timestamp)),
                style: TextStyle(
                    color:
                        message.isUser ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_app/models/chat_models.dart';
import 'package:pregnancy_app/services/api_service.dart';
import 'package:pregnancy_app/services/auth_service.dart';
import 'package:pregnancy_app/theme/app_theme.dart';

class ChatHistoryScreen extends StatefulWidget {
  final String userId;
  const ChatHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<ChatHistory> _historyFuture;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      if (!_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = true;
        });
      }
    } else {
      if (_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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

  List<dynamic> _buildGroupedHistory(List<MessageModel> messages) {
    List<dynamic> groupedItems = [];
    DateTime? lastDate;

    for (var message in messages) {
      final messageDate = DateTime.parse(message.timestamp);
      if (lastDate == null ||
          messageDate.day != lastDate!.day ||
          messageDate.month != lastDate!.month ||
          messageDate.year != lastDate!.year) {
        lastDate = messageDate;
        groupedItems.add(_formatDateHeader(lastDate!));
      }
      groupedItems.add(message);
    }
    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Percakapan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.primaryTextColor),
            onPressed: _refreshHistory,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: FutureBuilder<ChatHistory>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor));
            }
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }

            final messages = snapshot.data?.messages ?? [];
            if (messages.isEmpty) {
              return _buildEmptyStateWidget();
            }

            final groupedItems = _buildGroupedHistory(messages);

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshHistory,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final item = groupedItems[index];
                      Widget child;
                      if (item is String) {
                        child = _DateHeader(text: item);
                      } else {
                        child = _HistoryMessageBubble(
                            message: item as MessageModel);
                      }
                      // Animasi masuk untuk setiap item
                      return _AnimatedListItem(index: index, child: child);
                    },
                  ),
                ),
                // Tombol Scroll to Bottom
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _showScrollToBottomButton ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/empty_history.png',
                height: 150,
                errorBuilder: (c, e, s) => Icon(Icons.forum_outlined,
                    size: 80, color: Colors.grey.shade300)),
            const SizedBox(height: 24),
            Text('Belum Ada Riwayat',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor)),
            const SizedBox(height: 8),
            Text(
              'Mulai percakapan baru dengan asisten GITA untuk melihat riwayat Anda di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi'),
              onPressed: _refreshHistory,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    final displayError = error.replaceFirst('Exception: ', '');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/error.png',
                height: 150,
                errorBuilder: (c, e, s) => Icon(Icons.error_outline_rounded,
                    size: 80, color: Colors.red.shade300)),
            const SizedBox(height: 24),
            Text('Gagal Memuat',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(
              displayError,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi'),
              onPressed: _refreshHistory,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedListItem({Key? key, required this.index, required this.child})
      : super(key: key);

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String text;
  const _DateHeader({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: AppTheme.primaryTextColor.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HistoryMessageBubble extends StatelessWidget {
  final MessageModel message;
  const _HistoryMessageBubble({Key? key, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userInitial = authService.currentUser?.username.isNotEmpty == true
        ? authService.currentUser!.username[0].toUpperCase()
        : 'U';

    bool isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child:
                  Icon(Icons.health_and_safety, color: Colors.white, size: 22),
            ),
          Flexible(
            child: Container(
              margin:
                  EdgeInsets.fromLTRB(isUser ? 50 : 10, 4, isUser ? 10 : 50, 4),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: _FormattedHistoryText(
                    text: message.content,
                    isUser: isUser,
                    timestamp: message.timestamp,
                  ),
                ),
              ),
            ),
          ),
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(userInitial,
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _FormattedHistoryText extends StatelessWidget {
  final String text;
  final bool isUser;
  final String timestamp;

  const _FormattedHistoryText({
    Key? key,
    required this.text,
    required this.isUser,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isUser ? Colors.white : Colors.black87;
    final timeColor = isUser ? Colors.white70 : Colors.grey.shade600;

    final lines = text.split('\n');

    List<Widget> contentWidgets = [];
    for (String line in lines) {
      if (line.trim().isEmpty) continue;

      // Cek untuk sub-judul (teks tebal diakhiri dengan ':')
      if (line.trim().startsWith('**') && line.trim().endsWith(':**')) {
        contentWidgets.add(_buildSubheader(line, textColor));
      } else if (line.trim().startsWith('*')) {
        contentWidgets.add(_buildListItem(line, textColor));
      } else {
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              line.replaceAll('**', ''),
              style: GoogleFonts.poppins(
                  color: textColor, fontSize: 15.5, height: 1.5),
            ),
          ),
        );
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
            style: GoogleFonts.poppins(color: timeColor, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubheader(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        text.replaceAll('**', ''),
        style: GoogleFonts.poppins(
          color: isUser ? Colors.white : AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildListItem(String text, Color textColor) {
    final itemText = text.replaceFirst(RegExp(r'\*\s*'), '');
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child:
                Icon(Icons.circle, size: 6, color: textColor.withOpacity(0.8)),
          ),
          Expanded(
            child: Text(
              itemText.replaceAll('**', ''),
              style: GoogleFonts.poppins(
                  color: textColor, fontSize: 15.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatThreadScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchMessages(widget.chatId));
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(widget.chatId, _messageController.text.trim());
    _messageController.clear();
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(chatState),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    if (state.status == ChatStatus.loading && state.currentMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.currentMessages.isEmpty) {
      return const Center(child: Text('No messages yet. Send a message to start!'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.currentMessages.length,
      itemBuilder: (context, index) {
        final msg = state.currentMessages[index];
        // TODO: Get current user ID from AuthProvider to distinguish sender
        final isMe = true; // Placeholder

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryBlue : Colors.grey[200],
              borderRadius: BorderRadius.circular(12).copyWith(
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
              ),
            ),
            child: Text(
              msg['message'],
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.send, color: AppTheme.primaryBlue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchMyChats());
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(chatProvider.notifier).fetchMyChats(),
        child: _buildBody(chatState),
      ),
    );
  }

  Widget _buildBody(ChatState state) {
    if (state.status == ChatStatus.loading && state.myChats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ChatStatus.error) {
      return Center(child: Text(state.errorMessage ?? 'Error loading chats'));
    }

    if (state.myChats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.messageSquare, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('No active chats yet.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.myChats.length,
      itemBuilder: (context, index) {
        final chat = state.myChats[index];
        final load = chat['loads'];
        final otherParty = chat['trucker_profiles'] ?? load['supplier_profiles'];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: const Icon(LucideIcons.user, color: AppTheme.primaryBlue),
          ),
          title: Text(
            "${load['pickup_location']['city']} → ${load['drop_location']['city']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "With ${otherParty['company_name'] ?? otherParty['full_name'] ?? otherParty['owner_name']}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 16),
          onTap: () {
            GoRouter.of(context).push('/chat-thread/${chat['id']}');
          },
        );
      },
    );
  }
}

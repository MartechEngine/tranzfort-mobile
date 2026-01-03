import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/api_client.dart';

enum ChatStatus { initial, loading, success, error }

class ChatState {
  final ChatStatus status;
  final List<dynamic> myChats;
  final List<dynamic> currentMessages;
  final String? errorMessage;

  ChatState({
    this.status = ChatStatus.initial,
    this.myChats = const [],
    this.currentMessages = const [],
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<dynamic>? myChats,
    List<dynamic>? currentMessages,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      myChats: myChats ?? this.myChats,
      currentMessages: currentMessages ?? this.currentMessages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  RealtimeChannel? _messageSubscription;

  ChatNotifier() : super(ChatState());

  Future<void> fetchMyChats() async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final response = await apiClient.dio.get('/chats/my');
      state = state.copyWith(status: ChatStatus.success, myChats: response.data);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> fetchMessages(String chatId) async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final response = await apiClient.dio.get('/chats/$chatId/messages');
      state = state.copyWith(status: ChatStatus.success, currentMessages: response.data);
      
      // Setup Realtime listener
      _setupRealtimeListener(chatId);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
    }
  }

  void _setupRealtimeListener(String chatId) {
    _messageSubscription?.unsubscribe();
    
    _messageSubscription = Supabase.instance.client
        .channel('public:chat_messages:chat_id=eq.$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            state = state.copyWith(
              currentMessages: [...state.currentMessages, newMessage],
            );
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String chatId, String message) async {
    try {
      await apiClient.dio.post('/chats/message', data: {
        'chat_id': chatId,
        'message': message,
      });
      // No need to fetchMessages again, Realtime listener will catch the insert
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
    }
  }

  Future<String?> initiateChat(String loadId) async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final response = await apiClient.dio.post('/chats/initiate', data: {
        'load_id': loadId,
      });
      state = state.copyWith(status: ChatStatus.success);
      return response.data['id'];
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.unsubscribe();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

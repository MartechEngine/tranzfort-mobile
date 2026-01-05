import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _messageSubscription;

  ChatNotifier() : super(ChatState());

  Future<void> fetchMyChats() async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Determine if user is supplier or trucker to filter chats
      final userResponse = await _supabase
          .from('users')
          .select('role, supplier_profiles(id), trucker_profiles(id)')
          .eq('id', userId)
          .single();

      final role = userResponse['role'];
      var query = _supabase.from('chats').select('*, loads(*, supplier_profiles(*)), trucker_profiles(*)');

      if (role == 'SUPPLIER') {
        final supplierId = (userResponse['supplier_profiles'] as List).first['id'];
        query = query.eq('loads.supplier_id', supplierId);
      } else {
        final truckerId = (userResponse['trucker_profiles'] as List).first['id'];
        query = query.eq('trucker_id', truckerId);
      }

      final data = await query.order('created_at', {ascending: false});
      state = state.copyWith(status: ChatStatus.success, myChats: data as List);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> fetchMessages(String chatId) async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final data = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', {ascending: true});

      state = state.copyWith(status: ChatStatus.success, currentMessages: data as List);
      
      _setupRealtimeListener(chatId);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
    }
  }

  void _setupRealtimeListener(String chatId) {
    _messageSubscription?.unsubscribe();
    
    _messageSubscription = _supabase
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      await _supabase.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'message': message,
      });
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, errorMessage: e.toString());
    }
  }

  Future<String?> initiateChat(String loadId) async {
    state = state.copyWith(status: ChatStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // 1. Get trucker profile
      final truckerProfile = await _supabase
          .from('trucker_profiles')
          .select('id, verification_status')
          .eq('user_id', userId)
          .single();

      if (truckerProfile['verification_status'] != 'VERIFIED') {
        throw Exception('Only verified truckers can initiate chat');
      }

      // 2. Check for existing chat
      final existingChat = await _supabase
          .from('chats')
          .select('id')
          .eq('load_id', loadId)
          .eq('trucker_id', truckerProfile['id'])
          .maybeSingle();

      if (existingChat != null) {
        state = state.copyWith(status: ChatStatus.success);
        return existingChat['id'];
      }

      // 3. Create new chat
      final newChat = await _supabase.from('chats').insert({
        'load_id': loadId,
        'trucker_id': truckerProfile['id'],
        'status': 'ACTIVE'
      }).select().single();

      state = state.copyWith(status: ChatStatus.success);
      return newChat['id'];
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

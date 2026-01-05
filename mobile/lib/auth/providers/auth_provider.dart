import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? token;
  final String? errorMessage;
  final User? user;

  AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.token,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? token,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _supabase = Supabase.instance.client;

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: session.accessToken,
        user: session.user,
      );
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _supabase.auth.signInWithOtp(
        phone: '+91$phoneNumber',
      );
      state = state.copyWith(status: AuthStatus.unauthenticated, phoneNumber: phoneNumber);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: '+91${state.phoneNumber}',
        token: otp,
        type: OtpType.sms,
      );
      
      if (response.session != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated, 
          token: response.session!.accessToken,
          user: response.user,
        );
      } else {
        throw Exception('Verification failed - no session');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> updateProfile(String role, Map<String, dynamic> profileData) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // 1. Update user role in public.users
      await _supabase.from('users').update({
        'role': role,
      }).eq('id', userId);

      // 2. Update profile table
      final profileTable = role == 'SUPPLIER' ? 'supplier_profiles' : 'trucker_profiles';
      await _supabase.from(profileTable).upsert({
        'user_id': userId,
        ...profileData,
      });

      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  void logout() async {
    await _supabase.auth.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? token;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await apiClient.dio.post('/auth/otp/send', data: {'phone': phoneNumber});
      state = state.copyWith(status: AuthStatus.unauthenticated, phoneNumber: phoneNumber);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await apiClient.dio.post('/auth/otp/verify', data: {
        'phone': state.phoneNumber,
        'otp': otp,
      });
      
      final token = response.data['session']['access_token'];
      await _storage.write(key: 'auth_token', value: token);
      
      state = state.copyWith(status: AuthStatus.authenticated, token: token);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> updateProfile(String role, Map<String, dynamic> profileData) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await apiClient.dio.patch('/users/me', data: {
        'role': role,
        'profileData': profileData,
      });
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  void logout() async {
    await _storage.delete(key: 'auth_token');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

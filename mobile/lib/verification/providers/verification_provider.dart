import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum VerificationStatus { unverified, pending, verified, rejected, loading, error }
enum PaymentStatus { unpaid, created, paid, loading, error }

class VerificationState {
  final VerificationStatus status;
  final String? documentUrl;
  final PaymentStatus paymentStatus;
  final String? paymentId;
  final num? feeAmount;
  final String? feeCurrency;
  final String? errorMessage;

  VerificationState({
    this.status = VerificationStatus.unverified,
    this.documentUrl,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentId,
    this.feeAmount,
    this.feeCurrency,
    this.errorMessage,
  });

  VerificationState copyWith({
    VerificationStatus? status,
    String? documentUrl,
    PaymentStatus? paymentStatus,
    String? paymentId,
    num? feeAmount,
    String? feeCurrency,
    String? errorMessage,
  }) {
    return VerificationState(
      status: status ?? this.status,
      documentUrl: documentUrl ?? this.documentUrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      feeAmount: feeAmount ?? this.feeAmount,
      feeCurrency: feeCurrency ?? this.feeCurrency,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final _supabase = Supabase.instance.client;

  VerificationNotifier() : super(VerificationState());

  Future<void> fetchPaymentStatus() async {
    state = state.copyWith(paymentStatus: PaymentStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // For now, we simulate payment status using a local table or metadata
      // In a real serverless app, you'd use a 'payments' table in Supabase
      final {data, error} = await _supabase
          .from('subscriptions')
          .select('status, plan_type')
          .eq('user_id', userId)
          .maybeSingle();

      if (error != null && error.code != 'PGRST116') throw error;

      if (data != null && data['plan_type'] == 'PREMIUM') {
        state = state.copyWith(
          paymentStatus: PaymentStatus.paid,
          feeAmount: 199,
          feeCurrency: 'INR',
        );
      } else {
        state = state.copyWith(paymentStatus: PaymentStatus.unpaid);
      }
    } catch (e) {
      state = state.copyWith(paymentStatus: PaymentStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> payVerificationFee() async {
    state = state.copyWith(paymentStatus: PaymentStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Simulate successful payment by creating a premium subscription
      await _supabase.from('subscriptions').upsert({
        'user_id': userId,
        'plan_type': 'PREMIUM',
        'status': 'ACTIVE',
        'end_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      });

      state = state.copyWith(paymentStatus: PaymentStatus.paid);
    } catch (e) {
      state = state.copyWith(paymentStatus: PaymentStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> fetchStatus() async {
    state = state.copyWith(status: VerificationStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final {data, error} = await _supabase
          .from('verifications')
          .select('status, document_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (error != null && error.code != 'PGRST116') throw error;
      
      if (data == null) {
        state = state.copyWith(status: VerificationStatus.unverified);
        return;
      }

      VerificationStatus status;
      switch (data['status']) {
        case 'PENDING':
          status = VerificationStatus.pending;
          break;
        case 'APPROVED':
          status = VerificationStatus.verified;
          break;
        case 'REJECTED':
          status = VerificationStatus.rejected;
          break;
        default:
          status = VerificationStatus.unverified;
      }
      
      state = state.copyWith(
        status: status,
        documentUrl: data['document_url'],
      );
    } catch (e) {
      state = state.copyWith(status: VerificationStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> uploadAndSubmit(File file, String documentType) async {
    if (state.paymentStatus != PaymentStatus.paid) {
      state = state.copyWith(status: VerificationStatus.error, errorMessage: 'Verification fee not paid');
      return;
    }

    state = state.copyWith(status: VerificationStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // 1. Upload to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = 'verifications/$fileName';
      
      await _supabase.storage
          .from('documents')
          .upload(path, file);
      
      final documentUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(path);

      // 2. Submit via Supabase Table
      await _supabase.from('verifications').upsert({
        'user_id': userId,
        'document_type': documentType,
        'document_url': documentUrl,
        'status': 'PENDING',
      });

      // 3. Update profile status to PENDING
      final user = await _supabase.from('users').select('role').eq('id', userId).single();
      final table = user['role'] == 'SUPPLIER' ? 'supplier_profiles' : 'trucker_profiles';
      await _supabase.from(table).update({'verification_status': 'PENDING'}).eq('user_id', userId);

      state = state.copyWith(status: VerificationStatus.pending, documentUrl: documentUrl);
    } catch (e) {
      state = state.copyWith(status: VerificationStatus.error, errorMessage: e.toString());
    }
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});

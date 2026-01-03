import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/api_client.dart';

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
  VerificationNotifier() : super(VerificationState());

  Future<void> fetchPaymentStatus() async {
    state = state.copyWith(paymentStatus: PaymentStatus.loading);
    try {
      final response = await apiClient.dio.get('/payments/verification/status');
      final apiStatus = response.data['status'];

      PaymentStatus status;
      switch (apiStatus) {
        case 'PAID':
          status = PaymentStatus.paid;
          break;
        case 'CREATED':
          status = PaymentStatus.created;
          break;
        default:
          status = PaymentStatus.unpaid;
      }

      state = state.copyWith(
        paymentStatus: status,
        paymentId: response.data['paymentId'],
        feeAmount: response.data['amount'],
        feeCurrency: response.data['currency'],
      );
    } catch (e) {
      state = state.copyWith(paymentStatus: PaymentStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> payVerificationFee() async {
    state = state.copyWith(paymentStatus: PaymentStatus.loading);
    try {
      // Local/dev flow: create then immediately confirm.
      final created = await apiClient.dio.post('/payments/verification/create');
      final paymentId = created.data['paymentId'] as String;

      await apiClient.dio.post('/payments/verification/confirm', data: {
        'paymentId': paymentId,
      });

      await fetchPaymentStatus();
    } catch (e) {
      state = state.copyWith(paymentStatus: PaymentStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> fetchStatus() async {
    state = state.copyWith(status: VerificationStatus.loading);
    try {
      final response = await apiClient.dio.get('/verifications/status');
      final apiStatus = response.data['status'];
      
      VerificationStatus status;
      switch (apiStatus) {
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
        documentUrl: response.data['document_url'],
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
      // 1. Upload to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = 'verifications/$fileName';
      
      await Supabase.instance.client.storage
          .from('documents')
          .upload(path, file);
      
      final documentUrl = Supabase.instance.client.storage
          .from('documents')
          .getPublicUrl(path);

      // 2. Submit to Backend API
      await apiClient.dio.post('/verifications/submit', data: {
        'document_type': documentType,
        'document_url': documentUrl,
      });

      state = state.copyWith(status: VerificationStatus.pending, documentUrl: documentUrl);
    } catch (e) {
      state = state.copyWith(status: VerificationStatus.error, errorMessage: e.toString());
    }
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});

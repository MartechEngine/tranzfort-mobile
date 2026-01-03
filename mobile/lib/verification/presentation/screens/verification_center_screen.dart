import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/verification_provider.dart';

class VerificationCenterScreen extends ConsumerStatefulWidget {
  const VerificationCenterScreen({super.key});

  @override
  ConsumerState<VerificationCenterScreen> createState() => _VerificationCenterScreenState();
}

class _VerificationCenterScreenState extends ConsumerState<VerificationCenterScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();
  String _selectedDocType = 'GST Certificate';

  final List<String> _docTypes = [
    'GST Certificate',
    'Visiting Card',
    'Trade License',
    'Truck RC',
    'Driving License'
  ];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(verificationProvider.notifier).fetchPaymentStatus();
      await ref.read(verificationProvider.notifier).fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Center'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(verificationState.status),
            const SizedBox(height: 32),
            if (verificationState.status == VerificationStatus.unverified || 
                verificationState.status == VerificationStatus.rejected)
              _buildUploadSection(verificationState.status == VerificationStatus.loading),
            if (verificationState.status == VerificationStatus.pending)
              _buildPendingSection(),
            if (verificationState.status == VerificationStatus.verified)
              _buildVerifiedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(VerificationStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case VerificationStatus.verified:
        color = AppTheme.successEmerald;
        text = 'Verified';
        icon = LucideIcons.checkCircle;
        break;
      case VerificationStatus.pending:
        color = AppTheme.secondaryAmber;
        text = 'Pending Review';
        icon = LucideIcons.clock;
        break;
      case VerificationStatus.rejected:
        color = AppTheme.errorRed;
        text = 'Rejected';
        icon = LucideIcons.xCircle;
        break;
      case VerificationStatus.loading:
        color = AppTheme.primaryBlue;
        text = 'Loading...';
        icon = LucideIcons.refreshCw;
        break;
      default:
        color = AppTheme.textSecondary;
        text = 'Not Verified';
        icon = LucideIcons.alertCircle;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(bool isLoading) {
    final verificationState = ref.watch(verificationProvider);
    final paymentStatus = verificationState.paymentStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Documents',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'To access all features like posting loads or contacting suppliers, you must verify your identity.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        _buildPaymentSection(paymentStatus, verificationState.feeAmount, verificationState.feeCurrency),
        const SizedBox(height: 24),
        const Text('Document Type', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDocType,
          items: _docTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (val) => setState(() => _selectedDocType = val!),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Select Document Image', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        InkWell(
          onTap: isLoading ? null : _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 8),
                      Text('Tap to select image', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: isLoading || _selectedImage == null || paymentStatus != PaymentStatus.paid
              ? null
              : () async {
                  await ref.read(verificationProvider.notifier).uploadAndSubmit(
                        _selectedImage!,
                        _selectedDocType,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Documents submitted successfully!')),
                    );
                  }
                },
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(paymentStatus == PaymentStatus.paid ? 'Submit for Verification' : 'Pay fee to submit'),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(PaymentStatus status, num? amount, String? currency) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case PaymentStatus.paid:
        text = 'Verification fee paid';
        color = AppTheme.successEmerald;
        icon = LucideIcons.checkCircle;
        break;
      case PaymentStatus.loading:
        text = 'Checking payment...';
        color = AppTheme.primaryBlue;
        icon = LucideIcons.refreshCw;
        break;
      case PaymentStatus.error:
        text = 'Payment error. Try again.';
        color = AppTheme.errorRed;
        icon = LucideIcons.alertTriangle;
        break;
      default:
        text = 'Verification fee required';
        color = AppTheme.secondaryAmber;
        icon = LucideIcons.creditCard;
    }

    final amountText = (amount != null && currency != null) ? ' • $currency $amount' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$text$amountText',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          if (status != PaymentStatus.paid)
            TextButton(
              onPressed: status == PaymentStatus.loading
                  ? null
                  : () async {
                      await ref.read(verificationProvider.notifier).payVerificationFee();
                    },
              child: const Text('Pay Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(LucideIcons.hourglass, size: 64, color: AppTheme.secondaryAmber),
          SizedBox(height: 16),
          Text(
            'We are reviewing your documents.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'This usually takes 24-48 hours. You will be notified once the review is complete.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedSection() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(LucideIcons.shieldCheck, size: 64, color: AppTheme.successEmerald),
          SizedBox(height: 16),
          Text(
            'You are a verified user!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'You now have full access to all tranZfort features.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

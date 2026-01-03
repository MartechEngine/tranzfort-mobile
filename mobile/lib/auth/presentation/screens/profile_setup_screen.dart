import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String role;
  const ProfileSetupScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Common fields
  final _nameController = TextEditingController();
  
  // Supplier fields
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  
  // Trucker fields
  final _rcController = TextEditingController();
  final _truckTypeController = TextEditingController();
  final _wheelsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isSupplier = widget.role == 'SUPPLIER';

    return Scaffold(
      appBar: AppBar(
        title: Text('${isSupplier ? 'Supplier' : 'Trucker'} Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your details to get started.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                
                // Name Field (Common)
                _buildLabel('Full Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Enter your full name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),

                if (isSupplier) ...[
                  _buildLabel('Company Name (Optional)'),
                  TextFormField(
                    controller: _companyController,
                    decoration: _buildInputDecoration('Enter company name'),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('City'),
                  TextFormField(
                    controller: _cityController,
                    decoration: _buildInputDecoration('Enter your city'),
                    validator: (value) => value!.isEmpty ? 'Please enter your city' : null,
                  ),
                ] else ...[
                  _buildLabel('Truck RC Number'),
                  TextFormField(
                    controller: _rcController,
                    decoration: _buildInputDecoration('e.g. MH 12 AB 1234'),
                    validator: (value) => value!.isEmpty ? 'Please enter RC number' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Truck Type'),
                  TextFormField(
                    controller: _truckTypeController,
                    decoration: _buildInputDecoration('e.g. Open Body, Container'),
                    validator: (value) => value!.isEmpty ? 'Please enter truck type' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Number of Wheels'),
                  TextFormField(
                    controller: _wheelsController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('e.g. 6, 10, 12'),
                    validator: (value) => value!.isEmpty ? 'Please enter wheel count' : null,
                  ),
                ],
                
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: authState.status == AuthStatus.loading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final profileData = isSupplier
                                ? {
                                    'owner_name': _nameController.text,
                                    'company_name': _companyController.text,
                                    'city': _cityController.text,
                                  }
                                : {
                                    'full_name': _nameController.text,
                                    'truck_rc_number': _rcController.text,
                                    'truck_type': _truckTypeController.text,
                                    'wheel_count': int.tryParse(_wheelsController.text) ?? 0,
                                  };
                            
                            await ref.read(authProvider.notifier).updateProfile(widget.role, profileData);
                            
                            if (mounted) {
                              if (ref.read(authProvider).status == AuthStatus.error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ref.read(authProvider).errorMessage ?? 'Error updating profile')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile setup complete!')),
                                );
                                if (widget.role == 'SUPPLIER') {
                                  GoRouter.of(context).go('/supplier-home');
                                } else {
                                  GoRouter.of(context).go('/trucker-home');
                                }
                              }
                            }
                          }
                        },
                  child: authState.status == AuthStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Complete Setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _rcController.dispose();
    _truckTypeController.dispose();
    _wheelsController.dispose();
    super.dispose();
  }
}

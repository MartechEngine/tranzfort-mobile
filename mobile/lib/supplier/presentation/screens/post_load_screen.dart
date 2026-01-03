import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/load_provider.dart';

class PostLoadScreen extends ConsumerStatefulWidget {
  const PostLoadScreen({super.key});

  @override
  ConsumerState<PostLoadScreen> createState() => _PostLoadScreenState();
}

class _PostLoadScreenState extends ConsumerState<PostLoadScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _materialController = TextEditingController();
  final _weightController = TextEditingController();
  final _truckTypeController = TextEditingController();
  final _wheelsController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(loadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a New Load'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Pickup Location (City)'),
                TextFormField(
                  controller: _pickupController,
                  decoration: _buildInputDecoration('e.g. Mumbai'),
                  validator: (value) => value!.isEmpty ? 'Please enter pickup city' : null,
                ),
                const SizedBox(height: 20),
                
                _buildLabel('Drop Location (City)'),
                TextFormField(
                  controller: _dropController,
                  decoration: _buildInputDecoration('e.g. Delhi'),
                  validator: (value) => value!.isEmpty ? 'Please enter drop city' : null,
                ),
                const SizedBox(height: 20),
                
                _buildLabel('Material Type'),
                TextFormField(
                  controller: _materialController,
                  decoration: _buildInputDecoration('e.g. Steel, Cement, Fruits'),
                  validator: (value) => value!.isEmpty ? 'Please enter material type' : null,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Weight (MT)'),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 15'),
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Loading Date'),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null && picked != _selectedDate) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${_selectedDate.toLocal()}".split(' ')[0],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildLabel('Required Truck Type'),
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
                  decoration: _buildInputDecoration('e.g. 10, 12'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                
                _buildLabel('Remarks (Optional)'),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: _buildInputDecoration('Any additional information...'),
                ),
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: loadState.status == LoadStatus.loading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final loadData = {
                              'pickup_location': {'city': _pickupController.text},
                              'drop_location': {'city': _dropController.text},
                              'material_type': _materialController.text,
                              'weight_mt': double.tryParse(_weightController.text) ?? 0.0,
                              'required_truck_type': _truckTypeController.text,
                              'required_wheels': int.tryParse(_wheelsController.text) ?? 0,
                              'loading_date': _selectedDate.toIso8601String(),
                              'remarks': _remarksController.text,
                            };
                            
                            await ref.read(loadProvider.notifier).createLoad(loadData);
                            
                            if (mounted) {
                              if (ref.read(loadProvider).status == LoadStatus.error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(ref.read(loadProvider).errorMessage ?? 'Error posting load')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Load posted successfully!')),
                                );
                                GoRouter.of(context).pop();
                              }
                            }
                          }
                        },
                  child: loadState.status == LoadStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Post Load'),
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
    _pickupController.dispose();
    _dropController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _truckTypeController.dispose();
    _wheelsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

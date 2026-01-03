import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../supplier/providers/load_provider.dart';

class FindLoadScreen extends ConsumerStatefulWidget {
  const FindLoadScreen({super.key});

  @override
  ConsumerState<FindLoadScreen> createState() => _FindLoadScreenState();
}

class _FindLoadScreenState extends ConsumerState<FindLoadScreen> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  
  String? _selectedTruckType;
  int? _selectedWheels;

  @override
  void initState() {
    super.initState();
    // Initial search with no filters
    Future.microtask(() => ref.read(loadProvider.notifier).searchLoads({}));
  }

  void _onSearch() {
    final filters = <String, dynamic>{};
    if (_pickupController.text.isNotEmpty) {
      filters['pickup_city'] = _pickupController.text;
    }
    if (_dropController.text.isNotEmpty) {
      filters['drop_city'] = _dropController.text;
    }
    if (_selectedTruckType != null) {
      filters['truck_type'] = _selectedTruckType;
    }
    if (_selectedWheels != null) {
      filters['wheels'] = _selectedWheels;
    }
    ref.read(loadProvider.notifier).searchLoads(filters);
  }

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(loadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Loads'),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _buildResultsList(loadState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pickupController,
                  decoration: InputDecoration(
                    hintText: 'From City',
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrowRight, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _dropController,
                  decoration: InputDecoration(
                    hintText: 'To City',
                    prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSearch,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Search Loads'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(LoadState state) {
    if (state.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LoadStatus.error) {
      return Center(child: Text(state.errorMessage ?? 'An error occurred'));
    }

    if (state.searchResults.isEmpty) {
      return const Center(child: Text('No loads found matching your criteria.'));
    }

    return RefreshIndicator(
      onRefresh: () async => _onSearch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.searchResults.length,
        itemBuilder: (context, index) {
          final load = state.searchResults[index];
          return _buildLoadCard(load);
        },
      ),
    );
  }

  Widget _buildLoadCard(dynamic load) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${load['pickup_location']['city']} → ${load['drop_location']['city']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (load['supplier_profiles']['verification_status'] == 'VERIFIED')
                  const Icon(LucideIcons.checkCircle, color: AppTheme.successEmerald, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.package, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text("${load['material_type']} • ${load['weight_mt']} MT"),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.truck, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text("${load['required_truck_type']} • ${load['required_wheels']} Wheels"),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      load['supplier_profiles']['company_name'] ?? load['supplier_profiles']['owner_name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text("Supplier", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to Load Details / Initiate Chat
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Contact', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }
}

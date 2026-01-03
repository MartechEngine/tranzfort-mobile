import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/load_provider.dart';

class SupplierHomeScreen extends ConsumerStatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  ConsumerState<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends ConsumerState<SupplierHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(loadProvider.notifier).fetchMyLoads());
  }

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(loadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('tranZfort Supplier'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user),
            onPressed: () {
              // TODO: Navigate to Profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(loadProvider.notifier).fetchMyLoads(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(loadState.myLoads.length.toString()),
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: 'Post a New Load',
                subtitle: 'Find a truck for your cargo in seconds',
                icon: LucideIcons.plusCircle,
                color: AppTheme.primaryBlue,
                onTap: () {
                  GoRouter.of(context).push('/post-load');
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: 'My Active Loads',
                subtitle: 'Manage and track your current postings',
                icon: LucideIcons.list,
                color: AppTheme.secondaryAmber,
                onTap: () {
                  // TODO: Navigate to My Loads list screen
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (loadState.status == LoadStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (loadState.myLoads.isEmpty)
                const Center(child: Text('No recent activity to show.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loadState.myLoads.length > 5 ? 5 : loadState.myLoads.length,
                  itemBuilder: (context, index) {
                    final load = loadState.myLoads[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text("${load['pickup_location']['city']} → ${load['drop_location']['city']}"),
                        subtitle: Text("${load['material_type']} • ${load['weight_mt']} MT"),
                        trailing: Text(
                          load['status'],
                          style: TextStyle(
                            color: load['status'] == 'ACTIVE' ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push('/post-load');
        },
        label: const Text('Post Load'),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCards(String activeLoads) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Active Loads',
            value: activeLoads,
            icon: LucideIcons.package,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Total Chats',
            value: '0',
            icon: LucideIcons.messageSquare,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

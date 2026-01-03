import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class TruckerHomeScreen extends StatelessWidget {
  const TruckerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('tranZfort Trucker'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user),
            onPressed: () {
              // TODO: Navigate to Profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(context),
            const SizedBox(height: 32),
            Text(
              'Popular Routes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildRouteCard(context, 'Mumbai', 'Delhi'),
            const SizedBox(height: 12),
            _buildRouteCard(context, 'Bangalore', 'Chennai'),
            const SizedBox(height: 32),
            Text(
              'Nearby Loads',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('No loads found nearby.'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push('/find-load');
        },
        label: const Text('Find Load'),
        icon: const Icon(LucideIcons.search),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return InkWell(
      onTap: () {
        GoRouter.of(context).push('/find-load');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.search, color: AppTheme.textSecondary),
            SizedBox(width: 12),
            Text(
              'Search for loads...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, String from, String to) {
    return Card(
      child: ListTile(
        leading: const Icon(LucideIcons.mapPin, color: AppTheme.primaryBlue),
        title: Text('$from → $to'),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {
          GoRouter.of(context).push('/find-load');
        },
      ),
    );
  }
}

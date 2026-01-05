import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LoadStatus { initial, loading, success, error }

class LoadState {
  final LoadStatus status;
  final List<dynamic> myLoads;
  final List<dynamic> searchResults;
  final String? errorMessage;

  LoadState({
    this.status = LoadStatus.initial,
    this.myLoads = const [],
    this.searchResults = const [],
    this.errorMessage,
  });

  LoadState copyWith({
    LoadStatus? status,
    List<dynamic>? myLoads,
    List<dynamic>? searchResults,
    String? errorMessage,
  }) {
    return LoadState(
      status: status ?? this.status,
      myLoads: myLoads ?? this.myLoads,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoadNotifier extends StateNotifier<LoadState> {
  final _supabase = Supabase.instance.client;

  LoadNotifier() : super(LoadState());

  Future<void> createLoad(Map<String, dynamic> loadData) async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Get supplier profile id
      final supplierProfile = await _supabase
          .from('supplier_profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      await _supabase.from('loads').insert({
        'supplier_id': supplierProfile['id'],
        ...loadData,
        'status': 'ACTIVE',
      });

      state = state.copyWith(status: LoadStatus.success);
      await fetchMyLoads();
    } catch (e) {
      state = state.copyWith(status: LoadStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> fetchMyLoads() async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final supplierProfile = await _supabase
          .from('supplier_profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      final data = await _supabase
          .from('loads')
          .select('*, supplier_profiles(*)')
          .eq('supplier_id', supplierProfile['id'])
          .order('created_at', {ascending: false});

      state = state.copyWith(status: LoadStatus.success, myLoads: data as List);
    } catch (e) {
      state = state.copyWith(status: LoadStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> searchLoads(Map<String, dynamic> filters) async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      // If radius search is requested
      if (filters.containsKey('lat') && filters.containsKey('lng') && filters.containsKey('radius')) {
        final data = await _supabase.rpc('get_loads_by_radius', params: {
          'p_lat': filters['lat'],
          'p_lng': filters['lng'],
          'p_radius_meters': filters['radius'] * 1000, // km to meters
        });
        state = state.copyWith(status: LoadStatus.success, searchResults: data as List);
      } else {
        // Simple search
        var query = _supabase.from('loads').select('*, supplier_profiles(*)').eq('status', 'ACTIVE');
        
        if (filters.containsKey('material_type')) {
          query = query.eq('material_type', filters['material_type']);
        }
        
        final data = await query.order('created_at', {ascending: false});
        state = state.copyWith(status: LoadStatus.success, searchResults: data as List);
      }
    } catch (e) {
      state = state.copyWith(status: LoadStatus.error, errorMessage: e.toString());
    }
  }
}

final loadProvider = StateNotifierProvider<LoadNotifier, LoadState>((ref) {
  return LoadNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

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
  LoadNotifier() : super(LoadState());

  Future<void> createLoad(Map<String, dynamic> loadData) async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      await apiClient.dio.post('/loads', data: loadData);
      state = state.copyWith(status: LoadStatus.success);
      await fetchMyLoads(); // Refresh the list
    } catch (e) {
      state = state.copyWith(status: LoadStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> fetchMyLoads() async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      final response = await apiClient.dio.get('/loads/my');
      state = state.copyWith(status: LoadStatus.success, myLoads: response.data);
    } catch (e) {
      state = state.copyWith(status: LoadStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> searchLoads(Map<String, dynamic> filters) async {
    state = state.copyWith(status: LoadStatus.loading);
    try {
      final response = await apiClient.dio.get('/loads', queryParameters: filters);
      state = state.copyWith(status: LoadStatus.success, searchResults: response.data);
    } catch (e) {
      state = state.copyWith(status: LoadStatus.error, errorMessage: e.toString());
    }
  }
}

final loadProvider = StateNotifierProvider<LoadNotifier, LoadState>((ref) {
  return LoadNotifier();
});

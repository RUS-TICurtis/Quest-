import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'global_search_repository.dart';

class GlobalSearchState {
  final String query;
  final String selectedArchetype;
  final GlobalSearchResults results;
  final bool isLoading;
  final bool isTrending;
  final String? error;

  const GlobalSearchState({
    this.query = '',
    this.selectedArchetype = 'All',
    this.results = const GlobalSearchResults(),
    this.isLoading = false,
    this.isTrending = true,
    this.error,
  });

  GlobalSearchState copyWith({
    String? query,
    String? selectedArchetype,
    GlobalSearchResults? results,
    bool? isLoading,
    bool? isTrending,
    String? error,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      selectedArchetype: selectedArchetype ?? this.selectedArchetype,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isTrending: isTrending ?? this.isTrending,
      error: error,
    );
  }
}

class GlobalSearchNotifier extends Notifier<GlobalSearchState> {
  Timer? _debounceTimer;

  @override
  GlobalSearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    // Schedule initial trending load after build
    Future.microtask(() => loadTrending());
    return const GlobalSearchState();
  }

  GlobalSearchRepository get _repository =>
      ref.read(globalSearchRepositoryProvider);

  Future<void> loadTrending() async {
    state = state.copyWith(isLoading: true, isTrending: true);
    try {
      final trending = await _repository.getTrending();
      state = state.copyWith(
        results: trending,
        isLoading: false,
        isTrending: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void onQueryChanged(String newQuery) {
    _debounceTimer?.cancel();
    final trimmed = newQuery.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(query: '');
      loadTrending();
      return;
    }

    state = state.copyWith(query: newQuery, isLoading: true);
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      performSearch(trimmed);
    });
  }

  void setArchetypeFilter(String archetype) {
    if (state.selectedArchetype == archetype) return;
    state = state.copyWith(selectedArchetype: archetype, isLoading: true);
    performSearch(state.query);
  }

  Future<void> performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadTrending();
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final results = await _repository.searchAll(
        query: trimmed,
        archetypeFilter: state.selectedArchetype,
      );
      state = state.copyWith(
        results: results,
        isLoading: false,
        isTrending: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(query: '');
    loadTrending();
  }
}

final globalSearchProvider =
    NotifierProvider<GlobalSearchNotifier, GlobalSearchState>(
  GlobalSearchNotifier.new,
);

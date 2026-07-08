import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 历史记录项
class HistoryItem {
  final String id;
  final String title;
  final String url;
  final DateTime visitedAt;
  final int visitCount;

  HistoryItem({
    required this.id,
    required this.title,
    required this.url,
    required this.visitedAt,
    this.visitCount = 1,
  });

  HistoryItem copyWith({
    String? id,
    String? title,
    String? url,
    DateTime? visitedAt,
    int? visitCount,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      visitedAt: visitedAt ?? this.visitedAt,
      visitCount: visitCount ?? this.visitCount,
    );
  }
}

class HistoryService extends StateNotifier<List<HistoryItem>> {
  int _counter = 0;

  HistoryService() : super([]);

  void addVisit(String url, {String? title}) {
    final existingIndex = state.indexWhere((h) => h.url == url);

    if (existingIndex >= 0) {
      final newState = List<HistoryItem>.from(state);
      newState[existingIndex] = newState[existingIndex].copyWith(
        title: title ?? newState[existingIndex].title,
        visitedAt: DateTime.now(),
        visitCount: newState[existingIndex].visitCount + 1,
      );
      state = newState;
    } else {
      final item = HistoryItem(
        id: 'history_${_counter++}',
        title: title ?? url,
        url: url,
        visitedAt: DateTime.now(),
      );
      state = [item, ...state];
    }
  }

  void removeItem(String id) {
    state = state.where((h) => h.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  void clearOlderThan(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    state = state.where((h) => h.visitedAt.isAfter(cutoff)).toList();
  }

  List<HistoryItem> search(String query) {
    final q = query.toLowerCase();
    return state
        .where((h) =>
            h.title.toLowerCase().contains(q) ||
            h.url.toLowerCase().contains(q))
        .toList();
  }

  List<HistoryItem> getTodayHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((h) => h.visitedAt.isAfter(today)).toList();
  }

  List<HistoryItem> getTopVisited({int limit = 10}) {
    final sorted = List<HistoryItem>.from(state)
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return sorted.take(limit).toList();
  }
}

final historyServiceProvider =
    StateNotifierProvider<HistoryService, List<HistoryItem>>((ref) {
  return HistoryService();
});
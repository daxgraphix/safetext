import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/history_entry.dart';
import '../../data/repositories/history_repository.dart';
import 'services_providers.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  final HistoryRepository _repo;
  HistoryNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> add(HistoryEntry entry) async {
    await _repo.add(entry);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }

  Future<void> deleteExpired(Duration expiry) async {
    final now = DateTime.now();
    final expiredIds = state
        .where((e) => now.difference(e.timestamp) > expiry)
        .map((e) => e.id)
        .toList();

    if (expiredIds.isEmpty) return;

    for (final id in expiredIds) {
      await _repo.delete(id);
    }
    refresh();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    refresh();
  }

  List<HistoryEntry>? _lastCleared;

  Future<void> clearAllWithUndo() async {
    _lastCleared = List.from(state);
    await clearAll();
  }

  Future<void> restoreLastCleared() async {
    if (_lastCleared == null) return;
    final entries = _lastCleared!;
    _lastCleared = null;
    for (final entry in entries) {
      await _repo.add(entry);
    }
    refresh();
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

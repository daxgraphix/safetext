import '../../core/exceptions/app_exceptions.dart';
import '../datasources/hive_boxes.dart';
import '../models/history_entry.dart';

/// Persists and retrieves Secure History metadata. Never touches secret
/// message content or passphrases — see [HistoryEntry] doc comment.
class HistoryRepository {
  const HistoryRepository();

  List<HistoryEntry> getAll() {
    try {
      final entries = HiveBoxes.historyBox.values.cast<HistoryEntry>().toList();
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (_) {
      throw const StorageException('Unable to read secure history.');
    }
  }

  Future<void> add(HistoryEntry entry) async {
    try {
      await HiveBoxes.historyBox.put(entry.id, entry);
    } catch (_) {
      throw const StorageException('Unable to save history entry.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await HiveBoxes.historyBox.delete(id);
    } catch (_) {
      throw const StorageException('Unable to delete history entry.');
    }
  }

  Future<void> clearAll() async {
    try {
      await HiveBoxes.historyBox.clear();
    } catch (_) {
      throw const StorageException('Unable to clear history.');
    }
  }

  ({int encodedToday, int decodedToday, int imagesProcessed}) todayStats() {
    final now = DateTime.now();
    final all = getAll();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;

    final encodedToday = all.where((e) => e.operation == HistoryOperation.encoded && isToday(e.timestamp)).length;
    final decodedToday = all.where((e) => e.operation == HistoryOperation.decoded && isToday(e.timestamp)).length;
    return (encodedToday: encodedToday, decodedToday: decodedToday, imagesProcessed: all.length);
  }
}

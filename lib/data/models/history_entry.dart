import 'package:hive/hive.dart';

part 'history_entry.g.dart';

@HiveType(typeId: 1)
enum HistoryOperation {
  @HiveField(0)
  encoded,
  @HiveField(1)
  decoded,
  @HiveField(2)
  generated
}

@HiveType(typeId: 3)
enum HistoryStatus {
  @HiveField(0)
  success,
  @HiveField(1)
  failed
}

class HistoryTool {
  HistoryTool._();
  static const String safetext = 'safetext';
  static const String lsbText = 'lsb_text';
  static const String lsbDes = 'lsb_des';
  static const String passwordGenerator = 'password_generator';
  static const String caesarEncrypt = 'caesar_encrypt';
  static const String caesarDecrypt = 'caesar_decrypt';
}

@HiveType(typeId: 2)
class HistoryEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final HistoryOperation operation;
  @HiveField(2)
  final String imageName;
  @HiveField(3)
  final String mode;
  @HiveField(4)
  final DateTime timestamp;
  @HiveField(5)
  final HistoryStatus status;
  @HiveField(6)
  final String? cipherAlgorithm;
  @HiveField(7)
  final int? sizeBytes;
  @HiveField(8)
  final String toolId;

  const HistoryEntry({
    required this.id,
    required this.operation,
    required this.imageName,
    required this.mode,
    required this.timestamp,
    required this.status,
    this.cipherAlgorithm,
    this.sizeBytes,
    this.toolId = HistoryTool.safetext,
  });
}

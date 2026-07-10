// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 2;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      id: fields[0] as String,
      operation: fields[1] as HistoryOperation,
      imageName: fields[2] as String,
      mode: fields[3] as String,
      timestamp: fields[4] as DateTime,
      status: fields[5] as HistoryStatus,
      cipherAlgorithm: fields[6] as String?,
      sizeBytes: fields[7] as int?,
      toolId: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operation)
      ..writeByte(2)
      ..write(obj.imageName)
      ..writeByte(3)
      ..write(obj.mode)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.cipherAlgorithm)
      ..writeByte(7)
      ..write(obj.sizeBytes)
      ..writeByte(8)
      ..write(obj.toolId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoryOperationAdapter extends TypeAdapter<HistoryOperation> {
  @override
  final int typeId = 1;

  @override
  HistoryOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HistoryOperation.encoded;
      case 1:
        return HistoryOperation.decoded;
      case 2:
        return HistoryOperation.generated;
      default:
        return HistoryOperation.encoded;
    }
  }

  @override
  void write(BinaryWriter writer, HistoryOperation obj) {
    switch (obj) {
      case HistoryOperation.encoded:
        writer.writeByte(0);
        break;
      case HistoryOperation.decoded:
        writer.writeByte(1);
        break;
      case HistoryOperation.generated:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoryStatusAdapter extends TypeAdapter<HistoryStatus> {
  @override
  final int typeId = 3;

  @override
  HistoryStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HistoryStatus.success;
      case 1:
        return HistoryStatus.failed;
      default:
        return HistoryStatus.success;
    }
  }

  @override
  void write(BinaryWriter writer, HistoryStatus obj) {
    switch (obj) {
      case HistoryStatus.success:
        writer.writeByte(0);
        break;
      case HistoryStatus.failed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../data/models/history_entry.dart';

// ignore: prefer_const_constructors
final _uuid = Uuid();

enum LsbTextStage { idle, analyzing, encoding, saving, done, decoding, decoded, error }

class LsbTextState {
  // Encode side
  final Uint8List? encodeImageBytes;
  final String? encodeImageName;
  final int? capacityBytes;
  final String message;
  final Uint8List? resultBytes;
  final File? savedFile;

  // Decode side
  final Uint8List? decodeImageBytes;
  final String? decodeImageName;
  final String? decodedMessage;

  final LsbTextStage stage;
  final String? errorMessage;

  const LsbTextState({
    this.encodeImageBytes,
    this.encodeImageName,
    this.capacityBytes,
    this.message = '',
    this.resultBytes,
    this.savedFile,
    this.decodeImageBytes,
    this.decodeImageName,
    this.decodedMessage,
    this.stage = LsbTextStage.idle,
    this.errorMessage,
  });

  bool get isBusy =>
      stage == LsbTextStage.analyzing || stage == LsbTextStage.encoding || stage == LsbTextStage.saving || stage == LsbTextStage.decoding;

  bool get canEncode => encodeImageBytes != null && message.trim().isNotEmpty && (capacityBytes == null || message.length <= capacityBytes!);

  LsbTextState copyWith({
    Uint8List? encodeImageBytes,
    String? encodeImageName,
    int? capacityBytes,
    String? message,
    Uint8List? resultBytes,
    File? savedFile,
    Uint8List? decodeImageBytes,
    String? decodeImageName,
    String? decodedMessage,
    LsbTextStage? stage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LsbTextState(
      encodeImageBytes: encodeImageBytes ?? this.encodeImageBytes,
      encodeImageName: encodeImageName ?? this.encodeImageName,
      capacityBytes: capacityBytes ?? this.capacityBytes,
      message: message ?? this.message,
      resultBytes: resultBytes ?? this.resultBytes,
      savedFile: savedFile ?? this.savedFile,
      decodeImageBytes: decodeImageBytes ?? this.decodeImageBytes,
      decodeImageName: decodeImageName ?? this.decodeImageName,
      decodedMessage: decodedMessage ?? this.decodedMessage,
      stage: stage ?? this.stage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LsbTextNotifier extends StateNotifier<LsbTextState> {
  // ignore: prefer_const_constructors
  final Ref ref;
  // ignore: prefer_const_constructors
  LsbTextNotifier(this.ref) : super(const LsbTextState());

  Future<void> setEncodeImage(Uint8List bytes, String name) async {
    state = state.copyWith(encodeImageBytes: bytes, encodeImageName: name, stage: LsbTextStage.analyzing, clearError: true);
    try {
      final service = ref.read(lsbStegoServiceProvider);
      final capacity = await service.maxCapacityBytes(bytes);
      state = state.copyWith(capacityBytes: capacity, stage: LsbTextStage.idle);
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbTextStage.error, errorMessage: e.message);
    }
  }

  void setMessage(String value) => state = state.copyWith(message: value);

  Future<void> encode() async {
    if (!state.canEncode) return;
    final service = ref.read(lsbStegoServiceProvider);
    final storage = ref.read(storageServiceProvider);

    try {
      state = state.copyWith(stage: LsbTextStage.encoding, clearError: true);
      final embedded = await service.embed(imageBytes: state.encodeImageBytes!, message: state.message);

      state = state.copyWith(stage: LsbTextStage.saving);
      final file = await storage.saveEncodedImage(embedded, fileName: 'lsb_text_${DateTime.now().millisecondsSinceEpoch}.png');

      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.encoded,
            imageName: state.encodeImageName ?? 'image.png',
            mode: 'lsb',
            timestamp: DateTime.now(),
            status: HistoryStatus.success,
            cipherAlgorithm: 'None (plain LSB)',
            sizeBytes: embedded.length,
            toolId: HistoryTool.lsbText,
          ));

      state = state.copyWith(stage: LsbTextStage.done, resultBytes: embedded, savedFile: file);
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbTextStage.error, errorMessage: e.message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.encoded,
            imageName: state.encodeImageName ?? 'image.png',
            mode: 'lsb',
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
            toolId: HistoryTool.lsbText,
          ));
    }
  }

  Future<void> setDecodeImageAndDecode(Uint8List bytes, String name) async {
    state = state.copyWith(
      decodeImageBytes: bytes,
      decodeImageName: name,
      stage: LsbTextStage.decoding,
      clearError: true,
      decodedMessage: null,
    );
    final service = ref.read(lsbStegoServiceProvider);
    try {
      final message = await service.extract(bytes);
      state = state.copyWith(stage: LsbTextStage.decoded, decodedMessage: message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: name,
            mode: 'lsb',
            timestamp: DateTime.now(),
            status: HistoryStatus.success,
            cipherAlgorithm: 'None (plain LSB)',
            toolId: HistoryTool.lsbText,
          ));
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbTextStage.error, errorMessage: e.message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: name,
            mode: 'lsb',
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
            toolId: HistoryTool.lsbText,
          ));
    }
  }

  void reset() => state = const LsbTextState();
}

final lsbTextProvider = StateNotifierProvider.autoDispose<LsbTextNotifier, LsbTextState>((ref) {
  return LsbTextNotifier(ref);
});

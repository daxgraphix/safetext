import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../data/models/history_entry.dart';

// ignore: prefer_const_constructors
final _uuid = Uuid();

enum LsbDesStage { idle, analyzing, encrypting, embedding, saving, done, decoding, decrypted, error }

/// State for the "LSB with DES" module: DES-CBC encrypts the message, then
/// the resulting ciphertext bytes are embedded (base64-bridged, since the
/// underlying [LsbSteganographyService] frame carries UTF-8 text) using the
/// same plain-LSB engine as the "LSB on Text" module.
class LsbDesState {
  final Uint8List? encodeImageBytes;
  final String? encodeImageName;
  final int? capacityBytes;
  final String message;
  final String encryptKey;
  final bool useRedundancy;
  final Uint8List? resultBytes;
  final File? savedFile;

  final Uint8List? decodeImageBytes;
  final String? decodeImageName;
  final String decryptKey;
  final String? decryptedMessage;
  final bool payloadDetected;

  final LsbDesStage stage;
  final String? errorMessage;

  const LsbDesState({
    this.encodeImageBytes,
    this.encodeImageName,
    this.capacityBytes,
    this.message = '',
    this.encryptKey = '',
    this.useRedundancy = false,
    this.resultBytes,
    this.savedFile,
    this.decodeImageBytes,
    this.decodeImageName,
    this.decryptKey = '',
    this.decryptedMessage,
    this.payloadDetected = false,
    this.stage = LsbDesStage.idle,
    this.errorMessage,
  });

  bool get isBusy =>
      stage == LsbDesStage.analyzing ||
      stage == LsbDesStage.encrypting ||
      stage == LsbDesStage.embedding ||
      stage == LsbDesStage.saving ||
      stage == LsbDesStage.decoding;

  bool get canEncode =>
      encodeImageBytes != null && message.trim().isNotEmpty && encryptKey.isNotEmpty;

  bool get canDecode => payloadDetected && decryptKey.isNotEmpty;

  LsbDesState copyWith({
    Uint8List? encodeImageBytes,
    String? encodeImageName,
    int? capacityBytes,
    String? message,
    String? encryptKey,
    bool? useRedundancy,
    Uint8List? resultBytes,
    File? savedFile,
    Uint8List? decodeImageBytes,
    String? decodeImageName,
    String? decryptKey,
    String? decryptedMessage,
    bool? payloadDetected,
    LsbDesStage? stage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LsbDesState(
      encodeImageBytes: encodeImageBytes ?? this.encodeImageBytes,
      encodeImageName: encodeImageName ?? this.encodeImageName,
      capacityBytes: capacityBytes ?? this.capacityBytes,
      message: message ?? this.message,
      encryptKey: encryptKey ?? this.encryptKey,
      useRedundancy: useRedundancy ?? this.useRedundancy,
      resultBytes: resultBytes ?? this.resultBytes,
      savedFile: savedFile ?? this.savedFile,
      decodeImageBytes: decodeImageBytes ?? this.decodeImageBytes,
      decodeImageName: decodeImageName ?? this.decodeImageName,
      decryptKey: decryptKey ?? this.decryptKey,
      decryptedMessage: decryptedMessage ?? this.decryptedMessage,
      payloadDetected: payloadDetected ?? this.payloadDetected,
      stage: stage ?? this.stage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LsbDesNotifier extends StateNotifier<LsbDesState> {
  // ignore: prefer_const_constructors
  final Ref ref;
  String? _pendingDecodeBase64;
  // ignore: prefer_const_constructors
  LsbDesNotifier(this.ref) : super(const LsbDesState());

  Future<void> setEncodeImage(Uint8List bytes, String name) async {
    state = state.copyWith(encodeImageBytes: bytes, encodeImageName: name, stage: LsbDesStage.analyzing, clearError: true);
    await _updateCapacity();
  }

  Future<void> _updateCapacity() async {
    if (state.encodeImageBytes == null) return;
    try {
      final lsb = ref.read(lsbStegoServiceProvider);
      final capacity = await lsb.maxCapacityBytes(state.encodeImageBytes!, useRedundancy: state.useRedundancy);
      state = state.copyWith(capacityBytes: capacity, stage: LsbDesStage.idle);
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbDesStage.error, errorMessage: e.message);
    }
  }

  void setMessage(String value) => state = state.copyWith(message: value);
  void setEncryptKey(String value) => state = state.copyWith(encryptKey: value);
  void setDecryptKey(String value) => state = state.copyWith(decryptKey: value);
  
  void setUseRedundancy(bool value) {
    state = state.copyWith(useRedundancy: value, stage: LsbDesStage.analyzing);
    _updateCapacity();
  }

  Future<void> encryptAndEmbed() async {
    if (!state.canEncode) return;
    final des = ref.read(desCryptoServiceProvider);
    final lsb = ref.read(lsbStegoServiceProvider);
    final storage = ref.read(storageServiceProvider);

    try {
      state = state.copyWith(stage: LsbDesStage.encrypting, clearError: true);
      final encrypted = await des.encrypt(state.message, state.encryptKey);
      final bridged = base64Encode(encrypted);

      state = state.copyWith(stage: LsbDesStage.embedding);
      final embedded = await lsb.embed(
        imageBytes: state.encodeImageBytes!, 
        message: bridged,
        useRedundancy: state.useRedundancy,
      );

      state = state.copyWith(stage: LsbDesStage.saving);
      final file = await storage.saveEncodedImage(embedded, fileName: 'lsb_des_${DateTime.now().millisecondsSinceEpoch}.png');

      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.encoded,
            imageName: state.encodeImageName ?? 'image.png',
            mode: 'lsb-des',
            timestamp: DateTime.now(),
            status: HistoryStatus.success,
            cipherAlgorithm: 'DES-CBC',
            sizeBytes: embedded.length,
            toolId: HistoryTool.lsbDes,
          ));

      state = state.copyWith(stage: LsbDesStage.done, resultBytes: embedded, savedFile: file);
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbDesStage.error, errorMessage: e.message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.encoded,
            imageName: state.encodeImageName ?? 'image.png',
            mode: 'lsb-des',
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
            toolId: HistoryTool.lsbDes,
          ));
    }
  }

  Future<void> setDecodeImage(Uint8List bytes, String name) async {
    state = state.copyWith(decodeImageBytes: bytes, decodeImageName: name, stage: LsbDesStage.decoding, clearError: true);
    final lsb = ref.read(lsbStegoServiceProvider);
    try {
      final bridged = await lsb.extract(bytes);
      _pendingDecodeBase64 = bridged;
      state = state.copyWith(stage: LsbDesStage.idle, payloadDetected: true);
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbDesStage.error, errorMessage: e.message, payloadDetected: false);
    }
  }

  Future<void> decrypt() async {
    if (!state.canDecode || _pendingDecodeBase64 == null) return;
    final des = ref.read(desCryptoServiceProvider);
    state = state.copyWith(stage: LsbDesStage.decoding, clearError: true);
    try {
      final encryptedBytes = base64Decode(_pendingDecodeBase64!);
      final message = await des.decrypt(encryptedBytes, state.decryptKey);
      state = state.copyWith(stage: LsbDesStage.decrypted, decryptedMessage: message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: state.decodeImageName ?? 'image.png',
            mode: 'lsb-des',
            timestamp: DateTime.now(),
            status: HistoryStatus.success,
            cipherAlgorithm: 'DES-CBC',
            toolId: HistoryTool.lsbDes,
          ));
    } on AppException catch (e) {
      state = state.copyWith(stage: LsbDesStage.error, errorMessage: e.message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: state.decodeImageName ?? 'image.png',
            mode: 'lsb-des',
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
            toolId: HistoryTool.lsbDes,
          ));
    } catch (_) {
      state = state.copyWith(stage: LsbDesStage.error, errorMessage: 'Incorrect DES key or corrupted payload.');
    }
  }

  void reset() {
    _pendingDecodeBase64 = null;
    state = const LsbDesState();
  }
}

final lsbDesProvider = StateNotifierProvider.autoDispose<LsbDesNotifier, LsbDesState>((ref) {
  return LsbDesNotifier(ref);
});

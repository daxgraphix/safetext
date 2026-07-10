import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/security/payload_codec.dart';
import '../../../core/security/stego_service.dart';
import '../../../data/models/history_entry.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum EncodeStage { idle, analyzing, encrypting, embedding, verifying, saving, done, error }

class EncodeState {
  final Uint8List? imageBytes;
  final String? imageName;
  final ImageAnalysis? analysis;
  final String message;
  final String passphrase;
  final StegoMode mode;
  final EncodeStage stage;
  final String? errorMessage;
  final Uint8List? resultBytes;
  final File? savedFile;

  const EncodeState({
    this.imageBytes,
    this.imageName,
    this.analysis,
    this.message = '',
    this.passphrase = '',
    this.mode = StegoMode.ghost,
    this.stage = EncodeStage.idle,
    this.errorMessage,
    this.resultBytes,
    this.savedFile,
  });

  bool get hasImage => imageBytes != null;
  bool get isProcessing =>
      stage == EncodeStage.analyzing ||
      stage == EncodeStage.encrypting ||
      stage == EncodeStage.embedding ||
      stage == EncodeStage.verifying ||
      stage == EncodeStage.saving;

  int get estimatedMessageBytes => utf8.encode(message).length;

  /// Calculates how much larger the encoded PNG is compared to the original.
  /// Used to warn the user if the file size increase is "suspicious".
  double get expansionRatio {
    if (imageBytes == null || resultBytes == null) return 1.0;
    return resultBytes!.length / imageBytes!.length;
  }

  /// Returns true if the file size has increased by more than 3x,
  /// which might look suspicious to an observer.
  bool get isExpansionSuspicious => expansionRatio > 3.0;

  EncodeState copyWith({
    Uint8List? imageBytes,
    String? imageName,
    ImageAnalysis? analysis,
    String? message,
    String? passphrase,
    StegoMode? mode,
    EncodeStage? stage,
    String? errorMessage,
    Uint8List? resultBytes,
    File? savedFile,
    bool clearError = false,
  }) {
    return EncodeState(
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      analysis: analysis ?? this.analysis,
      message: message ?? this.message,
      passphrase: passphrase ?? this.passphrase,
      mode: mode ?? this.mode,
      stage: stage ?? this.stage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resultBytes: resultBytes ?? this.resultBytes,
      savedFile: savedFile ?? this.savedFile,
    );
  }
}

class EncodeNotifier extends StateNotifier<EncodeState> {
  final Ref ref;
  EncodeNotifier(this.ref) : super(EncodeState(mode: ref.read(settingsProvider).defaultStegoMode));

  Future<void> setImage(Uint8List bytes, String name) async {
    state = EncodeState(
      imageBytes: bytes,
      imageName: name,
      mode: state.mode,
      stage: EncodeStage.idle,
    );
    await _analyze();
  }

  Future<void> setMode(StegoMode mode) async {
    state = state.copyWith(mode: mode);
    if (state.hasImage) await _analyze();
  }

  Future<void> _analyze() async {
    if (state.imageBytes == null) return;
    state = state.copyWith(stage: EncodeStage.analyzing, clearError: true);
    try {
      final stego = ref.read(stegoServiceProvider);
      // Analysis now runs in a background isolate via StegoService
      final analysis = await stego.analyze(state.imageBytes!, mode: state.mode);
      state = state.copyWith(analysis: analysis, stage: EncodeStage.idle);
    } on AppException catch (e) {
      state = state.copyWith(stage: EncodeStage.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(stage: EncodeStage.error, errorMessage: 'Failed to analyze image. It may be corrupted.');
    }
  }

  void setMessage(String value) {
    state = state.copyWith(message: value, clearError: true);
  }

  void setPassphrase(String value) {
    state = state.copyWith(passphrase: value, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  bool get canEncode {
    if (!state.hasImage || state.analysis == null) return false;
    if (state.message.trim().isEmpty || state.message.length > AppConstants.maxMessageChars) return false;
    if (state.passphrase.length < AppConstants.minPassphraseLength) return false;
    if (state.estimatedMessageBytes > state.analysis!.maxCapacityBytes) return false;
    return true;
  }

  Future<void> encode() async {
    if (!canEncode) {
      final validationMessage = state.message.trim().isEmpty
          ? 'Enter a message before encoding.'
          : state.message.length > AppConstants.maxMessageChars
              ? 'The message is too long for this image and mode.'
              : state.passphrase.length < AppConstants.minPassphraseLength
                  ? 'Choose a longer passphrase with at least ${AppConstants.minPassphraseLength} characters.'
                  : state.estimatedMessageBytes > (state.analysis?.maxCapacityBytes ?? 0)
                      ? 'This image cannot safely carry the current message size. Shorten it or choose a larger image.'
                      : 'Add an image and complete the required fields before encoding.';
      state = state.copyWith(stage: EncodeStage.error, errorMessage: validationMessage);
      return;
    }
    final crypto = ref.read(cryptoServiceProvider);
    final stego = ref.read(stegoServiceProvider);
    final storage = ref.read(storageServiceProvider);
    const PayloadCodec codec = PayloadCodec();

    try {
      state = state.copyWith(stage: EncodeStage.encrypting, clearError: true);
      final encryptionResult = await crypto.encrypt(state.message, state.passphrase);

      state = state.copyWith(stage: EncodeStage.embedding);
      final body = codec.buildBody(
        timestamp: DateTime.now(),
        salt: encryptionResult.salt,
        nonce: encryptionResult.nonce,
        cipherText: encryptionResult.cipherText,
        mac: encryptionResult.mac,
      );
      final seedBytes = crypto.randomBytes(8);
      final seed = seedBytes.buffer.asByteData().getInt64(0);

      final embedded = await stego.embed(
        imageBytes: state.imageBytes!,
        bodyBytes: body,
        mode: state.mode,
        seed: seed,
      );

      state = state.copyWith(stage: EncodeStage.verifying);
      // Round-trip verification: re-extract & re-decrypt to guarantee the
      // saved file is actually recoverable before we report success.
      final extracted = await stego.extract(embedded);
      await crypto.decrypt(
        salt: extracted.salt,
        nonce: extracted.nonce,
        cipherText: extracted.cipherText,
        mac: extracted.mac,
        passphrase: state.passphrase,
      );

      state = state.copyWith(stage: EncodeStage.saving);
      final file = await storage.saveEncodedImage(embedded);

      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.encoded,
            imageName: state.imageName ?? 'image.png',
            mode: state.mode.id,
            timestamp: DateTime.now(),
            status: HistoryStatus.success,
            cipherAlgorithm: 'AES-256 GCM',
            sizeBytes: embedded.length,
          ));

      state = state.copyWith(stage: EncodeStage.done, resultBytes: embedded, savedFile: file);
      await HapticFeedback.mediumImpact();
    } on AppException catch (e) {
      state = state.copyWith(stage: EncodeStage.error, errorMessage: e.message);
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.encoded,
            imageName: state.imageName ?? 'image.png',
            mode: state.mode.id,
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
          ));
    } catch (_) {
      state = state.copyWith(stage: EncodeStage.error, errorMessage: 'Encoding failed unexpectedly. Please retry with a fresh image or shorter message.');
    }
  }

  void reset() => state = const EncodeState();
}

final encodeProvider = StateNotifierProvider.autoDispose<EncodeNotifier, EncodeState>((ref) {
  return EncodeNotifier(ref);
});

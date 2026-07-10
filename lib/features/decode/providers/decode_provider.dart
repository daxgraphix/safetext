import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/history_entry.dart';

const _uuid = Uuid();

enum DecodeStage {
  idle,
  scanning,
  found,
  notFound,
  decrypting,
  verifying,
  success,
  error,
}

class DecodeState {
  final Uint8List? imageBytes;
  final String? imageName;
  final String passphrase;
  final DecodeStage stage;
  final String? decryptedMessage;
  final String? mode;
  final String? errorMessage;
  final int failedAttempts;

  const DecodeState({
    this.imageBytes,
    this.imageName,
    this.passphrase = '',
    this.stage = DecodeStage.idle,
    this.decryptedMessage,
    this.mode,
    this.errorMessage,
    this.failedAttempts = 0,
  });

  bool get hasImage => imageBytes != null;
  bool get payloadDetected => stage == DecodeStage.found || stage == DecodeStage.decrypting || stage == DecodeStage.success;

  DecodeState copyWith({
    Uint8List? imageBytes,
    String? imageName,
    String? passphrase,
    DecodeStage? stage,
    String? decryptedMessage,
    String? mode,
    String? errorMessage,
    int? failedAttempts,
    bool clearError = false,
  }) {
    return DecodeState(
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      passphrase: passphrase ?? this.passphrase,
      stage: stage ?? this.stage,
      decryptedMessage: decryptedMessage ?? this.decryptedMessage,
      mode: mode ?? this.mode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}

class DecodeNotifier extends StateNotifier<DecodeState> {
  final Ref ref;
  dynamic _extractedPayload;

  DecodeNotifier(this.ref) : super(const DecodeState());

  Future<void> setImage(Uint8List bytes, String name) async {
    state = DecodeState(imageBytes: bytes, imageName: name, stage: DecodeStage.scanning);
    final stego = ref.read(stegoServiceProvider);
    try {
      final payload = await stego.extract(bytes);
      _extractedPayload = payload;
      state = state.copyWith(stage: DecodeStage.found, mode: payload.isGhost ? 'Ghost' : 'Armor');
    } on AppException {
      state = state.copyWith(stage: DecodeStage.notFound);
    } catch (_) {
      state = state.copyWith(stage: DecodeStage.notFound);
    }
  }

  void setPassphrase(String value) {
    state = state.copyWith(passphrase: value, clearError: true);
  }

  void clearError() {
    state = state.copyWith(
      stage: _extractedPayload != null ? DecodeStage.found : DecodeStage.idle,
      clearError: true,
    );
  }

  Future<void> decode() async {
    if (_extractedPayload == null) {
      state = state.copyWith(stage: DecodeStage.error, errorMessage: 'No SafeText payload was found in this image.');
      return;
    }
    if (state.passphrase.isEmpty) {
      state = state.copyWith(stage: DecodeStage.error, errorMessage: 'Enter your passphrase to decrypt this payload.');
      return;
    }
    state = state.copyWith(stage: DecodeStage.decrypting, clearError: true);
    final crypto = ref.read(cryptoServiceProvider);
    final settings = ref.read(settingsProvider);
    try {
      final message = await crypto.decrypt(
        salt: _extractedPayload.salt,
        nonce: _extractedPayload.nonce,
        cipherText: _extractedPayload.cipherText,
        mac: _extractedPayload.mac,
        passphrase: state.passphrase,
      );

      state = state.copyWith(stage: DecodeStage.verifying);
      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(stage: DecodeStage.success, decryptedMessage: message, failedAttempts: 0);
      await HapticFeedback.mediumImpact();
      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: state.imageName ?? 'image.png',
            mode: (_extractedPayload.isGhost ? StegoMode.ghost : StegoMode.armor).id,
            timestamp: DateTime.now(),
            status: HistoryStatus.success,
            cipherAlgorithm: 'AES-256 GCM',
          ));
    } on AppException catch (e) {
      final newAttempts = state.failedAttempts + 1;
      state = state.copyWith(stage: DecodeStage.error, errorMessage: e.message, failedAttempts: newAttempts);
      
      if (settings.panicWipeEnabled && newAttempts >= settings.maxFailedAttempts) {
        await _performPanicWipe();
      }

      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: state.imageName ?? 'image.png',
            mode: (_extractedPayload?.isGhost == true ? StegoMode.ghost : StegoMode.armor).id,
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
          ));
    } catch (_) {
      final newAttempts = state.failedAttempts + 1;
      state = state.copyWith(stage: DecodeStage.error, errorMessage: 'Decode failed unexpectedly.', failedAttempts: newAttempts);
      
      if (settings.panicWipeEnabled && newAttempts >= settings.maxFailedAttempts) {
        await _performPanicWipe();
      }

      await ref.read(historyProvider.notifier).add(HistoryEntry(
            id: _uuid.v4(),
            operation: HistoryOperation.decoded,
            imageName: state.imageName ?? 'image.png',
            mode: (_extractedPayload?.isGhost == true ? StegoMode.ghost : StegoMode.armor).id,
            timestamp: DateTime.now(),
            status: HistoryStatus.failed,
          ));
    }
  }

  Future<void> _performPanicWipe() async {
    await ref.read(historyProvider.notifier).clearAll();
    state = state.copyWith(
      errorMessage: 'SECURITY ALERT: Maximum failed attempts reached. Local history has been wiped for your protection.',
    );
  }

  void reset() {
    _extractedPayload = null;
    state = const DecodeState();
  }
}

final decodeProvider = StateNotifierProvider.autoDispose<DecodeNotifier, DecodeState>((ref) {
  return DecodeNotifier(ref);
});

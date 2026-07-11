import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/security/caesar_cipher_service.dart';
import '../../core/security/crypto_service.dart';
import '../../core/security/des_crypto_service.dart';
import '../../core/security/device_integrity_service.dart';
import '../../core/security/device_security_service.dart';
import '../../core/security/lsb_steganography_service.dart';
import '../../core/security/password_generator_service.dart';
import '../../core/security/password_strength_analyzer.dart';
import '../../core/security/stego_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/security_channel_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());
final stegoServiceProvider = Provider<StegoService>((ref) => const StegoService());
final storageServiceProvider = Provider<StorageService>((ref) => const StorageService());
final clipboardServiceProvider = Provider<ClipboardService>((ref) => ClipboardService(ref));
final securityChannelServiceProvider = Provider<SecurityChannelService>((ref) => const SecurityChannelService());
final deviceSecurityServiceProvider = Provider<DeviceSecurityService>((ref) => DeviceSecurityService(const FlutterSecureStorage()));
final deviceIntegrityServiceProvider = Provider<DeviceIntegrityService>((ref) => const DeviceIntegrityService());

final lsbStegoServiceProvider = Provider<LsbSteganographyService>((ref) => const LsbSteganographyService());
final desCryptoServiceProvider = Provider<DesCryptoService>((ref) => const DesCryptoService());
final caesarCipherServiceProvider = Provider<CaesarCipherService>((ref) => const CaesarCipherService());
final passwordGeneratorServiceProvider = Provider<PasswordGeneratorService>((ref) => const PasswordGeneratorService());
final passwordStrengthAnalyzerProvider = Provider<PasswordStrengthAnalyzer>((ref) => const PasswordStrengthAnalyzer());

final historyRepositoryProvider = Provider<HistoryRepository>((ref) => const HistoryRepository());
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => const SettingsRepository());

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../exceptions/app_exceptions.dart';

/// Binds the application data to the physical device using hardware-backed 
/// storage (Keystore/Keychain).
class DeviceSecurityService {
  final FlutterSecureStorage _secureStorage;
  static const String _bindingKey = 'device_binding_id';
  static const String _encryptionKey = 'database_encryption_key';

  DeviceSecurityService(this._secureStorage);

  /// Verifies if the current installation matches the stored hardware binding.
  /// Throws [SecurityException] if a mismatch is detected (indicating data tampering).
  /// Returns the hardware ID.
  Future<String> verifyDeviceBinding(String? storedId) async {
    final hardwareId = await _getOrCreateHardwareId();
    if (storedId != null && storedId != hardwareId) {
      throw const SecurityException(
        'Security breach detected: Application data does not match this device. '
        'Secure history has been locked to protect your privacy.',
      );
    }
    return hardwareId;
  }

  /// Returns a secure encryption key anchored to the device's TEE.
  /// Generates a new one if it doesn't exist.
  Future<Uint8List> getDatabaseKey() async {
    String? keyBase64 = await _secureStorage.read(key: _encryptionKey);
    if (keyBase64 == null) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(key: _encryptionKey, value: base64Url.encode(key));
      return Uint8List.fromList(key);
    }
    return base64Url.decode(keyBase64);
  }

  Future<String> _getOrCreateHardwareId() async {
    String? id = await _secureStorage.read(key: _bindingKey);
    if (id == null) {
      id = const Uuid().v4();
      await _secureStorage.write(key: _bindingKey, value: id);
    }
    return id;
  }
}

import 'package:safe_device/safe_device.dart';

class DeviceIntegrityResult {
  final bool isRooted;
  final bool isRealDevice;
  final bool isDevMode;
  final bool isSafe;

  const DeviceIntegrityResult({
    required this.isRooted,
    required this.isRealDevice,
    required this.isDevMode,
    required this.isSafe,
  });

  factory DeviceIntegrityResult.unknown() => const DeviceIntegrityResult(
        isRooted: false,
        isRealDevice: true,
        isDevMode: false,
        isSafe: true,
      );
}

class DeviceIntegrityService {
  const DeviceIntegrityService();

  Future<DeviceIntegrityResult> checkIntegrity() async {
    final isRooted = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;
    final isDevMode = await SafeDevice.isDevelopmentModeEnable;
    final isSafe = await SafeDevice.isSafeDevice;

    return DeviceIntegrityResult(
      isRooted: isRooted,
      isRealDevice: isRealDevice,
      isDevMode: isDevMode,
      isSafe: isSafe,
    );
  }
}

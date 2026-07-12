import 'dart:io';
import 'package:safe_device/safe_device.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceIntegrityResult {
  final bool isRooted;
  final bool isRealDevice;
  final bool isDevMode;
  final bool isSafe;
  final String deviceModel;
  final String osVersion;

  const DeviceIntegrityResult({
    required this.isRooted,
    required this.isRealDevice,
    required this.isDevMode,
    required this.isSafe,
    required this.deviceModel,
    required this.osVersion,
  });

  factory DeviceIntegrityResult.unknown() => const DeviceIntegrityResult(
        isRooted: false,
        isRealDevice: true,
        isDevMode: false,
        isSafe: true,
        deviceModel: 'Unknown',
        osVersion: 'Unknown',
      );
}

class DeviceIntegrityService {
  const DeviceIntegrityService();

  Future<DeviceIntegrityResult> checkIntegrity() async {
    final isRooted = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;
    final isDevMode = await SafeDevice.isDevelopmentModeEnable;
    final isSafe = await SafeDevice.isSafeDevice;

    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (_) {}

    return DeviceIntegrityResult(
      isRooted: isRooted,
      isRealDevice: isRealDevice,
      isDevMode: isDevMode,
      isSafe: isSafe,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }
}

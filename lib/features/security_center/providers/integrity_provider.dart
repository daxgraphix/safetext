import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/security/device_integrity_service.dart';

final integrityProvider = FutureProvider<DeviceIntegrityResult>((ref) async {
  final service = ref.watch(deviceIntegrityServiceProvider);
  return service.checkIntegrity();
});

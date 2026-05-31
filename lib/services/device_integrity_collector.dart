import 'package:flutter/services.dart';
import 'package:haam_counter/models/security_state.dart';

class DeviceIntegrityCollector {
  static const _channel = MethodChannel('com.haam.security/integrity');

  Future<DeviceIntegrity> collect() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('checkIntegrity');
      if (raw == null) return const DeviceIntegrity(isRooted: false, isEmulator: false);
      return DeviceIntegrity(
        isRooted:   raw['is_rooted']   as bool? ?? false,
        isEmulator: raw['is_emulator'] as bool? ?? false,
      );
    } on PlatformException {
      return const DeviceIntegrity(isRooted: false, isEmulator: false);
    } catch (_) {
      return const DeviceIntegrity(isRooted: false, isEmulator: false);
    }
  }
}

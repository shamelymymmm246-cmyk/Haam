import 'package:flutter/services.dart';
import 'package:haam_counter/models/security_state.dart';

class DeviceIntegrityCollector {
  static const _channel = MethodChannel('com.haam.security/integrity');

  Future<DeviceIntegrity> collect() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('checkIntegrity');
      if (raw == null) return const DeviceIntegrity(isRooted: false, isEmulator: false);
      return DeviceIntegrity(
        isRooted:           raw['is_rooted']            as bool? ?? false,
        isEmulator:         raw['is_emulator']          as bool? ?? false,
        isDebuggable:       raw['is_debuggable']        as bool? ?? false,
        isDebuggerAttached: raw['is_debugger_attached'] as bool? ?? false,
        isBeingTraced:      raw['is_being_traced']      as bool? ?? false,
        isFridaDetected:    raw['is_frida_detected']    as bool? ?? false,
        isXposedDetected:   raw['is_xposed_detected']   as bool? ?? false,
        isAdbEnabled:       raw['is_adb_enabled']       as bool? ?? false,
        isMockLocation:     raw['is_mock_location']     as bool? ?? false,
        signatureValid:     raw['signature_valid']      as bool? ?? true,
        installerTrusted:   raw['installer_trusted']    as bool? ?? true,
        apkIntegrityValid:  raw['apk_integrity_valid']  as bool? ?? true,
        isMagiskHidden:     raw['is_magisk_hidden']     as bool? ?? false,
        isClockTampered:    raw['is_clock_tampered']    as bool? ?? false,
        hasStrongBiometric:  raw['has_strong_biometric'] as bool? ?? false,
      );
    } on PlatformException {
      return const DeviceIntegrity(isRooted: false, isEmulator: false);
    } catch (_) {
      return const DeviceIntegrity(isRooted: false, isEmulator: false);
    }
  }
}

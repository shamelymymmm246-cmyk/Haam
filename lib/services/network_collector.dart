import 'package:flutter/services.dart';
import 'package:haam_counter/models/security_state.dart';

class NetworkCollector {
  static const _channel = MethodChannel('com.haam.security/network');

  Future<NetworkInfo?> collect() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('getWifiInfo');
      if (raw == null) return null;
      return _parse(raw);
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  NetworkInfo _parse(Map<String, dynamic> raw) {
    final encType = _parseEncryption(raw['encryption_type'] as String?);
    return NetworkInfo(
      ssid: raw['ssid'] as String?,
      bssid: raw['bssid'] as String?,
      gateway: raw['gateway'] as String?,
      subnetMask: raw['subnet_mask'] as String?,
      isOpenNetwork: raw['is_open'] as bool? ?? false,
      encryptionType: encType,
      signal: raw['signal'] as int?,
      frequency: raw['frequency'] as int?,
      hasSystemProxy: raw['has_system_proxy'] as bool? ?? false,
    );
  }

  EncryptionType _parseEncryption(String? raw) {
    switch (raw) {
      case 'none':    return EncryptionType.none;
      case 'wep':     return EncryptionType.wep;
      case 'wpa':     return EncryptionType.wpa;
      case 'wpa2':    return EncryptionType.wpa2;
      case 'wpa3':    return EncryptionType.wpa3;
      case 'eap':     return EncryptionType.eap;
      case 'owe':     return EncryptionType.owe;
      default:        return EncryptionType.unknown;
    }
  }
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:haam_counter/models/dns_status.dart';

class DnsService {
  static const _channel = MethodChannel('com.haam.security/dns');

  Future<DnsStatus> checkStatus() async {
    final vpn = await _hasActiveVpn();
    final mode = await _getPrivateDnsMode();
    final hostname = await _getPrivateDnsHostname();
    return DnsStatus(
      mode: mode,
      hostname: hostname,
      hasActiveVpn: vpn,
    );
  }

  // قراءة إعداد Private DNS من Android (API 28+) عبر MethodChannel
  Future<DnsMode> _getPrivateDnsMode() async {
    try {
      final raw = await _channel.invokeMethod<String>('getPrivateDnsMode');
      switch (raw) {
        case 'hostname':    return DnsMode.hostname;
        case 'opportunistic': return DnsMode.opportunistic;
        case 'off':         return DnsMode.off;
        default:            return DnsMode.unknown;
      }
    } on PlatformException {
      return DnsMode.unknown;
    }
  }

  Future<String?> _getPrivateDnsHostname() async {
    try {
      return await _channel.invokeMethod<String>('getPrivateDnsHostname');
    } on PlatformException {
      return null;
    }
  }

  // فحص وجود VPN نشط عبر فحص واجهات الشبكة (tun / ppp)
  Future<bool> _hasActiveVpn() async {
    try {
      final ifaces = await NetworkInterface.list();
      return ifaces.any((i) {
        final name = i.name.toLowerCase();
        return name.contains('tun') || name.contains('ppp');
      });
    } catch (_) {
      return false;
    }
  }

  // فتح إعدادات Private DNS في النظام
  Future<void> openPrivateDnsSettings() async {
    try {
      await _channel.invokeMethod('openPrivateDnsSettings');
    } on PlatformException {
      // إذا فشل، يُعرض للمستخدم مسار الإعدادات يدوياً
    }
  }
}

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

  // فحص وجود VPN حقيقي نشط عبر فحص واجهات الشبكة (tun / ppp).
  // ملاحظة مهمّة: فلتر DNS المحلي (LDF) ينشئ هو نفسه واجهة TUN ضمن النطاق
  // المحجوز 10.111.222.x — نستثنيها كي لا تُحسب خطأً كـ VPN حماية حقيقي
  // (فلترنا لا يشفّر الحركة ولا يخفي IP، فادّعاء التشفير سيكون مضلِّلاً).
  Future<bool> _hasActiveVpn() async {
    try {
      final ifaces = await NetworkInterface.list();
      return ifaces.any((i) {
        final name = i.name.toLowerCase();
        if (!name.contains('tun') && !name.contains('ppp')) return false;
        // تجاهل واجهة فلتر DNS المحلي الخاصة بنا
        final isLocalLdf =
            i.addresses.any((a) => a.address.startsWith('10.111.222.'));
        return !isLocalLdf;
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

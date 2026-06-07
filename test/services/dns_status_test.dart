import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/dns_status.dart';

void main() {
  group('DnsStatus', () {
    test('isEncrypted true for hostname mode', () {
      final status = DnsStatus(mode: DnsMode.hostname, hasActiveVpn: false, hostname: 'one.one.one.one');
      expect(status.isEncrypted, isTrue);
    });

    test('isEncrypted true for opportunistic mode', () {
      final status = DnsStatus(mode: DnsMode.opportunistic, hasActiveVpn: false);
      expect(status.isEncrypted, isTrue);
    });

    test('isEncrypted true when VPN active', () {
      final status = DnsStatus(mode: DnsMode.off, hasActiveVpn: true);
      expect(status.isEncrypted, isTrue);
    });

    test('isEncrypted false when off and no VPN', () {
      final status = DnsStatus(mode: DnsMode.off, hasActiveVpn: false);
      expect(status.isEncrypted, isFalse);
    });

    test('isEncrypted false when unknown', () {
      final status = DnsStatus(mode: DnsMode.unknown, hasActiveVpn: false);
      expect(status.isEncrypted, isFalse);
    });

    test('statusLabel returns correct labels', () {
      expect(DnsStatus(mode: DnsMode.hostname, hasActiveVpn: false, hostname: 'test.com').statusLabel, 'DNS مشفّر (DoH)');
      expect(DnsStatus(mode: DnsMode.opportunistic, hasActiveVpn: false).statusLabel, 'DNS مشفّر (تلقائي)');
      expect(DnsStatus(mode: DnsMode.off, hasActiveVpn: false).statusLabel, 'DNS غير مشفّر');
      expect(DnsStatus(mode: DnsMode.unknown, hasActiveVpn: false).statusLabel, 'حالة DNS غير معروفة');
      expect(DnsStatus(mode: DnsMode.off, hasActiveVpn: true).statusLabel, 'DNS مشفّر (VPN)');
    });

    test('reason is not empty for all modes', () {
      for (final mode in DnsMode.values) {
        final status = DnsStatus(mode: mode, hasActiveVpn: false);
        expect(status.reason, isNotEmpty,
            reason: 'Mode $mode should have a non-empty reason');
      }
    });

    test('suggestedAction is empty when VPN active or hostname set', () {
      final vpn = DnsStatus(mode: DnsMode.off, hasActiveVpn: true);
      expect(vpn.suggestedAction, isEmpty);

      final hostname = DnsStatus(mode: DnsMode.hostname, hasActiveVpn: false, hostname: 'test.com');
      expect(hostname.suggestedAction, isEmpty);
    });

    test('suggestedAction is not empty when DNS off or opportunistic', () {
      final off = DnsStatus(mode: DnsMode.off, hasActiveVpn: false);
      expect(off.suggestedAction, isNotEmpty);

      final opp = DnsStatus(mode: DnsMode.opportunistic, hasActiveVpn: false);
      expect(opp.suggestedAction, isNotEmpty);
    });

    test('unknown factory creates correct default', () {
      final unknown = DnsStatus.unknown();
      expect(unknown.mode, DnsMode.unknown);
      expect(unknown.hasActiveVpn, isFalse);
    });
  });
}

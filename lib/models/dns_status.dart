enum DnsMode {
  off,          // Private DNS معطّل
  opportunistic, // تلقائي بدون تحقق (أوبورتيونستيك)
  hostname,     // مزوّد محدد (مثل cloudflare-dns.com)
  unknown,
}

class DnsStatus {
  final DnsMode mode;
  final String? hostname;
  final bool hasActiveVpn;
  final String? errorMessage;

  const DnsStatus({
    required this.mode,
    this.hostname,
    required this.hasActiveVpn,
    this.errorMessage,
  });

  factory DnsStatus.unknown() => const DnsStatus(
    mode: DnsMode.unknown,
    hasActiveVpn: false,
  );

  bool get isEncrypted =>
    mode == DnsMode.hostname || mode == DnsMode.opportunistic || hasActiveVpn;

  String get statusLabel {
    if (hasActiveVpn) return 'DNS مشفّر (VPN)';
    switch (mode) {
      case DnsMode.hostname:
        return 'DNS مشفّر (DoH)';
      case DnsMode.opportunistic:
        return 'DNS مشفّر (تلقائي)';
      case DnsMode.off:
        return 'DNS غير مشفّر';
      case DnsMode.unknown:
        return 'حالة DNS غير معروفة';
    }
  }

  // السبب الواضح للمستخدم
  String get reason {
    if (hasActiveVpn) {
      return 'الـ VPN النشط يُشفّر استعلاماتك — مزوّد VPN يرى الاستعلامات بدلاً من ISP.';
    }
    switch (mode) {
      case DnsMode.hostname:
        return 'Private DNS مفعّل عبر مزوّد محدد (${hostname ?? 'غير معروف'}) — '
            'استعلاماتك لا يراها مزوّد الإنترنت.';
      case DnsMode.opportunistic:
        return 'Private DNS في الوضع التلقائي — يحاول التشفير لكن بدون تحقق '
            'من هوية الخادم. هذا أفضل من لا شيء، لكن أقل أماناً من مزوّد محدد.';
      case DnsMode.off:
        return 'استعلاماتك للمواقع ترسل بنص واضح — مزوّد الإنترنت (ISP) يرى '
            'كل موقع تزوره حتى لو الاتصال بـ HTTPS.';
      case DnsMode.unknown:
        return 'تعذّر قراءة إعداد DNS. قد يكون الجهاز قديماً أو الإذن غير متوفر.';
    }
  }

  // الإجراء المقترح
  String get suggestedAction {
    if (hasActiveVpn) return '';
    switch (mode) {
      case DnsMode.hostname:
        return '';
      case DnsMode.opportunistic:
        return 'للحماية الكاملة: اذهب للإعدادات ← الشبكة ← Private DNS '
            'واختر "اسم مضيف مزوّد DNS" وأدخل: one.one.one.one';
      case DnsMode.off:
        return 'فعّل Private DNS: الإعدادات ← الشبكة والإنترنت ← Private DNS '
            '← اختر "one.one.one.one" (Cloudflare) أو "dns.quad9.net" (Quad9).';
      case DnsMode.unknown:
        return 'جرّب إعادة تشغيل التطبيق أو تحديث الصفحة.';
    }
  }
}

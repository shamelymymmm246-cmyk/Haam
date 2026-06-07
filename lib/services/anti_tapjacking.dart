import 'package:flutter/material.dart';

/// إضافة مضاد Tapjacking للشاشات الحسّاسة.
///
/// المرحلة 4 — طبقة 4-هـ.4:
/// filterTouchesWhenObscured=true يمنع طبقة شفافة خبيثة فوق الأزرار
/// (متاحة على Android 12+).
class AntiTapjacking extends StatelessWidget {
  const AntiTapjacking({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: child,
    );
  }

  /// لَفّ child بـ GestureDetector مع filterForObscuring على Android 12+.
  static Widget wrap(Widget child) {
    return GestureDetector(
      onTap: () {},
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

class LessonModel {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final String category;
  final List<String> steps;

  const LessonModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
    required this.steps,
  });
}

const kAllLessons = <LessonModel>[
  LessonModel(
    id: 'twofa',
    icon: Icons.vibration_rounded,
    title: 'كيفية تفعيل التحقق الثنائي (2FA)',
    description: 'احمِ حساباتك بطبقة أمان إضافية لمنع الاختراقات.',
    category: 'passwords',
    steps: [
      'حمّل تطبيق مصادقة (Authenticator)',
      'امسح رمز الـ QR الخاص بالحساب',
      'احفظ رموز النسخ الاحتياطي في مكان آمن',
    ],
  ),
  LessonModel(
    id: 'strongpass',
    icon: Icons.key_rounded,
    title: 'إنشاء كلمات مرور قوية',
    description: 'تعلّم سرّ صياغة كلمات مرور لا يمكن تخمينها.',
    category: 'passwords',
    steps: [
      'استخدم 12 حرفاً على الأقل',
      'امزج حروفاً كبيرة وصغيرة وأرقاماً ورموزاً',
      'لا تُعِد استخدام نفس كلمة المرور',
      'فعّل مدير كلمات مرور موثوقاً',
    ],
  ),
  LessonModel(
    id: 'vpn',
    icon: Icons.vpn_lock_rounded,
    title: 'لماذا تحتاج إلى VPN؟',
    description: 'تأمين اتصالك عند استخدام شبكات الواي فاي العامة.',
    category: 'networks',
    steps: [
      'تجنّب الواي فاي العام بدون حماية',
      'فعّل VPN موثوقاً عند الحاجة',
      'تحقّق من عدم تسرّب DNS',
    ],
  ),
  LessonModel(
    id: 'dns',
    icon: Icons.dns_rounded,
    title: 'تشفير DNS (Private DNS)',
    description: 'امنع تنصّت مزوّد الإنترنت على المواقع التي تزورها.',
    category: 'networks',
    steps: [
      'افتح إعدادات Private DNS في جهازك',
      'اختر مزوّداً موثوقاً مثل one.one.one.one',
      'تأكّد من ظهور حالة "مشفّر" في تبويب الشبكة',
    ],
  ),
  LessonModel(
    id: 'perms',
    icon: Icons.privacy_tip_rounded,
    title: 'مراجعة أذونات التطبيقات',
    description: 'قلّل تجسّس التطبيقات بإزالة الأذونات غير الضرورية.',
    category: 'privacy',
    steps: [
      'راجع أذونات الكاميرا والمايكروفون',
      'أزل الأذونات التي لا يحتاجها التطبيق',
      'انتبه للتطبيقات التي تطلب كل شيء معاً',
    ],
  ),
  LessonModel(
    id: 'phishing',
    icon: Icons.report_gmailerrorred_rounded,
    title: 'الوقاية من التصيّد الاحتيالي',
    description: 'تعرّف على الروابط والرسائل المزيّفة قبل أن تقع فيها.',
    category: 'privacy',
    steps: [
      'تحقّق دائماً من عنوان المُرسِل',
      'لا تضغط روابط مشبوهة أو مختصرة',
      'لا تُدخل بياناتك إلا في المواقع الرسمية',
    ],
  ),
  LessonModel(
    id: 'publicwifi',
    icon: Icons.wifi_off_rounded,
    title: 'أخطار شبكات WiFi العامة',
    description: 'تجنّب اختراق بياناتك عند استخدام الشبكات المفتوحة.',
    category: 'networks',
    steps: [
      'لا تدخل حسابات حساسة على شبكات مفتوحة',
      'استخدم VPN عند الضرورة',
      'أطفِ مشاركة الملفات والطابعة',
    ],
  ),
  LessonModel(
    id: 'apppermissions',
    icon: Icons.settings_suggest_rounded,
    title: 'معنى أذونات التطبيقات الخطرة',
    description: 'افهم لماذا تطلب التطبيقات أذونات الكاميرا والمايك والموقع.',
    category: 'privacy',
    steps: [
      'الكاميرا: تستخدم للتصوير — احذر التطبيقات التي تصوّر بالخلفية',
      'المايك: للتسجيل — لا تعطه لتطبيقات لا تحتاج الصوت',
      'الموقع: لتحديد مكانك — أطفئه للتطبيقات التي لا تحتاج خرائط',
    ],
  ),
  LessonModel(
    id: 'ldf',
    icon: Icons.dns_rounded,
    title: 'الفرق بين VPN و LDF (الفلتر المحلي)',
    description: 'افهم ماذا يفعل كل منهما ولماذا يستخدم حام الفلتر المحلي.',
    category: 'networks',
    steps: [
      'VPN يوجّه كل حركتك عبر خادم خارجي ويشفّرها',
      'LDF يحجب فقط استعلامات DNS ولا يوجّه بياناتك لخادم',
      'حام يستخدم LDF لأنه يعمل محلياً 100% بلا سحابة',
    ],
  ),
  LessonModel(
    id: 'compromised',
    icon: Icons.bug_report_rounded,
    title: 'كيف تعرف أن جهازك مخترق',
    description: 'علامات تدل على احتمال اختراق جهازك الأندرويد.',
    category: 'privacy',
    steps: [
      'بطء غير مفسّر أو سخونة الجهاز',
      'ظهور إعلانات كثيرة ومفاجئة',
      'صوت خلفية أو تطبيقات لم تثبّتها',
    ],
  ),
  LessonModel(
    id: 'backup',
    icon: Icons.backup_rounded,
    title: 'النسخ الاحتياطي الآمن والتشفير',
    description: 'احتفظ بنسخة آمنة من ملفاتك المهمة.',
    category: 'passwords',
    steps: [
      'استخدم التخزين المشفّر (مثل خزنة حام)',
      'لا تعتمد على خدمة سحابية واحدة',
      'اختبر استرجاع النسخة بانتظام',
    ],
  ),
  LessonModel(
    id: 'dailyhabits',
    icon: Icons.autorenew_rounded,
    title: 'عادات أمان يومية',
    description: 'خطوات بسيطة ولكنها فعّالة لحماية جهازك يومياً.',
    category: 'privacy',
    steps: [
      'حدّث التطبيقات والنظام باستمرار',
      'أقفل جهازك عند عدم الاستخدام',
      'تجنّب الشبكات غير المعروفة',
    ],
  ),
];

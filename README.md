<div align="center">

<img src="assets/icons/app_icon.png" alt="Haam Logo" width="120" height="120"/>

# حـام — Haam

**درعك الرقمي على أندرويد**

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-5.0%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![No LLM](https://img.shields.io/badge/No%20LLM-100%25%20Local-blueviolet?style=for-the-badge)](https://github.com)

> تطبيق أمان خصوصي يعمل **بالكامل على جهازك** — لا سحابة، لا ذكاء اصطناعي، لا تتبع.

</div>

---

## ما هو حام؟

**حام** هو تطبيق أمان خفيف الوزن لأندرويد يراقب وضعك الأمني الرقمي في الوقت الفعلي ويُنبّهك عند اكتشاف أي تهديد — كل ذلك دون الاتصال بأي خادم خارجي أو نموذج لغوي.

```
الشبكة المفتوحة ← حام يكتشف ← تنبيه فوري + سبب + إجراء
DNS غير مشفّر  ← حام يكتشف ← إرشاد للحل
جهاز غريب     ← حام يكتشف ← تحذير + تفاصيل
تطبيق مشبوه   ← حام يكتشف ← تقرير الأذونات
```

---

## المميزات الرئيسية

| الميزة | الوصف |
|--------|-------|
| 🔐 **قفل بيومتري** | تشغيل محمي ببصمة الإصبع أو PIN، مع إعادة قفل تلقائية عند الخروج للخلفية |
| 🌐 **مراقبة DNS** | كشف استخدام DNS غير المشفّر مع إرشاد فوري للتحويل إلى DoH |
| 📡 **فحص الشبكة** | رصد الأجهزة الجديدة على الشبكة المحلية والشبكات المفتوحة |
| 📱 **تدقيق التطبيقات** | تحديد التطبيقات التي تملك أذونات الكاميرا + الميكروفون + الموقع معاً |
| 🛡️ **كشف الجهاز المروّت** | فحص سلامة الجهاز والكشف عن Root |
| 🧠 **كشف الشذوذ** | خوارزمية Welford لتعلّم السلوك الطبيعي وإنذار الانحرافات |
| 🔔 **إشعارات ذكية** | deduplication + cooldown ساعتين + 4 مستويات حساسية |
| 🌙 **مراقبة في الخلفية** | WorkManager يفحص كل 15 دقيقة دون استنزاف البطارية |

---

## محرك القواعد الأمنية

يُقيّم حام وضعك الأمني عبر **6 قواعد** تُنتج درجة خطر من 0 إلى 100:

```
R1 — شبكة مفتوحة بلا تشفير         │ +35 نقطة
R2 — DNS غير مشفّر                  │ +20 نقطة
R3 — جهاز جديد على الشبكة          │ +10 نقطة
R4 — تطبيق بأذونات تجسّس           │ +25 نقطة
R5 — جهاز مروّت (Rooted)           │ +30 نقطة
R6 — شذوذ في السلوك (AI محلي)      │ +15 نقطة
                                     ─────────
                  درجة الخطر القصوى │ 135 → تُطبَّع على 100
```

### مستويات الخطر

```
🟢  0 – 25    آمن        كل شيء على ما يرام
🟡 26 – 50    تحذير      راجع التفاصيل
🟠 51 – 75    خطر        اتخذ إجراءً
🔴 76+        حرج        تهديد فعلي
```

---

## البنية التقنية

```
haam_counter/
├── lib/
│   ├── models/
│   │   ├── rule_result.dart        # RuleResult + RiskLevel + RiskAssessment
│   │   ├── security_state.dart     # حالة الأمان الموحّدة
│   │   └── dns_status.dart
│   │
│   ├── services/
│   │   ├── rule_engine.dart        # محرك القواعد الست
│   │   ├── anomaly_detector.dart   # Welford online algorithm
│   │   ├── network_collector.dart  # فحص الشبكة والـ DNS
│   │   ├── network_devices_collector.dart
│   │   ├── apps_collector.dart     # مراقبة أذونات التطبيقات
│   │   ├── device_integrity_collector.dart
│   │   ├── background_service.dart # WorkManager كل 15 دق
│   │   ├── notification_manager.dart
│   │   ├── dns_service.dart
│   │   └── auth_service.dart       # local_auth بيومتري/PIN
│   │
│   ├── screens/
│   │   ├── lock_screen.dart        # شاشة القفل الأمنية
│   │   ├── security_overview_screen.dart  # لوحة الأمان الرئيسية
│   │   ├── dns_screen.dart
│   │   └── settings_screen.dart
│   │
│   ├── providers/
│   │   └── security_state_provider.dart   # Provider المركزي
│   │
│   └── widgets/                    # glass_card، security_chip، status_badge...
│
└── android/
    └── app/
        ├── proguard-rules.pro      # حماية release + إخفاء الـ logs
        └── src/main/
            └── kotlin/.../MainActivity.kt  # FLAG_SECURE — يمنع التقاط الشاشة
```

---

## المكتبات المستخدمة

| المكتبة | الغرض |
|---------|-------|
| `provider ^6.1.2` | إدارة الحالة |
| `flutter_secure_storage ^9.2.2` | تخزين مشفّر للبيانات الحساسة |
| `local_auth ^2.3.0` | المصادقة البيومترية |
| `workmanager ^0.9.0` | المراقبة الدورية في الخلفية |
| `flutter_local_notifications ^17.2.4` | الإشعارات الذكية |
| `permission_handler ^11.3.1` | إدارة أذونات أندرويد |
| `google_fonts ^6.2.1` | واجهة مصرية أنيقة |
| `flutter_animate ^4.5.0` | تحريك سلس للعناصر |

---

## متطلبات البناء

```bash
# التحقق من البيئة
flutter doctor

# تثبيت الاعتماديات
flutter pub get

# بناء APK للإصدار
flutter build apk --release

# تشغيل على جهاز متصل
flutter run
```

> **ملاحظة:** تأكد من تفعيل وضع المطوّر على جهازك ومن أن `minSdkVersion` لا يقل عن **21** (Android 5.0).

---

## الأذونات المطلوبة

```xml
ACCESS_WIFI_STATE        — قراءة معلومات الشبكة
ACCESS_NETWORK_STATE     — رصد نوع الاتصال
ACCESS_FINE_LOCATION     — ضروري لـ SSID/ARP scan على Android 9+
QUERY_ALL_PACKAGES       — تدقيق أذونات التطبيقات
USE_BIOMETRIC            — القفل البيومتري
POST_NOTIFICATIONS       — إشعارات الأمان
FOREGROUND_SERVICE       — المراقبة في الخلفية
```

---

## لقطات الشاشة

<div align="center">

| شاشة القفل | لوحة الأمان | فحص DNS |
|:---:|:---:|:---:|
| *(قريباً)* | *(قريباً)* | *(قريباً)* |

</div>

---

## خارطة التطوير

- [x] مرحلة 1 — تشفير DNS (DoH)
- [x] مرحلة 2 — جامعو الإشارات (شبكة، تطبيقات، جهاز)
- [x] مرحلة 3 — محرك القواعد الأمنية (R1–R5)
- [x] مرحلة 4 — المراقبة الخلفية والإشعارات الذكية
- [x] مرحلة 5 — كشف الشذوذ (Welford Algorithm)
- [x] مرحلة 6 — قفل بيومتري + FLAG_SECURE
- [ ] مرحلة 7 — VPN داخلي (WireGuard)

---

## فلسفة التصميم

> **"الأمان الحقيقي لا يحتاج إلى سحابة"**

حام مبني على ثلاثة مبادئ:

1. **الخصوصية أولاً** — كل الحسابات تجري على جهازك، لا شيء يُرسل خارجاً
2. **الشفافية الكاملة** — كل تنبيه يوضّح السبب والإجراء المطلوب
3. **الخفّة** — مراقبة مستمرة دون استنزاف البطارية أو البيانات

---

<div align="center">

**صُنع بـ ❤️ للمستخدم العربي**

[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev)

</div>

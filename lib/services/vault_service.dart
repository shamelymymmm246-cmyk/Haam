import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:haam_counter/models/vault_item.dart';

/// خزنة ملفات مشفّرة محلياً بمعيار AES-256-GCM (تشفير موثَّق).
///
/// المرحلة 4 — طبقة 4-ج (تشفير من الطراز الأعلى):
/// • GCM يوفّر السرية والسلامة معاً (Authenticated Encryption): أي عبث
///   ببايتة واحدة في الملف يُفشِل المصادقة فيُرفض فك التشفير (كشف تلاعب).
/// • مفتاح 256-بت يُولَّد عشوائياً مرة واحدة ويُحفظ في Android Keystore
///   عبر flutter_secure_storage (لا يغادر التخزين الآمن للنظام).
/// • IV عشوائي 12-بايت لكل ملف عبر مولّد آمن (مثالي لـ GCM)، مخزّن في
///   مقدّمة الملف. وسم المصادقة (16 بايت) يُلحق تلقائياً بالنص المشفّر.
/// • البيانات الوصفية في فهرس JSON داخل مجلد معزول خاص بالتطبيق فقط.
class VaultService {
  // مفتاح GCM (v2). نُبقي اسماً منفصلاً عن مفتاح CBC القديم (v1) لئلا
  // يُعاد استخدام مفتاح بين نمطين مختلفين.
  static const _kKeyName = 'vault_aes_gcm_key_v2';
  static const _ivLength = 12; // 96-بت — الطول الموصى به لـ GCM
  static const _storage = FlutterSecureStorage();

  Directory? _dir;
  enc.Encrypter? _encrypter;

  Future<Directory> _vaultDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/haam_vault');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  Future<enc.Encrypter> _enc() async {
    if (_encrypter != null) return _encrypter!;
    var b64 = await _storage.read(key: _kKeyName);
    if (b64 == null) {
      b64 = enc.Key.fromSecureRandom(32).base64; // AES-256
      await _storage.write(key: _kKeyName, value: b64);
    }
    final key = enc.Key.fromBase64(b64);
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    return _encrypter!;
  }

  File _indexFile(Directory dir) => File('${dir.path}/index.json');

  Future<List<VaultItem>> list() async {
    final dir = await _vaultDir();
    final f = _indexFile(dir);
    if (!await f.exists()) return [];
    try {
      final raw = jsonDecode(await f.readAsString()) as List<dynamic>;
      final items = raw
          .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveIndex(List<VaultItem> items) async {
    final dir = await _vaultDir();
    await _indexFile(dir).writeAsString(
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// يشفّر ملفاً من المسار المعطى ويضيفه للخزنة.
  Future<VaultItem> addFile(String sourcePath, String displayName) async {
    final dir = await _vaultDir();
    final encrypter = await _enc();

    final src = File(sourcePath);
    final bytes = await src.readAsBytes();
    final iv = enc.IV.fromSecureRandom(_ivLength);
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final id = '${DateTime.now().microsecondsSinceEpoch}.enc';
    final out = File('${dir.path}/$id');
    // الملف = IV(12 بايت) + النص المشفّر + وسم المصادقة (مُلحق ضمن bytes)
    await out.writeAsBytes([...iv.bytes, ...encrypted.bytes]);

    final ext = displayName.contains('.')
        ? displayName.split('.').last.toLowerCase()
        : '';
    final item = VaultItem(
      id: id,
      name: displayName,
      ext: ext,
      sizeBytes: bytes.length,
      addedAt: DateTime.now(),
      category: VaultItem.categoryForExt(ext),
    );

    final items = await list();
    items.insert(0, item);
    await _saveIndex(items);
    return item;
  }

  /// يفكّ تشفير العنصر إلى ملف مؤقّت ويعيد مساره (لفتحه/معاينته).
  ///
  /// يرمي استثناءً إذا فشلت مصادقة GCM (دليل عبث بالملف المشفّر) — لا
  /// يُعيد بيانات تالفة بصمت.
  Future<String> decryptToTemp(VaultItem item) async {
    final dir = await _vaultDir();
    final encrypter = await _enc();
    final raw = await File('${dir.path}/${item.id}').readAsBytes();

    final iv = enc.IV(raw.sublist(0, _ivLength));
    final cipher = enc.Encrypted(raw.sublist(_ivLength));
    final clear = encrypter.decryptBytes(cipher, iv: iv);

    final tmpBase = await getTemporaryDirectory();
    final tmpDir = Directory('${tmpBase.path}/haam_open');
    if (!await tmpDir.exists()) await tmpDir.create(recursive: true);
    final tmp = File('${tmpDir.path}/${item.name}');
    await tmp.writeAsBytes(clear, flush: true);
    return tmp.path;
  }

  /// يحذف الملف بشكل آمن: يكتب فوقه قبل الحذف (best-effort على flash).
  /// المرحلة 4 — طبقة 4-ج.6 (الحذف الآمن).
  Future<void> _secureDelete(File f) async {
    if (!await f.exists()) return;
    try {
      final len = await f.length();
      if (len > 0 && len < 50 * 1024 * 1024) {
        // اكتب فوق بثلاث تمريرات (آخر تمريرة صفرية)
        final buf1 = Uint8List(len.clamp(0, 4096));
        final buf2 = Uint8List(len.clamp(0, 4096));
        final rng = math.Random.secure();
        for (int i = 0; i < buf1.length; i++) buf1[i] = rng.nextInt(256);
        for (int i = 0; i < buf2.length; i++) buf2[i] = rng.nextInt(256);
        for (final buf in [buf1, buf2, Uint8List(buf1.length)]) {
          final raf = await f.open(mode: FileMode.write);
          for (int written = 0; written < len; written += buf.length) {
            final count = (len - written).clamp(0, buf.length);
            await raf.writeFrom(buf, 0, count);
          }
          await raf.flush();
          await raf.close();
        }
      }
      await f.delete();
    } catch (_) {
      // best-effort — إذا فشلت الكتابة، نحذف عادياً
      await f.delete();
    }
  }

  /// يمسح محتويات بايت بفراغات (zeroize) — لمنع بقاء النسخ في الذاكرة.
  /// المرحلة 4 — طبقة 4-ج.7 (نظافة الذاكرة).
  @pragma('vm:prefer-inline')
  static void zeroizeBytes(Uint8List bytes) {
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  Future<void> delete(VaultItem item) async {
    final dir = await _vaultDir();
    final f = File('${dir.path}/${item.id}');
    await _secureDelete(f);
    // احذف المفتاح المرتبط (المفتاح واحد لكل الخزنة، نُبقي المفتاح للملفات المتبقية)
    final items = await list();
    items.removeWhere((e) => e.id == item.id);
    if (items.isEmpty) {
      // إذا أصبحت الخزنة فارغة، احذف المفتاح أيضاً
      await _storage.delete(key: _kKeyName);
      _encrypter = null;
    }
    await _saveIndex(items);
  }

  /// يحذف الملفات المؤقّتة المفكوكة (تنظيف بعد المعاينة).
  Future<void> clearTemp() async {
    try {
      final tmpBase = await getTemporaryDirectory();
      final tmpDir = Directory('${tmpBase.path}/haam_open');
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    } catch (_) {}
  }
}

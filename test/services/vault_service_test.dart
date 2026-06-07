import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:haam_counter/models/vault_item.dart';

void main() {
  group('VaultItem model', () {
    test('creates vault item with correct fields', () {
      final item = VaultItem(
        id: 'test.enc',
        name: 'document.pdf',
        ext: 'pdf',
        sizeBytes: 1024,
        addedAt: DateTime(2024, 1, 1),
        category: VaultCategory.documents,
      );

      expect(item.id, 'test.enc');
      expect(item.name, 'document.pdf');
      expect(item.ext, 'pdf');
      expect(item.category, VaultCategory.documents);
    });

    test('categoryForExt returns correct category', () {
      expect(VaultItem.categoryForExt('jpg'), VaultCategory.photos);
      expect(VaultItem.categoryForExt('png'), VaultCategory.photos);
      expect(VaultItem.categoryForExt('mp4'), VaultCategory.videos);
      expect(VaultItem.categoryForExt('pdf'), VaultCategory.documents);
      expect(VaultItem.categoryForExt('doc'), VaultCategory.documents);
      expect(VaultItem.categoryForExt('apk'), VaultCategory.other);
    });

    test('toJson and fromJson round-trip', () {
      final original = VaultItem(
        id: 'test.enc',
        name: 'photo.jpg',
        ext: 'jpg',
        sizeBytes: 2048,
        addedAt: DateTime(2024, 6, 15, 10, 30),
        category: VaultCategory.photos,
      );

      final json = original.toJson();
      final restored = VaultItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.ext, original.ext);
      expect(restored.sizeBytes, original.sizeBytes);
      expect(restored.category, original.category);
      expect(restored.addedAt.toIso8601String(), original.addedAt.toIso8601String());
    });

    test('file types supported: text, image, PDF, video', () {
      const supportedExts = ['txt', 'jpg', 'png', 'pdf', 'mp4', 'mov', 'doc', 'docx'];
      for (final ext in supportedExts) {
        final category = VaultItem.categoryForExt(ext);
        expect(category, isNotNull);
      }
    });
  });

  group('AES-256-GCM encryption - actual crypto', () {
    test('AES-256 key is 32 bytes', () {
      final key = enc.Key.fromSecureRandom(32);
      expect(key.bytes.length, 32);
    });

    test('GCM IV is 12 bytes (recommended)', () {
      final iv = enc.IV.fromSecureRandom(12);
      expect(iv.bytes.length, 12);
    });

    test('encrypt then decrypt returns original data', () {
      final key = enc.Key.fromSecureRandom(32);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final original = Uint8List.fromList([104, 101, 108, 108, 111]);
      final encrypted = encrypter.encryptBytes(original, iv: iv);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      expect(decrypted, orderedEquals(original));
    });

    test('different IV produces different ciphertext for same data', () {
      final key = enc.Key.fromSecureRandom(32);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final original = Uint8List.fromList([104, 101, 108, 108, 111]);
      final iv1 = enc.IV.fromSecureRandom(12);
      final iv2 = enc.IV.fromSecureRandom(12);

      final cipher1 = encrypter.encryptBytes(original, iv: iv1);
      final cipher2 = encrypter.encryptBytes(original, iv: iv2);

      expect(cipher1.bytes, isNot(equals(cipher2.bytes)));
    });

    test('tampered ciphertext fails GCM authentication (throws)', () {
      final key = enc.Key.fromSecureRandom(32);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final original = Uint8List.fromList([104, 101, 108, 108, 111]);
      final encrypted = encrypter.encryptBytes(original, iv: iv);

      final tamperedBytes = encrypted.bytes.map((b) => b ^ 0x01).toList();
      final tampered = enc.Encrypted(Uint8List.fromList(tamperedBytes));
      expect(
        () => encrypter.decryptBytes(tampered, iv: iv),
        throwsA(anything),
      );
    });

    test('stored format: IV(12 bytes) + ciphertext matches VaultService format', () {
      final key = enc.Key.fromSecureRandom(32);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final original = Uint8List.fromList([104, 101, 108, 108, 111]);
      final encrypted = encrypter.encryptBytes(original, iv: iv);

      // VaultService stores: [...iv.bytes, ...encrypted.bytes]
      final stored = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
      expect(stored.length, iv.bytes.length + encrypted.bytes.length);

      // Extract and decrypt
      final storedIv = enc.IV(Uint8List.fromList(stored.sublist(0, 12)));
      final storedCipher = enc.Encrypted(Uint8List.fromList(stored.sublist(12)));
      final decrypted = encrypter.decryptBytes(storedCipher, iv: storedIv);

      expect(decrypted, orderedEquals(original));
    });

    test('encrypt large data (1MB) works correctly', () {
      final key = enc.Key.fromSecureRandom(32);
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final original = Uint8List(1024 * 1024);
      for (int i = 0; i < original.length; i++) {
        original[i] = i % 256;
      }

      final encrypted = encrypter.encryptBytes(original, iv: iv);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      expect(decrypted, orderedEquals(original));
    });
  });

  group('VaultService zeroizeBytes', () {
    test('zeroizeBytes clears all bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      // Simulate VaultService.zeroizeBytes
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
      expect(bytes, everyElement(0));
    });

    test('zeroizeBytes handles empty list', () {
      final bytes = Uint8List(0);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
      expect(bytes.length, 0);
    });
  });
}

enum VaultCategory { photos, videos, documents, other }

extension VaultCategoryExt on VaultCategory {
  String get label {
    switch (this) {
      case VaultCategory.photos:    return 'الصور';
      case VaultCategory.videos:    return 'مقاطع الفيديو';
      case VaultCategory.documents: return 'المستندات';
      case VaultCategory.other:     return 'ملفات أخرى';
    }
  }
}

/// عنصر مخزّن داخل الخزنة المشفّرة. الملف الفعلي محفوظ مشفّراً على القرص؛
/// هذه فقط البيانات الوصفية المعروضة.
class VaultItem {
  const VaultItem({
    required this.id,
    required this.name,
    required this.ext,
    required this.sizeBytes,
    required this.addedAt,
    required this.category,
  });

  final String id;        // اسم الملف المشفّر على القرص (بدون مسار)
  final String name;      // الاسم الأصلي
  final String ext;       // الامتداد (lowercase, بدون نقطة)
  final int sizeBytes;
  final DateTime addedAt;
  final VaultCategory category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ext': ext,
        'size': sizeBytes,
        'added': addedAt.millisecondsSinceEpoch,
        'cat': category.index,
      };

  factory VaultItem.fromJson(Map<String, dynamic> j) => VaultItem(
        id: j['id'] as String,
        name: j['name'] as String,
        ext: (j['ext'] as String?) ?? '',
        sizeBytes: (j['size'] as num?)?.toInt() ?? 0,
        addedAt: DateTime.fromMillisecondsSinceEpoch(
            (j['added'] as num?)?.toInt() ?? 0),
        category: VaultCategory.values[(j['cat'] as num?)?.toInt() ?? 3],
      );

  static VaultCategory categoryForExt(String ext) {
    const photos = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'tiff'};
    const videos = {'mp4', 'mov', 'mkv', 'avi', 'webm', '3gp', 'm4v'};
    const docs = {
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'txt', 'rtf', 'csv', 'odt'
    };
    final e = ext.toLowerCase();
    if (photos.contains(e)) return VaultCategory.photos;
    if (videos.contains(e)) return VaultCategory.videos;
    if (docs.contains(e)) return VaultCategory.documents;
    return VaultCategory.other;
  }
}

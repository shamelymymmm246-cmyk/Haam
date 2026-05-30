enum CounterMode {
  threats,
  protected,
  scan,
}

class CounterModel {
  final int count;
  final CounterMode mode;
  final DateTime createdAt;
  final DateTime lastUpdated;

  CounterModel({
    this.count = 0,
    this.mode = CounterMode.protected,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  String get label {
    switch (mode) {
      case CounterMode.threats:
        return 'ثغرة مكتشفة';
      case CounterMode.protected:
        return 'جهاز محمي';
      case CounterMode.scan:
        return 'فحص أمني';
    }
  }

  String get labelPlural {
    switch (mode) {
      case CounterMode.threats:
        return 'ثغرات مكتشفة';
      case CounterMode.protected:
        return 'أجهزة محمية';
      case CounterMode.scan:
        return 'فحوص أمنية';
    }
  }
}

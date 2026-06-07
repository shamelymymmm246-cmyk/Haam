/// حالة فلتر DNS المحلي (LDF) كما تعيدها الطبقة الأصلية.
class LdfStatus {
  const LdfStatus({
    required this.running,
    required this.totalQueries,
    required this.blockedQueries,
  });

  final bool running;
  final int totalQueries;
  final int blockedQueries;

  int get allowedQueries =>
      (totalQueries - blockedQueries).clamp(0, totalQueries);

  factory LdfStatus.idle() =>
      const LdfStatus(running: false, totalQueries: 0, blockedQueries: 0);

  factory LdfStatus.fromMap(Map<dynamic, dynamic> map) => LdfStatus(
        running: map['running'] as bool? ?? false,
        totalQueries: (map['totalQueries'] as num?)?.toInt() ?? 0,
        blockedQueries: (map['blockedQueries'] as num?)?.toInt() ?? 0,
      );
}

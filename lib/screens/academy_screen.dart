import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haam_counter/models/lesson_model.dart';
import 'package:haam_counter/services/app_prefs.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/score_ring.dart';

/// شاشة الأكاديمية — دروس أمنية حقيقية مع قوائم مهام يُحفظ تقدّمها محلياً.
/// مطابقة لتصميم security_academy.
class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

const _filters = <_Filter>[
  _Filter(key: 'all', label: 'الكل'),
  _Filter(key: 'privacy', label: 'الخصوصية'),
  _Filter(key: 'passwords', label: 'كلمات المرور'),
  _Filter(key: 'networks', label: 'الشبكات'),
];

class _Filter {
  const _Filter({required this.key, required this.label});
  final String key;
  final String label;
}

class _AcademyScreenState extends State<AcademyScreen> {
  final Set<String> _done = {};
  String _filter = 'all';
  bool _loading = true;
  bool _darkMode = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _stepKey(String lessonId, int i) => 'acad_${lessonId}_$i';

  Future<void> _load() async {
    final done = <String>{};
    for (final l in kAllLessons) {
      for (int i = 0; i < l.steps.length; i++) {
        final k = _stepKey(l.id, i);
        if (await AppPrefs.getFlag(k)) done.add(k);
      }
    }
    if (!mounted) return;
    setState(() {
      _done
        ..clear()
        ..addAll(done);
      _loading = false;
    });
  }

  void _toggleStep(String lessonId, int i) {
    final k = _stepKey(lessonId, i);
    setState(() {
      if (_done.contains(k)) {
        _done.remove(k);
      } else {
        _done.add(k);
      }
    });
    AppPrefs.setFlag(k, _done.contains(k));
  }

  bool _isLessonComplete(LessonModel l) {
    for (int i = 0; i < l.steps.length; i++) {
      if (!_done.contains(_stepKey(l.id, i))) return false;
    }
    return true;
  }

  int _lessonProgress(LessonModel l) {
    var c = 0;
    for (int i = 0; i < l.steps.length; i++) {
      if (_done.contains(_stepKey(l.id, i))) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    final allLessons = kAllLessons.where((l) {
      if (_filter != 'all' && l.category != _filter) return false;
      if (_query.isNotEmpty) {
        final title = l.title.toLowerCase();
        final desc = l.description.toLowerCase();
        if (!title.contains(_query) && !desc.contains(_query)) return false;
      }
      return true;
    }).toList();

    final completed = kAllLessons.where(_isLessonComplete).length;
    final total = kAllLessons.length;
    final pct = total > 0 ? (completed / total * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        // ─── بطاقة التقدّم ───────────────────────────────────
        GlassCard(
          borderRadius: 26,
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أكاديمية الحماية',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'لقد أكملت $completed من أصل $total دروس',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ScoreRing(
                progress: total > 0 ? completed / total : 0,
                size: 76,
                strokeWidth: 8,
                gradientColors: const [AppColors.secondary],
                center: Text(
                  '$pct%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 14),

        // ─── شريط البحث ──────────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث في الدروس...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              prefixIcon: IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.onSurfaceVariant,
                onPressed: () {
                  _searchCtrl.clear();
                },
              ),
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 14),

        // ─── الفلاتر ────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final selected = f.key == _filter;
              return GestureDetector(
                onTap: () => setState(() => _filter = f.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryContainer
                        : AppColors.glassFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ─── زر وضع القراءة الليلي ──────────────────────────
        Row(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _darkMode = !_darkMode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _darkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ─── الدروس ─────────────────────────────────────────
        if (allLessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                _query.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد دروس',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),

        for (final l in allLessons) ...[
          _LessonCard(
            lesson: l,
            done: _done,
            stepKey: _stepKey,
            complete: _isLessonComplete(l),
            progress: _lessonProgress(l),
            onToggle: (i) => _toggleStep(l.id, i),
            darkMode: _darkMode,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _LessonCard extends StatefulWidget {
  const _LessonCard({
    required this.lesson,
    required this.done,
    required this.stepKey,
    required this.complete,
    required this.progress,
    required this.onToggle,
    this.darkMode = false,
  });

  final LessonModel lesson;
  final Set<String> done;
  final String Function(String, int) stepKey;
  final bool complete;
  final int progress;
  final ValueChanged<int> onToggle;
  final bool darkMode;

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final started = widget.progress > 0;
    final accent = widget.complete ? AppColors.secondary : AppColors.primary;

    final textColor = widget.darkMode
        ? const Color(0xFFB0B8C8)
        : AppColors.onSurface;

    final badge = widget.complete
        ? ('مكتمل', AppColors.secondary)
        : started
            ? ('قيد التنفيذ', AppColors.primary)
            : ('لم يبدأ', AppColors.onSurfaceVariant);

    return GlassCard(
      borderRadius: 26,
      borderColor: widget.complete ? AppColors.secondary.withValues(alpha: 0.3) : null,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(l.icon, color: accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badge.$2.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge.$1,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badge.$2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.complete && !_expanded) ...[
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'تم إكمال هذا الدرس بنجاح',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _expanded = true),
                child: Text(
                  'مراجعة الخطوات',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.primary),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            for (int i = 0; i < l.steps.length; i++) ...[
              _StepRow(
                text: l.steps[i],
                checked: widget.done.contains(widget.stepKey(l.id, i)),
                onTap: () => widget.onToggle(i),
                darkMode: widget.darkMode,
              ),
              if (i != l.steps.length - 1) const SizedBox(height: 10),
            ],
            if (widget.complete) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _expanded = false),
                  child: Text(
                    'إخفاء',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.text,
    required this.checked,
    required this.onTap,
    this.darkMode = false,
  });
  final String text;
  final bool checked;
  final VoidCallback onTap;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final textColor = darkMode
        ? const Color(0xFFB0B8C8)
        : AppColors.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: checked
              ? AppColors.secondary.withValues(alpha: 0.10)
              : AppColors.glassFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.secondary : Colors.transparent,
                border: Border.all(
                  color: checked ? AppColors.secondary : AppColors.primary,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textColor,
                  height: 1.4,
                  decoration:
                      checked ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

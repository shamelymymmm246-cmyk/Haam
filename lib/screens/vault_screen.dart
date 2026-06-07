import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/models/vault_item.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/services/vault_service.dart';
import 'package:haam_counter/theme/app_colors.dart';
import 'package:haam_counter/widgets/glass_card.dart';
import 'package:haam_counter/widgets/score_ring.dart';

/// شاشة الخزنة — ملفات مشفّرة محلياً بـ AES-256. مطابقة لتصميم secure_file_vault.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _vault = VaultService();
  List<VaultItem> _items = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _vault.list();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  int _countOf(VaultCategory c) {
    if (c == VaultCategory.documents) {
      // اعرض "أخرى" ضمن المستندات للتبسيط
      return _items
          .where((e) =>
              e.category == VaultCategory.documents ||
              e.category == VaultCategory.other)
          .length;
    }
    return _items.where((e) => e.category == c).length;
  }

  /// هل الخزنة مقفلة بسبب إشارات تلاعب حرجة؟
  bool _isVaultFrozen(BuildContext context) {
    final integrity = context.read<SecurityStateProvider>().state.deviceIntegrity;
    return integrity?.hasCriticalTamper == true;
  }

  Future<void> _addFile() async {
    if (_busy) return;
    if (_isVaultFrozen(context)) {
      _showFrozenWarning();
      return;
    }
    try {
      final res = await FilePicker.platform.pickFiles();
      final path = res?.files.single.path;
      final name = res?.files.single.name;
      if (path == null || name == null) return;

      setState(() => _busy = true);
      await _vault.addFile(path, name);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأمين الملف وتشفيره داخل الخزنة'),
            backgroundColor: AppColors.secondaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر تأمين الملف'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showFrozenWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الخزنة مُعلّقة احترازياً — رُصد تلاعب في بيئة التشغيل'),
        backgroundColor: AppColors.alertRed,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openItem(VaultItem item) async {
    if (_isVaultFrozen(context)) {
      _showFrozenWarning();
      return;
    }
    try {
      final path = await _vault.decryptToTemp(item);
      await OpenFilex.open(path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الملف')),
        );
      }
    }
  }

  Future<void> _deleteItem(VaultItem item) async {
    await _vault.delete(item);
    await _load();
  }

  void _showItemMenu(VaultItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.container,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.lock_open_rounded, color: AppColors.primary),
              title: Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppColors.onSurface)),
              subtitle: Text(_sizeLabel(item.sizeBytes),
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            const Divider(color: Color(0x14FFFFFF), height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_rounded, color: AppColors.secondary),
              title: Text('فتح (فكّ التشفير مؤقّتاً)',
                  style: GoogleFonts.inter(color: AppColors.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                _openItem(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed),
              title: Text('حذف من الخزنة',
                  style: GoogleFonts.inter(color: AppColors.alertRed)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteItem(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.secondary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 170),
                children: [
                  _HeroCard(total: _items.length)
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 22),

                  // ─── فئات الخزنة ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.description_rounded,
                          color: AppColors.secondary,
                          title: 'المستندات',
                          count: _countOf(VaultCategory.documents),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.image_rounded,
                          color: AppColors.primary,
                          title: 'الصور',
                          count: _countOf(VaultCategory.photos),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CategoryWide(
                    icon: Icons.video_library_rounded,
                    color: AppColors.tertiary,
                    title: 'مقاطع الفيديو',
                    count: _countOf(VaultCategory.videos),
                  ),

                  const SizedBox(height: 26),

                  Text(
                    'الملفات المضافة حديثاً',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_items.isEmpty)
                    _EmptyVault()
                  else
                    for (final item in _items.take(8)) ...[
                      _FileRow(
                        item: item,
                        onTap: () => _showItemMenu(item),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),

        // زر تأمين ملف العائم
        Positioned(
          left: 20,
          right: 20,
          bottom: bottomSafe + 70,
          child: _SecureButton(busy: _busy, onTap: _addFile)
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms),
        ),
      ],
    );
  }
}

String _sizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes ب';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} ك.ب';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
}

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'الآن';
  if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
  if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
  if (d.inDays == 1) return 'أمس';
  return 'قبل ${d.inDays} يوم';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ScoreRing(
            progress: 1.0,
            size: 132,
            strokeWidth: 9,
            gradientColors: const [AppColors.secondary],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded,
                    color: AppColors.secondary, size: 30),
                const SizedBox(height: 4),
                Text(
                  'AES-256',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'الخزنة محمية (Vault Secured)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'أضف ملفاتك ليتم تشفيرها بتقنية AES-256 المتطورة.'
                : '$total ملف مشفّر بتقنية AES-256 المتطورة على جهازك.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
  });
  final IconData icon;
  final Color color;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count ملف',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Icon(Icons.lock_rounded, color: AppColors.secondary, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryWide extends StatelessWidget {
  const _CategoryWide({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
  });
  final IconData icon;
  final Color color;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '$count ملف مخفي',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, color: AppColors.secondary, size: 20),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.item, required this.onTap});
  final VaultItem item;
  final VoidCallback onTap;

  IconData get _icon {
    switch (item.category) {
      case VaultCategory.photos:    return Icons.image_rounded;
      case VaultCategory.videos:    return Icons.movie_rounded;
      case VaultCategory.documents: return Icons.picture_as_pdf_rounded;
      case VaultCategory.other:     return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تم التشفير ${_timeAgo(item.addedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.onSurfaceVariant, size: 40),
          const SizedBox(height: 14),
          Text(
            'الخزنة فارغة',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط "تأمين ملف" لإضافة أول ملف مشفّر إلى خزنتك.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureButton extends StatelessWidget {
  const _SecureButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.35), blurRadius: 24),
          ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_moderator_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'تأمين ملف (Secure a File)',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kartu Neo-Brutalism KASI JADI (border tegas 2px + hard offset shadow).
/// Mempertahankan nama & parameter HairlineCard demi kompatibilitas pemanggil.
class HairlineCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final Offset shadowOffset;

  const HairlineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 16,
    this.onTap,
    this.shadowOffset = const Offset(3, 4),
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final decoration = AppTheme.cardDecoration(
      p,
      color: color,
      borderColor: borderColor,
      radius: radius,
      shadowOffset: shadowOffset,
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }

    return Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Badge status dengan border tegas dan titik indikator opsional.
class StatusDotBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final bool showDot;
  final Color? borderColor;

  const StatusDotBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
    this.showDot = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? p.border,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: p.border, width: 1),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill monospace dengan garis tepi tegas untuk tanggal, versi, bobot, kode.
class MonoPill extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? bgColor;
  final Color? borderColor;

  const MonoPill({
    super.key,
    required this.text,
    this.color,
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final fg = color ?? p.textPrimary;
    final bg = bgColor ?? p.surfaceMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? p.border, width: 1.5),
      ),
      child: Text(
        text,
        style: AppTheme.mono(size: 11, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// Header bagian konten dengan tipografi tebal dan aksi opsional.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: ThemeController.isDark(context) ? p.info : p.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tampilan kosong standar berbingkai Neo-Brutalism.
class ExecutiveEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const ExecutiveEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return HairlineCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border, width: 2),
              boxShadow: [
                BoxShadow(color: p.shadow, offset: const Offset(2, 3)),
              ],
            ),
            child: Icon(icon, size: 28, color: p.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.sansFamily,
              fontSize: 12.5,
              height: 1.45,
              color: p.textSecondary,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            KjNeoButton(
              label: buttonLabel!,
              icon: Icons.add_rounded,
              variant: KjButtonVariant.orange,
              onPressed: onPressed,
            ),
          ],
        ],
      ),
    );
  }
}

/// Bar pemilih periode kerja bulanan berbingkai Neo-Brutalism.
class PeriodSelectorBar extends StatelessWidget {
  final List<dynamic> periods;
  final int? selectedPeriodId;
  final ValueChanged<int> onChanged;
  final Widget? trailing;

  const PeriodSelectorBar({
    super.key,
    required this.periods,
    required this.selectedPeriodId,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final validId = periods.any((item) => item['id'] == selectedPeriodId)
        ? selectedPeriodId
        : (periods.isNotEmpty ? periods.first['id'] as int? : null);

    return HairlineCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      radius: 14,
      shadowOffset: const Offset(2, 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: p.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.border, width: 1.5),
            ),
            child: KjOutlineIcon(
              type: KjIconType.calendar,
              size: 16,
              color: p.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: validId,
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.expand_more_rounded, color: p.textPrimary),
                dropdownColor: p.surfaceElevated,
                style: TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
                hint: Text(
                  'Pilih Periode',
                  style: TextStyle(fontSize: 13, color: p.textMuted),
                ),
                items: periods
                    .map<DropdownMenuItem<int>>(
                      (pr) => DropdownMenuItem<int>(
                        value: pr['id'] as int,
                        child: Text(
                          '${pr['nama_periode'] ?? 'Periode'} (${pr['status'] ?? ''})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Varian warna tombol Neo-Brutalism KASI JADI.
enum KjButtonVariant { orange, teal, blue, secondary, danger }

/// Tombol kapsul Neo-Brutalism ("GAS ISI!", "BERES!", "GAS MASUK!") dengan efek tekan.
class KjNeoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final KjButtonVariant variant;
  final bool isLoading;
  final bool pill;
  final bool expand;
  final EdgeInsetsGeometry? padding;

  const KjNeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.variant = KjButtonVariant.orange,
    this.isLoading = false,
    this.pill = true,
    this.expand = false,
    this.padding,
  });

  @override
  State<KjNeoButton> createState() => _KjNeoButtonState();
}

class _KjNeoButtonState extends State<KjNeoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final disabled = widget.onPressed == null || widget.isLoading;

    final Color bgColor;
    final Color fgColor;
    switch (widget.variant) {
      case KjButtonVariant.orange:
        bgColor = const Color(0xFFFF6B35);
        fgColor = Colors.white;
        break;
      case KjButtonVariant.teal:
        bgColor = const Color(0xFF00B4D8);
        fgColor = Colors.white;
        break;
      case KjButtonVariant.blue:
        bgColor = const Color(0xFF0052FF);
        fgColor = Colors.white;
        break;
      case KjButtonVariant.danger:
        bgColor = p.danger;
        fgColor = Colors.white;
        break;
      case KjButtonVariant.secondary:
        bgColor = p.surface;
        fgColor = p.textPrimary;
        break;
    }

    final radius = widget.pill ? 999.0 : 12.0;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: Matrix4.translationValues(
        _pressed && !disabled ? 1.5 : 0,
        _pressed && !disabled ? 2.0 : 0,
        0,
      ),
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: disabled ? bgColor.withAlpha(150) : bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.border, width: 2),
        boxShadow: (_pressed || disabled)
            ? []
            : [
                BoxShadow(
                  color: p.shadow,
                  offset: const Offset(2, 3),
                  blurRadius: 0,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: fgColor,
              ),
            ),
            const SizedBox(width: 8),
          ] else if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 8),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, size: 17, color: fgColor),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: child,
    );
  }
}

/// Banner pengingat khas Sulteng ("Jangan lupa spill kerjaan hari ini, Jo!").
class KjReminderBanner extends StatefulWidget {
  final String message;
  final String ctaLabel;
  final VoidCallback? onTapCta;
  final VoidCallback? onDismiss;

  const KjReminderBanner({
    super.key,
    this.message = 'Jangan lupa spill kerjaan hari ini, Jo!',
    this.ctaLabel = 'GAS ISI!',
    this.onTapCta,
    this.onDismiss,
  });

  @override
  State<KjReminderBanner> createState() => _KjReminderBannerState();
}

class _KjReminderBannerState extends State<KjReminderBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: ThemeController.isDark(context) ? p.surface : p.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border, width: 2),
        boxShadow: [
          BoxShadow(color: p.shadow, offset: const Offset(3, 4)),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFFF6B35),
                  const Color(0xFFFFA585),
                  _pulse.value * 0.55,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: p.border, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.message,
              style: TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          if (widget.onTapCta != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.onTapCta,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.border, width: 1.5),
                ),
                child: Text(
                  widget.ctaLabel,
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          if (widget.onDismiss != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: widget.onDismiss,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: p.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Monogram SVG KASI JADI ("KJ" + Checklist Oranye) digambar tajam secara vektor.
class KjLogoMark extends StatelessWidget {
  final double width;
  final double height;
  final bool monochromeWhite;

  const KjLogoMark({
    super.key,
    this.width = 40,
    this.height = 34,
    this.monochromeWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _KjLogoPainter(monochromeWhite: monochromeWhite),
      ),
    );
  }
}

class _KjLogoPainter extends CustomPainter {
  final bool monochromeWhite;

  _KjLogoPainter({required this.monochromeWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120.0;
    final sy = size.height / 100.0;
    final s = math.min(sx, sy);
    final dx = (size.width - 120.0 * s) / 2;
    final dy = (size.height - 100.0 * s) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s, s);

    // 1. Huruf K (Biru Elektrik)
    final kPaint = Paint()
      ..color = monochromeWhite ? Colors.white : const Color(0xFF0052FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final kPath = Path()
      ..moveTo(20, 15)
      ..lineTo(20, 85)
      ..moveTo(20, 50)
      ..lineTo(55, 15)
      ..moveTo(35, 35)
      ..lineTo(60, 85);
    canvas.drawPath(kPath, kPaint);

    // 2. Lengkung J (Toska) — ekuivalen SVG M90 45V65C90 78.807 78.807 90 65 90C55.5 90 47.5 84.5 44 76
    final jPaint = Paint()
      ..color = monochromeWhite ? Colors.white : const Color(0xFF00B4D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final jPath = Path()
      ..moveTo(90, 45)
      ..lineTo(90, 65)
      ..cubicTo(90, 78.8071, 78.8071, 90, 65, 90)
      ..cubicTo(55.5, 90, 47.5, 84.5, 44, 76);
    canvas.drawPath(jPath, jPaint);

    // 3. Centang / Checklist (Oranye Hangat) — M62 48L76 62L105 20
    final checkPaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(62, 48)
      ..lineTo(76, 62)
      ..lineTo(105, 20);
    canvas.drawPath(checkPath, checkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KjLogoPainter oldDelegate) =>
      oldDelegate.monochromeWhite != monochromeWhite;
}

/// Jenis ikon garis tangan (Hand-Drawn Outline) navigasi utama KASI JADI.
enum KjIconType { dashboard, dailyLog, analytics, calendar, profile }

class KjOutlineIcon extends StatelessWidget {
  final KjIconType type;
  final double size;
  final Color? color;
  final double strokeWidth;

  const KjOutlineIcon({
    super.key,
    required this.type,
    this.size = 22,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KjOutlineIconPainter(
          type: type,
          color: color ?? p.textPrimary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _KjOutlineIconPainter extends CustomPainter {
  final KjIconType type;
  final Color color;
  final double strokeWidth;

  _KjOutlineIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 24.0;
    canvas.save();
    canvas.scale(s, s);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case KjIconType.dashboard:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 4, 18, 16),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        canvas.drawLine(const Offset(3, 9), const Offset(21, 9), strokePaint);
        canvas.drawLine(const Offset(7, 13), const Offset(10, 13), strokePaint);
        canvas.drawLine(const Offset(7, 16), const Offset(10, 16), strokePaint);
        canvas.drawCircle(const Offset(15.5, 14.5), 2.5, strokePaint);
        canvas.drawLine(
            const Offset(15.5, 14.5), const Offset(17, 13), strokePaint);
        break;

      case KjIconType.dailyLog:
        final clipBody = Path()
          ..moveTo(16, 4)
          ..lineTo(18, 4)
          ..arcToPoint(const Offset(20, 6), radius: const Radius.circular(2))
          ..lineTo(20, 20)
          ..arcToPoint(const Offset(18, 22), radius: const Radius.circular(2))
          ..lineTo(6, 22)
          ..arcToPoint(const Offset(4, 20), radius: const Radius.circular(2))
          ..lineTo(4, 6)
          ..arcToPoint(const Offset(6, 4), radius: const Radius.circular(2))
          ..lineTo(8, 4);
        canvas.drawPath(clipBody, strokePaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 2, 8, 4),
            const Radius.circular(1),
          ),
          strokePaint,
        );
        canvas.drawLine(const Offset(8, 11), const Offset(12, 11), strokePaint);
        canvas.drawLine(const Offset(8, 15), const Offset(11, 15), strokePaint);
        final pen = Path()
          ..moveTo(14.5, 17.5)
          ..lineTo(19, 13)
          ..lineTo(17, 11)
          ..lineTo(12.5, 15.5)
          ..lineTo(12.5, 17.5)
          ..close();
        canvas.drawPath(pen, strokePaint);
        break;

      case KjIconType.analytics:
        // Donut & slice + sparkline trend
        canvas.drawArc(
          const Rect.fromLTWH(2, 2, 20, 20),
          0.35,
          4.45,
          false,
          strokePaint,
        );
        final slice = Path()
          ..moveTo(12, 2)
          ..lineTo(12, 12)
          ..lineTo(22, 12)
          ..arcToPoint(
            const Offset(12, 2),
            radius: const Radius.circular(10),
            clockwise: false,
          );
        canvas.drawPath(slice, strokePaint);
        final spark = Path()
          ..moveTo(7, 15)
          ..lineTo(10, 12)
          ..lineTo(12, 14)
          ..lineTo(16, 10);
        canvas.drawPath(spark, strokePaint);
        break;

      case KjIconType.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 4, 18, 18),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        canvas.drawLine(const Offset(16, 2), const Offset(16, 6), strokePaint);
        canvas.drawLine(const Offset(8, 2), const Offset(8, 6), strokePaint);
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), strokePaint);
        for (final y in [14.0, 18.0]) {
          for (final x in [8.0, 12.0, 16.0]) {
            canvas.drawCircle(Offset(x, y), 1.05, fillPaint);
          }
        }
        break;

      case KjIconType.profile:
        canvas.drawCircle(const Offset(12, 8), 4, strokePaint);
        final shoulders = Path()
          ..moveTo(5, 20)
          ..cubicTo(5, 15.5, 8.1, 13.5, 12, 13.5)
          ..cubicTo(15.9, 13.5, 19, 15.5, 19, 20);
        canvas.drawPath(shoulders, strokePaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KjOutlineIconPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Pattern geometris Tenun / Ketupat Sulawesi Tengah tipis untuk divider atau aksen tepi.
class KjTenunStrip extends StatelessWidget {
  final double height;
  final double opacity;
  final Color? color;

  const KjTenunStrip({
    super.key,
    this.height = 12,
    this.opacity = 0.25,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final effectiveColor = color ?? p.textPrimary;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: _KjTenunPainter(color: effectiveColor),
        ),
      ),
    );
  }
}

class _KjTenunPainter extends CustomPainter {
  final Color color;

  _KjTenunPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final step = size.height <= 10 ? 12.0 : 16.0;
    final cy = size.height / 2;
    final ry = (size.height / 2) - 1.5;
    final rx = step / 2 - 1.0;

    for (double x = step / 2; x < size.width + step; x += step) {
      final diamond = Path()
        ..moveTo(x, cy - ry)
        ..lineTo(x + rx, cy)
        ..lineTo(x, cy + ry)
        ..lineTo(x - rx, cy)
        ..close();
      canvas.drawPath(diamond, paint);
      canvas.drawCircle(Offset(x, cy), 1.1, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _KjTenunPainter oldDelegate) =>
      oldDelegate.color != color;
}

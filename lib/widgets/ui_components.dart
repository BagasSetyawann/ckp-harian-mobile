import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HairlineCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  const HairlineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final box = Container(
      padding: padding,
      decoration: AppTheme.cardDecoration(
        p,
        color: color ?? p.surface,
        borderColor: borderColor ?? p.border,
        radius: radius,
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: box,
      ),
    );
  }
}

class StatusDotBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final bool showDot;

  const StatusDotBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MonoPill extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? bgColor;

  const MonoPill({
    super.key,
    required this.text,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final fg = color ?? p.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor ?? p.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Text(
        text,
        style: AppTheme.mono(size: 11, weight: FontWeight.w600, color: fg),
      ),
    );
  }
}

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
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: p.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Icon(icon, size: 22, color: p.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMuted,
              height: 1.45,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class PeriodSelectorBar extends StatelessWidget {
  final List<dynamic> periods;
  final int? selectedPeriodId;
  final ValueChanged<int?> onChanged;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, size: 17, color: p.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                isDense: true,
                value: selectedPeriodId,
                dropdownColor: p.surface,
                iconEnabledColor: p.textMuted,
                style: TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
                items: periods.map((item) {
                  final map = item as Map<String, dynamic>;
                  final active = map['is_active'] == 1 || map['is_active'] == true || map['status'] == 'aktif';
                  final label = map['nama'] ?? map['nama_periode'] ?? 'Periode';
                  return DropdownMenuItem<int>(
                    value: map['id'] as int,
                    child: Text(
                      '$label${active ? ' • Aktif' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

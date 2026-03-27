// lib/widgets/common.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ── KPI CARD ─────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const KpiCard({
    super.key, required this.label, required this.value,
    required this.color, this.icon, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, color: color, size: 20),
            if (icon != null) const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                style: TextStyle(
                  color: color, fontSize: 22,
                  fontWeight: FontWeight.w900, height: 1.1,
                )),
            ),
            const SizedBox(height: 4),
            Text(label,
              style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
          ],
        ),
      ),
    );
  }
}

// ── STATUS BADGE ─────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String statut;
  const StatusBadge(this.statut, {super.key});

  @override
  Widget build(BuildContext context) {
    final isTerminee = statut == 'terminee';
    final color = isTerminee ? AppColors.green : AppColors.gold;
    final label = isTerminee ? 'Terminée' : 'En cours';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
            style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── SECTION HEADER ───────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 18,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14, fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            )),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ── APP TEXT FIELD ───────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool required;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final VoidCallback? onTap;
  final bool readOnly;

  const AppTextField({
    super.key, required this.label, this.hint,
    this.controller, this.keyboardType, this.required = false,
    this.maxLines = 1, this.inputFormatters,
    this.validator, this.suffix, this.onTap, this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          children: required ? [
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.red))
          ] : [],
        )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// ── PRIMARY BUTTON ───────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool loading;
  final double height;

  const PrimaryButton({
    super.key, required this.label, this.onPressed,
    this.color, this.textColor, this.icon,
    this.loading = false, this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.gold;
    final fg = textColor ?? AppColors.bg;
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
          ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: fg))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label,
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
              ],
            ),
      ),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key, required this.message, required this.icon,
    this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!,
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ── ALERT CHIP ───────────────────────────────────────────
class AlertChip extends StatelessWidget {
  final String nom;
  final double stockActuel;
  final double stockMin;
  final String unite;

  const AlertChip({
    super.key, required this.nom,
    required this.stockActuel, required this.stockMin, required this.unite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(nom,
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text('$stockActuel/$stockMin $unite',
            style: const TextStyle(
              color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── DATE FILTER CHIPS ────────────────────────────────────
class DateFilterChips extends StatefulWidget {
  final Function(String?, String?) onChanged;
  const DateFilterChips({super.key, required this.onChanged});

  @override
  State<DateFilterChips> createState() => _DateFilterChipsState();
}

class _DateFilterChipsState extends State<DateFilterChips> {
  String _selected = 'all';

  static const _periods = [
    ('all', 'Tout'),
    ('today', 'Auj.'),
    ('week', 'Semaine'),
    ('month', 'Mois'),
    ('month3', '3 mois'),
    ('year', 'Année'),
  ];

  void _select(String key) {
    setState(() => _selected = key);
    final now = DateTime.now();
    String? d, f;
    switch (key) {
      case 'today':
        d = f = now.toIso8601String().substring(0, 10);
      case 'week':
        d = now.subtract(Duration(days: now.weekday - 1)).toIso8601String().substring(0, 10);
        f = now.toIso8601String().substring(0, 10);
      case 'month':
        d = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
        f = now.toIso8601String().substring(0, 10);
      case 'month3':
        d = DateTime(now.year, now.month - 2, 1).toIso8601String().substring(0, 10);
        f = now.toIso8601String().substring(0, 10);
      case 'year':
        d = '${now.year}-01-01';
        f = now.toIso8601String().substring(0, 10);
    }
    widget.onChanged(d, f);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _periods.map((p) {
          final isSelected = _selected == p.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _select(p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold.withOpacity(0.15) : AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(p.$2,
                  style: TextStyle(
                    color: isSelected ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

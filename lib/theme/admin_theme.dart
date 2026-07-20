import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AT {
  AT._();

  static const Color background = Color(0xFF0B0C10);
  static const Color card = Color(0xFF16171D);
  static const Color card2 = Color(0xFF111319);
  static const Color border = Color(0xFF2A2B33);
  static const Color border2 = Color(0xFF3B3D46);

  static const Color gold = Color(0xFFE8B923);
  static const Color goldSoft = Color(0x33E8B923);

  static const Color textMuted = Color(0xFF9B9AA3);
  static const Color textFaint = Color(0xFF6F7079);

  static const Color ok = Color(0xFF22C55E);
  static const Color okBg = Color(0x1F22C55E);
  static const Color warn = Color(0xFFF59E0B);
  static const Color err = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color violet = Color(0xFFA78BFA);

  static TextStyle title({
    double size = 18,
    Color color = Colors.white,
    FontWeight w = FontWeight.w700,
  }) {
    return GoogleFonts.playfairDisplay(
      color: color,
      fontSize: size,
      fontWeight: w,
    );
  }

  static TextStyle body({
    double size = 12,
    Color color = textMuted,
    FontWeight w = FontWeight.w400,
  }) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: size,
      fontWeight: w,
    );
  }
}

Color statusColor(String status) {
  final String value = status.trim().toLowerCase();

  if (value.contains('complete') ||
      value.contains('confirmed') ||
      value == 'good') {
    return AT.ok;
  }

  if (value.contains('pending') ||
      value.contains('deposit') ||
      value == 'low') {
    return AT.warn;
  }

  if (value.contains('missing') ||
      value.contains('reject') ||
      value.contains('decline') ||
      value.contains('cancel')) {
    return AT.err;
  }

  if (value.contains('prep') ||
      value.contains('new request')) {
    return AT.info;
  }

  return AT.textMuted;
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AT.title(size: 17),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AT.body(size: 9.5, color: AT.textFaint),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AT.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AT.border),
      ),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AT.body(
          size: 8.5,
          color: color,
          w: FontWeight.w700,
        ),
      ),
    );
  }
}

class OutlinePill extends StatelessWidget {
  const OutlinePill(
    this.label, {
    super.key,
    this.color = AT.textMuted,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Text(
        label,
        style: AT.body(
          size: 8.5,
          color: color,
          w: FontWeight.w600,
        ),
      ),
    );
  }
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.valueColor,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AT.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AT.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              Text(
                value,
                style: AT.title(
                  size: 19,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AT.body(
              size: 10,
              color: Colors.white,
              w: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AT.body(size: 8.5, color: AT.textFaint),
          ),
        ],
      ),
    );
  }
}

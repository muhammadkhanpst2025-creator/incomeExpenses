
import 'package:flutter/material.dart';
import 'models.dart';

const Color ink = Color(0xFF102B2B);
const Color purple = Color(0xFF7C4DFF);
const Color green = Color(0xFF22C997);
const Color red = Color(0xFFFF5268);
const Color canvas = Color(0xFFF4F7EF);
const Color neonBlue = Color(0xFF36C9F4);
const Color neonYellow = Color(0xFFFFD84D);
const Color muted = Color(0xFF78858B);

String money(num value) {
  final negative = value < 0;
  final amount = value.abs().toStringAsFixed(2);
  final parts = amount.split('.');
  final whole = parts[0];
  final buffer = StringBuffer();

  for (var i = 0; i < whole.length; i++) {
    buffer.write(whole[i]);

    final remaining = whole.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  return '${negative ? '-' : ''}Rs ${buffer.toString()}.${parts[1]}';
}

String shortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
    case 'groceries':
      return Icons.restaurant_rounded;
    case 'school':
    case 'education':
    case 'school fees':
      return Icons.school_rounded;
    case 'rent':
      return Icons.home_rounded;
    case 'salary':
      return Icons.payments_rounded;
    case 'travel':
    case 'transport':
      return Icons.directions_car_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'medical':
    case 'health':
      return Icons.medical_services_rounded;
    case 'bank':
      return Icons.account_balance_rounded;
    case 'cash':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

class NeonIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const NeonIconBadge({
    super.key,
    required this.icon,
    this.color = purple,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.75),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final List<Color>? gradientColors;
  final Color outlineColor;
  final double radius;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.gradientColors,
    this.outlineColor = const Color(0x337C4DFF),
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradientColors == null ? color : null,
      gradient: gradientColors == null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors!,
            ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: outlineColor, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: outlineColor.withValues(alpha: 0.14),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

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

class GradientHeader extends StatelessWidget {
  final String title;
  final String amount;
  final Widget? child;

  const GradientHeader({
    super.key,
    required this.title,
    required this.amount,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102F30),
            Color(0xFF214C50),
            Color(0xFF38296A),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0x9979F2D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFC6E9DD),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 18),
            child!,
          ],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AccountBalanceCard extends StatelessWidget {
  final KhataAccount account;
  final VoidCallback? onTap;
  final bool compact;

  const AccountBalanceCard({
    super.key,
    required this.account,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = account.balance < 0;
    final icon = account.isPayable
        ? Icons.arrow_upward_rounded
        : account.isReceivable
            ? Icons.arrow_downward_rounded
            : account.name.toLowerCase().contains('bank')
                ? Icons.account_balance_rounded
                : Icons.account_balance_wallet_rounded;

    final accent = account.isPayable
        ? const Color(0xFFFFB547)
        : account.isReceivable
            ? neonBlue
            : green;

    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 12 : 16),
      outlineColor: accent.withValues(alpha: 0.65),
      gradientColors: [
        accent.withValues(alpha: 0.13),
        Colors.white,
      ],
      child: Row(
        children: [
          NeonIconBadge(
            icon: icon,
            color: accent,
            size: compact ? 42 : 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  money(account.balance),
                  style: TextStyle(
                    color: isNegative ? red : ink,
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

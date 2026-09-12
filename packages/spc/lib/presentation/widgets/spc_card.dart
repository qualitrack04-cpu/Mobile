import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';

/// Kartu putih standar di halaman SPC.
///
/// Mengurus warna, radius, dan shadow. Kalau [onTap] diisi, kartu dibungkus
/// [Material] + [InkWell] supaya efek ripple tetap terlihat: warna latar
/// dipegang [Material], bukan [Container] di dalamnya.
class SpcCard extends StatelessWidget {
  const SpcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isLarge = radius >= 16;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: isLarge ? 10 : 8,
        offset: Offset(0, isLarge ? 4 : 2),
      ),
    ];

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius,
          boxShadow: shadow,
        ),
        child: child,
      );
    }

    return Material(
      color: AppColors.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable brand logo components for Rently
class RentlyLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool transparent;
  final BoxFit fit;

  const RentlyLogo({
    super.key,
    this.width,
    this.height = 70,
    this.transparent = false,
    this.fit = BoxFit.contain,
  });

  /// Full brand logo with mark and "rently FIND YOUR HOME" text
  const RentlyLogo.full({
    super.key,
    this.width,
    this.height = 70,
    this.transparent = false,
    this.fit = BoxFit.contain,
  });

  /// Just the brand mark house + arrow in a square format
  static Widget mark({
    Key? key,
    double size = 44,
    double borderRadius = 12,
    bool transparent = false,
    Color? backgroundColor,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: GenXPalette.cameoWhite),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * 0.7),
        child: Image.asset(
          transparent
              ? 'assets/images/rently_mark_transparent.png'
              : 'assets/images/rently_mark.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.home_rounded,
            color: GenXPalette.midnightBlue,
          ),
        ),
      ),
    );
  }

  /// Large hero card logo used on splash and auth welcome screens
  static Widget heroCard({
    Key? key,
    double size = 88,
    double borderRadius = 22,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * 0.7),
        child: Image.asset(
          'assets/images/rently_mark.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.home_rounded,
            color: GenXPalette.midnightBlue,
            size: 48,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      transparent
          ? 'assets/images/rently_logo_transparent.png'
          : 'assets/images/rently_logo.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, color: GenXPalette.midnightBlue, size: 28),
          SizedBox(width: 8),
          Text(
            'Rently',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: GenXPalette.midnightBlue,
            ),
          ),
        ],
      ),
    );
  }
}

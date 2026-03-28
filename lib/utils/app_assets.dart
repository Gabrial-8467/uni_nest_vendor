import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppAssets {
  // Logo Image
  static const String logoImage = 'assets/images/uninest.jpeg';

  // App Icon (for fallback)
  static const IconData appIcon = Icons.store;

  // Logo dimensions
  static const double logoSizeSmall = 60.0;
  static const double logoSizeMedium = 100.0;
  static const double logoSizeLarge = 140.0;

  // Logo container decoration
  static BoxDecoration getLogoContainerDecoration({
    double borderRadius = 35.0,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }

  // Logo container with gradient (deprecated - keeping for backward compatibility)
  static BoxDecoration getLogoContainerWithGradientDecoration({
    double borderRadius = 25.0,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;
  final bool withGradient;
  final double? borderRadius;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size = AppAssets.logoSizeMedium,
    this.withGradient = false,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final containerDecoration = withGradient
        ? AppAssets.getLogoContainerWithGradientDecoration(
            borderRadius: borderRadius ?? 25.0,
          )
        : AppAssets.getLogoContainerDecoration(
            borderRadius: borderRadius ?? 35.0,
          );

    return Container(
      width: size,
      height: size,
      decoration: containerDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius ?? (withGradient ? 25.0 : 35.0),
        ),
        child: Image.asset(
          AppAssets.logoImage,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image fails to load
            return Container(
              width: size,
              height: size,
              decoration: containerDecoration,
              child: Icon(
                AppAssets.appIcon,
                size: size * 0.5,
                color: withGradient ? AppTheme.textWhite : AppTheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

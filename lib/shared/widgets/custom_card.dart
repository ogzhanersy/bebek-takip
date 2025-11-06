import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/theme_provider.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.gradient,
    this.boxShadow,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final card = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: gradient == null
                ? (color ?? themeProvider.cardBackground)
                : null,
            gradient: gradient,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: border,
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: padding != null
                  ? Padding(padding: padding!, child: child)
                  : child,
            ),
          ),
        );

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            child: card,
          );
        }

        return card;
      },
    );
  }
}

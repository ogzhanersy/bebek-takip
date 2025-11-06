import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ButtonVariant { primary, outline, ghost, destructive }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();
    final buttonHeight = _getHeight();

    Widget buttonChild = isLoading
        ? _buildLoadingWidget()
        : _buildButtonContent(textStyle);

    Widget button = SizedBox(
      height: buttonHeight,
      width: width,
      child: _buildButton(buttonStyle, buttonChild),
    );

    if (margin != null) {
      button = Container(margin: margin, child: button);
    }

    return button;
  }

  Widget _buildButton(ButtonStyle style, Widget child) {
    switch (variant) {
      case ButtonVariant.outline:
        return OutlinedButton(onPressed: onPressed, style: style, child: child);
      case ButtonVariant.ghost:
        return TextButton(onPressed: onPressed, style: style, child: child);
      default:
        return ElevatedButton(onPressed: onPressed, style: style, child: child);
    }
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(text, style: textStyle),
        ],
      );
    }
    return Text(text, style: textStyle);
  }

  Widget _buildLoadingWidget() {
    final color = variant == ButtonVariant.primary
        ? AppColors.primaryForeground
        : AppColors.primary;

    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    final baseStyle = ButtonStyle(
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(_getPadding()),
      minimumSize: WidgetStateProperty.all<Size>(
        Size(44, _getHeight()), // Touch-friendly minimum size
      ),
    );

    switch (variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all<Color>(
            AppColors.primaryForeground,
          ),
          elevation: WidgetStateProperty.all<double>(2),
          shadowColor: WidgetStateProperty.all<Color>(AppColors.buttonShadow),
        );

      case ButtonVariant.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
          foregroundColor: WidgetStateProperty.all<Color>(AppColors.foreground),
          side: WidgetStateProperty.all<BorderSide>(
            const BorderSide(color: AppColors.border),
          ),
          elevation: WidgetStateProperty.all<double>(0),
        );

      case ButtonVariant.ghost:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
          foregroundColor: WidgetStateProperty.all<Color>(AppColors.foreground),
          elevation: WidgetStateProperty.all<double>(0),
        );

      case ButtonVariant.destructive:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            return AppColors.destructive;
          }),
          foregroundColor: WidgetStateProperty.all<Color>(
            AppColors.destructiveForeground,
          ),
          elevation: WidgetStateProperty.all<double>(2),
          shadowColor: WidgetStateProperty.all<Color>(
            AppColors.destructive.withValues(alpha: 0.3),
          ),
        );
    }
  }

  TextStyle _getTextStyle() {
    final fontSize = _getFontSize();
    final fontWeight = FontWeight.w500;

    Color color;
    switch (variant) {
      case ButtonVariant.primary:
        color = AppColors.primaryForeground;
        break;
      case ButtonVariant.destructive:
        color = AppColors.destructiveForeground;
        break;
      default:
        color = AppColors.foreground;
    }

    return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 52;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }
}

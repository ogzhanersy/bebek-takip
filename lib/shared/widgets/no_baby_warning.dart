import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class NoBabyWarning extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const NoBabyWarning({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Center(
      child: Container(
        width: isTablet ? screenSize.width * 0.5 : screenSize.width * 0.85,
        constraints: BoxConstraints(
          maxWidth: 350,
          minHeight: screenSize.height * 0.3,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: isTablet ? 16 : 12),
            // Icon
            Container(
              padding: EdgeInsets.all(isTablet ? 18 : 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.child_care_outlined,
                size: isTablet ? 36 : 28,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: isTablet ? 14 : 10),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 24 : 20,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isTablet ? 8 : 4),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedForeground,
                height: 1.4,
                fontSize: isTablet ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed ?? () => context.go('/add-baby'),
                icon: Icon(Icons.add, size: isTablet ? 22 : 20),
                label: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                        horizontal: isTablet ? 20 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/providers/theme_provider.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? iconPath;
  final IconData? icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconPath,
    this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Koyu tema için gradient'leri değiştir
        Gradient cardGradient;
        if (themeProvider.isDarkMode) {
          // Koyu tema için daha koyu gradient'ler
          switch (title) {
            case 'Uyku':
              cardGradient = const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Koyu mavi
              );
              break;
            case 'Beslenme':
              cardGradient = const LinearGradient(
                colors: [Color(0xFFBE185D), Color(0xFFEC4899)], // Koyu pembe
              );
              break;
            case 'Alt Değişimi':
              cardGradient = const LinearGradient(
                colors: [Color(0xFF166534), Color(0xFF22C55E)], // Koyu yeşil
              );
              break;
            case 'Ölçümler':
              cardGradient = const LinearGradient(
                colors: [Color(0xFF7C2D12), Color(0xFFF97316)], // Koyu turuncu
              );
              break;
            default:
              cardGradient = gradient; // Varsayılan gradient
          }
        } else {
          cardGradient = gradient; // Açık tema için orijinal gradient'ler
        }

        return CustomCard(
          gradient: cardGradient,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconPath != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        iconPath!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 24,
                          );
                        },
                      ),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

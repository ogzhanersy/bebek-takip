import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding sayfalarının içeriği
  final List<Map<String, dynamic>> onboardingPages = [
    {
      'icon': Icons.track_changes_outlined,
      'title': 'Kapsamlı Bebek Takibi',
      'description':
          'Bebeğinizin uyku, beslenme, alt değişimi ve gelişimini kolayca kaydedin ve takip edin. Her anınızı değerli kılın.',
      'gradient': AppColors.babyBlueGradient,
    },
    {
      'icon': Icons.photo_camera_outlined,
      'title': 'Anılar ve Gelişim',
      'description':
          'Bebeğinizin özel anlarını fotoğraflar ve notlarla ölümsüzleştirin. Gelişim kilometre taşlarını takip edin.',
      'gradient': AppColors.babyPinkGradient,
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Akıllı Analizler',
      'description':
          'Detaylı grafikler ve raporlarla bebeğinizin rutinlerini anlayın. Sağlıklı gelişimini destekleyin.',
      'gradient': AppColors.babyGreenGradient,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Onboarding tamamlandığında çağrılacak metod
  Future<void> _onFinishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.homeBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingPages.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(
                      context,
                      onboardingPages[index],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Sayfa göstergeleri (noktalar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingPages.length,
                        (index) => _buildDot(index, context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Son sayfada "Başla" butonu, diğer sayfalarda "Atla" ve "İleri"
                    _currentPage == onboardingPages.length - 1
                        ? CustomButton(
                            text: 'Başla',
                            onPressed: _onFinishOnboarding,
                          )
                        : Row(
                            children: [
                              TextButton(
                                onPressed: _onFinishOnboarding,
                                child: Text(
                                  'Atla',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.mutedForeground,
                                      ),
                                ),
                              ),
                              const Spacer(),
                              CustomButton(
                                text: 'İleri',
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeIn,
                                  );
                                },
                                width: 120,
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Her bir onboarding sayfasının yapısı
  Widget _buildOnboardingPage(
    BuildContext context,
    Map<String, dynamic> pageData,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ana ikon/görsel
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: pageData['gradient'],
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(pageData['icon'], size: 80, color: Colors.white),
          ),
          const SizedBox(height: 48),
          // Başlık
          Text(
            pageData['title'],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Açıklama
          Text(
            pageData['description'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Sayfa göstergesi noktaları
  Widget _buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primary
            : AppColors.mutedForeground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

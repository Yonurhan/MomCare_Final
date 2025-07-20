import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pregnancy_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final LiquidController _liquidController = LiquidController();
  final PageController _pageIndicatorController = PageController();

  @override
  void dispose() {
    _pageIndicatorController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> pageData = [
    {
      "image": "assets/images/screen1.png",
      "title": "Setiap Detak Adalah Cerita",
      "subtitle":
          "Pantau setiap momen berharga dalam perjalanan kehamilan Anda bersama kami.",
      "color": AppTheme.nutritionCardColor,
    },
    {
      "image": "assets/images/screen2.png",
      "title": "Pahami Kesehatan Anda",
      "subtitle":
          "Dapatkan informasi akurat dan tips harian untuk menjaga kesehatan ibu dan bayi.",
      "color": AppTheme.morningCardColor,
    },
    {
      "image": "assets/images/screen3.png",
      "title": "Melahirkan Masa Depan",
      "subtitle":
          "Siapkan diri Anda untuk menjadi ibu yang hebat dengan panduan lengkap dari para ahli.",
      "color": AppTheme.weightCardColor,
    }
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe.builder(
            itemCount: pageData.length,
            liquidController: _liquidController,
            onPageChangeCallback: (page) {
              setState(() {
                _currentPage = page;
                _pageIndicatorController.animateToPage(
                  page,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              });
            },
            itemBuilder: (context, index) {
              return Container(
                width: size.width,
                height: size.height,
                color: pageData[index]['color'],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Image.asset(pageData[index]["image"]!,
                          height: size.height * 0.4),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        children: [
                          FadeInUp(
                            duration: const Duration(milliseconds: 900),
                            child: Text(
                              pageData[index]["title"]!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: AppTheme.primaryTextColor,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInUp(
                            duration: const Duration(milliseconds: 900),
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              pageData[index]["subtitle"]!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.secondaryTextColor,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            preferDragFromRevealedArea: true,
            enableLoop: false,
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _finishOnboarding();
                  },
                  child: Text(
                    "SKIP",
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SmoothPageIndicator(
                  controller: _pageIndicatorController,
                  count: pageData.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppTheme.primaryColor,
                    dotColor: AppTheme.accentColor,
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < pageData.length - 1) {
                      _liquidController.jumpToPage(page: _currentPage + 1);
                    } else {
                      _finishOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _currentPage == pageData.length - 1
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 24),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
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
  // Hanya butuh satu controller sekarang
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Menambahkan properti 'color' untuk membuat kode lebih bersih
  final List<Map<String, dynamic>> pageData = [
    {
      "image": "assets/images/screen1.png",
      "title": "Setiap Detak Adalah Cerita",
      "subtitle":
          "Pantau setiap momen berharga dalam perjalanan kehamilan Anda bersama kami.",
      "color": const Color.fromARGB(255, 255, 255, 255),
    },
    {
      "image": "assets/images/screen2.png",
      "title": "Pahami Kesehatan Anda",
      "subtitle":
          "Dapatkan informasi akurat dan tips harian untuk menjaga kesehatan ibu dan bayi.",
      "color": const Color.fromARGB(255, 255, 255, 255),
    },
    {
      "image": "assets/images/screen3.png",
      "title": "Melahirkan Masa Depan",
      "subtitle":
          "Siapkan diri Anda untuk menjadi ibu yang hebat dengan panduan lengkap dari para ahli.",
      "color": const Color.fromARGB(255, 255, 255, 255),
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Menggunakan PageView untuk animasi geser yang bersih
          PageView.builder(
            controller: _pageController,
            itemCount: pageData.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              // Mengirim controller ke setiap halaman untuk animasi
              return OnboardingPage(
                pageController: _pageController,
                pageData: pageData[index],
                index: index,
              );
            },
          ),
          // Kontrol (Tombol dan Indikator)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol SKIP
                TextButton(
                  onPressed: () => _finishOnboarding(),
                  child: Text(
                    "SKIP",
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Indikator Halaman
                SmoothPageIndicator(
                  controller:
                      _pageController, // Terhubung langsung, tidak perlu sinkronisasi manual
                  count: pageData.length,
                  effect: WormEffect(
                    // Efek yang elegan dan ringan
                    activeDotColor: AppTheme.primaryColor,
                    dotColor: AppTheme.accentColor,
                    dotHeight: 12,
                    dotWidth: 12,
                  ),
                ),
                // Tombol NEXT / FINISH
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == pageData.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
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

// Widget terpisah untuk setiap halaman dengan animasi parallax
class OnboardingPage extends StatelessWidget {
  final PageController pageController;
  final Map<String, dynamic> pageData;
  final int index;

  const OnboardingPage({
    Key? key,
    required this.pageController,
    required this.pageData,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double pageOffset = 0;
        if (pageController.position.haveDimensions) {
          pageOffset = pageController.page! - index;
        }

        // Faktor untuk membuat gambar bergerak lebih lambat (efek parallax)
        double imageTranslate = pageOffset * (size.width / 2);

        // Faktor untuk skala dan fade out
        double scale = max(0.7, 1 - pageOffset.abs() * 0.5);
        double opacity = max(0.0, 1 - pageOffset.abs() * 1.5);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size.width,
              height: size.height,
              color: pageData['color'],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(imageTranslate, 0),
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Image.asset(pageData["image"],
                          height: size.height * 0.4),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 900),
                          child: Text(
                            pageData["title"],
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: AppTheme.primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInUp(
                          duration: const Duration(milliseconds: 900),
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            pageData["subtitle"],
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.secondaryTextColor,
                                      height: 1.5,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

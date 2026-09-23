import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Find Your\nPerfect Home',
      description:
          'Discover verified apartments, rooms and houses that fit your lifestyle and budget.',
      icon: Icons.apartment_rounded,
      badgeText: 'Verified Homes',
    ),
    OnboardingItem(
      title: 'Safe & Secure',
      description:
          'Verified listings, secure payments and trusted users for a worry-free rental experience.',
      icon: Icons.verified_user_rounded,
      badgeText: 'Protected Guarantee',
    ),
    OnboardingItem(
      title: 'Manage Everything\nin One Place',
      description:
          'From rental requests to maintenance, notices and rent records — all in one app.',
      icon: Icons.devices_rounded,
      badgeText: 'All-In-One Hub',
    ),
  ];

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Container matching Picture 1
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: GenXPalette.cameoWhite, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: GenXPalette.whippedCream,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Icon(
                                  item.icon,
                                  size: 80,
                                  color: GenXPalette.midnightBlue,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: GenXPalette.textDark,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: GenXPalette.textMuted,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Bar matching Picture 1 Screens 2, 3, 4:
            // "Skip" on left, 3 dots in center, circular arrow button on right
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    onPressed: _goToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: GenXPalette.textMuted,
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Skip'),
                  ),

                  // 3 Dot Page Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_items.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? GenXPalette.midnightBlue : GenXPalette.cameoWhite,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Circular Next Button with Arrow
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: GenXPalette.midnightBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: GenXPalette.midnightBlue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final String badgeText;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
  });
}

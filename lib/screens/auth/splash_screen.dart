import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rently_logo.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const heroImageUrl =
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80';

    return Scaffold(
      backgroundColor: GenXPalette.midnightBlue,
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        },
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                heroImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: GenXPalette.midnightBlue,
                ),
              ),
            ),

            // Dusk Gradient Overlay matching Picture 1 Screen 1
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GenXPalette.midnightBlue.withValues(alpha: 0.85),
                      GenXPalette.midnightBlue.withValues(alpha: 0.65),
                      GenXPalette.midnightBlue.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Top Status Bar Area & Center Branding
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Rently Brand Icon & Title (Picture 1 Screen 1)
                  Center(
                    child: RentlyLogo.heroCard(size: 96),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Rently',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Rent  •  Manage  •  Live Better',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),

                  const Spacer(),

                  // Bottom Card: "Your next home is just a tap away."
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Your next home\nis just a tap away.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: GenXPalette.textDark,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: GenXPalette.midnightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
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

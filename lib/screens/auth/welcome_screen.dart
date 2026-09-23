import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../widgets/rently_logo.dart';

// Generation X Color Palette (Picture 2)
class GenXPalette {
  static const Color whippedCream = Color(0xFFF7F5EE); // DC-001: Warm soft white/cream
  static const Color cameoWhite = Color(0xFFE5E7E2);   // MQ3-32: Crisp pale neutral white
  static const Color vineLeaf = Color(0xFF3B4D3C);     // N400-7: Rich deep forest vine leaf green
  static const Color midnightBlue = Color(0xFF38454D); // N480-7: Deep slate midnight blue
  static const Color textDark = Color(0xFF1E2830);
  static const Color textMuted = Color(0xFF6B7680);
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFeatures() {
    final context = _featuresKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Hero Section matching Picture 1 with GenX colors
            _buildHeroSection(),

            // Lower Section containing Feature Cards and Auth CTA
            Container(
              color: GenXPalette.whippedCream,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 4 Feature Cards in a 2x2 responsive layout
                  Padding(
                    key: _featuresKey,
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: _buildFeaturesGrid(),
                  ),

                  const SizedBox(height: 36),

                  // Bottom "Ready to get started?" Call To Action section
                  _buildBottomAuthCta(),

                  const SizedBox(height: 20),

                  // Decorative skyline outline at very bottom
                  _buildSkylineFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hero Section with dusk apartment architecture, logo, headline, and buttons
  Widget _buildHeroSection() {
    const heroImageUrl =
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80';

    return ClipPath(
      clipper: _WaveHeaderClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: GenXPalette.midnightBlue,
        ),
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

            // Dusk Midnight Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GenXPalette.midnightBlue.withValues(alpha: 0.88),
                      GenXPalette.midnightBlue.withValues(alpha: 0.72),
                      GenXPalette.vineLeaf.withValues(alpha: 0.65),
                      GenXPalette.midnightBlue.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 54),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Rently Logo + Header text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo & Brand
                        Row(
                          children: [
                            RentlyLogo.mark(size: 38, borderRadius: 10),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rently',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Rent  •  Manage  •  Live Better',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Right subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Your Home',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            Text(
                              'Management, Simplified',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 36,
                              height: 2,
                              decoration: BoxDecoration(
                                color: GenXPalette.cameoWhite,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 44),

                    // Big Headline: "Find Your Perfect Home"
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Find Your\n',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Perfect ',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: GenXPalette.cameoWhite,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const TextSpan(
                            text: 'Home',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Subtitle text
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'Rently makes renting easier for tenants and landlords. Find, manage, and maintain your home — all in one place.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Two CTA Buttons (Get Started & Learn More)
                    Row(
                      children: [
                        // Get Started solid pill button
                        ElevatedButton(
                          onPressed: _navigateToRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GenXPalette.vineLeaf,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Get Started',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Learn More transparent outlined button
                        OutlinedButton(
                          onPressed: _scrollToFeatures,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text(
                            'Learn More',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4 Feature Cards (2x2 Grid)
  Widget _buildFeaturesGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.home_outlined,
                iconColor: GenXPalette.vineLeaf,
                iconBg: GenXPalette.cameoWhite.withValues(alpha: 0.6),
                title: 'Find Apartments',
                subtitle: 'Browse verified listings and find your ideal space.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.description_outlined,
                iconColor: GenXPalette.midnightBlue,
                iconBg: const Color(0xFFE2EBE5),
                title: 'Manage Requests',
                subtitle: 'Submit rental or maintenance requests with ease.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.shield_outlined,
                iconColor: GenXPalette.midnightBlue,
                iconBg: const Color(0xFFE5E9EE),
                title: 'Secure & Reliable',
                subtitle: 'Your data and payments are always protected.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFFC07028),
                iconBg: const Color(0xFFFBEEDB),
                title: 'Stay Updated',
                subtitle: 'Get the latest notices, reminders and announcements.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Feature Card Widget
  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GenXPalette.cameoWhite),
        boxShadow: [
          BoxShadow(
            color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: GenXPalette.textDark,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: GenXPalette.textMuted,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Bottom Auth Call-to-action
  Widget _buildBottomAuthCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Text(
            'Ready to get started?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GenXPalette.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Join Rently today and experience a smarter\nway to rent and manage your home.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: GenXPalette.textMuted,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              // Sign Up Solid Pill Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GenXPalette.midnightBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Log In Outlined Button
              Expanded(
                child: OutlinedButton(
                  onPressed: _navigateToLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GenXPalette.midnightBlue,
                    side: const BorderSide(color: GenXPalette.midnightBlue, width: 1.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Decorative skyline at the very bottom
  Widget _buildSkylineFooter() {
    return SizedBox(
      height: 48,
      child: CustomPaint(
        painter: _SkylinePainter(),
        size: const Size(double.infinity, 48),
      ),
    );
  }
}

// Custom Clipper for the smooth wavy transition between Hero and features
class _WaveHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);

    final firstControlPoint = Offset(size.width * 0.25, size.height - 5);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height - 35);
    final secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Subtle skyline silhouette painter for the bottom decoration
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GenXPalette.cameoWhite.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = GenXPalette.cameoWhite.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    double x = 0;
    while (x < size.width) {
      final h = 14.0 + (x * 13) % 22;
      path.lineTo(x, size.height - h);
      path.lineTo(x + 16, size.height - h);
      path.lineTo(x + 16, size.height);
      x += 24;
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

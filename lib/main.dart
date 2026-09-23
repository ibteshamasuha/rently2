import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RentlyApp());
}

class RentlyApp extends StatelessWidget {
  const RentlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Generation X Color Palette (Picture 2)
    const midnightBlue = Color(0xFF38454D); // N480-7 Midnight Blue
    const vineLeaf = Color(0xFF3B4D3C);     // N400-7 Vine Leaf
    const whippedCream = Color(0xFFF7F5EE); // DC-001 Whipped Cream
    const cameoWhite = Color(0xFFE5E7E2);   // MQ3-32 Cameo White

    return MaterialApp(
      title: 'Rently',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: midnightBlue,
          primary: midnightBlue,
          secondary: vineLeaf,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: whippedCream,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: whippedCream,
          foregroundColor: midnightBlue,
          titleTextStyle: TextStyle(
            color: midnightBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: cameoWhite, width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: midnightBlue,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: midnightBlue,
              );
            }
            return const TextStyle(fontSize: 12, color: Color(0xFF8C93A0));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Color(0xFF8C93A0));
          }),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

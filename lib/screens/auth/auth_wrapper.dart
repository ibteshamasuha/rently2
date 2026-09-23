import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../landlord/landlord_main_screen.dart';
import '../tenant/tenant_main_screen.dart';
import 'splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Connecting to Rently...');
        }

        final firebaseUser = authSnapshot.data;

        // If not authenticated, display Splash Screen (Screen 1 in Picture 1)
        if (firebaseUser == null) {
          return const SplashScreen();
        }

        // Authenticated: Stream Firestore UserModel
        return StreamBuilder<UserModel?>(
          stream: authService.streamUserModel(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(message: 'Loading your dashboard...');
            }

            final userModel = userSnapshot.data;

            if (userModel == null) {
              // Safety fallback: auto-provision user model if somehow missing
              return FutureBuilder<UserModel>(
                future: authService.signIn(
                  email: firebaseUser.email ?? 'user@rently.com',
                  password: '',
                ).catchError((_) {
                  // Fallback in-memory
                  return UserModel(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email ?? '',
                    name: firebaseUser.displayName ?? 'Rently User',
                    role: 'tenant',
                  );
                }),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return TenantMainScreen(currentUser: snapshot.data!);
                  }
                  return const _LoadingScreen(message: 'Setting up your profile...');
                },
              );
            }

            // Route dynamically based on user role
            if (userModel.isAdmin) {
              return AdminDashboardScreen(currentUser: userModel);
            } else if (userModel.isLandlord && !userModel.isBoth) {
              return LandlordMainScreen(currentUser: userModel);
            } else {
              // Default to Tenant screen (users with role 'both' have access to tenant + landlord actions)
              return TenantMainScreen(currentUser: userModel);
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: GenXPalette.cameoWhite),
                boxShadow: [
                  BoxShadow(
                    color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.home_rounded, size: 48, color: GenXPalette.midnightBlue),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: GenXPalette.midnightBlue),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: GenXPalette.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

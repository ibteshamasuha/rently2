import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../landlord/landlord_main_screen.dart';
import '../tenant/tenant_main_screen.dart';
import 'welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen(message: 'Connecting to Rently...');
        }

        final firebaseUser = authSnapshot.data;

        // If not logged in, show Welcome / Landing Screen from Picture 1
        if (firebaseUser == null) {
          return const WelcomeScreen();
        }

        // User is logged in, stream their Firestore document to get real-time role
        return StreamBuilder<UserModel?>(
          stream: authService.streamUserModel(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen(message: 'Loading your profile...');
            }

            final userModel = userSnapshot.data;

            if (userModel == null) {
              // Document missing or error
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 54, color: Colors.amber),
                        const SizedBox(height: 16),
                        const Text(
                          'User Profile Not Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your login was successful, but no Firestore document exists at users/${firebaseUser.uid}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => authService.signOut(),
                          child: const Text('Return to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Route dynamically based on role from Firestore
            if (userModel.isLandlord) {
              return LandlordMainScreen(currentUser: userModel);
            } else if (userModel.isAdmin) {
              return AdminDashboardScreen(currentUser: userModel);
            } else {
              return TenantMainScreen(currentUser: userModel);
            }
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  final String message;

  const _SplashScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.apartment_rounded, size: 56, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../landlord/landlord_main_screen.dart';
import '../tenant/tenant_main_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Checking authentication...');
        }

        final firebaseUser = authSnapshot.data;

        // If not authenticated, display LoginScreen
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // Authenticated: Stream Firestore UserModel for the authenticated user's exact UID
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            // 1. Loading state while Firestore is retrieving the user role
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(message: 'Verifying user permissions...');
            }

            // 2. Firestore temporarily fails / error state
            if (userSnapshot.hasError) {
              return Scaffold(
                backgroundColor: GenXPalette.whippedCream,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 54, color: GenXPalette.danger),
                        const SizedBox(height: 16),
                        const Text(
                          'Connection Error',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Could not load profile from database: ${userSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: GenXPalette.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => authService.signOut(),
                          child: const Text('Sign Out & Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // 3. Document does not exist in Firestore
            final doc = userSnapshot.data;
            if (doc == null || !doc.exists || doc.data() == null) {
              return Scaffold(
                backgroundColor: GenXPalette.whippedCream,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 54, color: GenXPalette.warning),
                        const SizedBox(height: 16),
                        const Text(
                          'Profile Not Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GenXPalette.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No user document found at users/${firebaseUser.uid}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: GenXPalette.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => authService.signOut(),
                              child: const Text('Sign Out'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final newUser = UserModel(
                                  uid: firebaseUser.uid,
                                  email: firebaseUser.email ?? '',
                                  name: firebaseUser.displayName ?? 'User',
                                  role: 'tenant',
                                  createdAt: DateTime.now(),
                                );
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(firebaseUser.uid)
                                    .set(newUser.toMap());
                              },
                              child: const Text('Create Profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // 4. Role detection from Firestore
            final userModel = UserModel.fromMap(doc.data()!, doc.id);
            final role = userModel.normalizedRole;

            if (role == 'admin') {
              return AdminDashboardScreen(currentUser: userModel);
            } else if (role == 'landlord') {
              return LandlordMainScreen(currentUser: userModel);
            } else {
              // Default to Tenant screen (handles 'tenant', 'both', or any other valid fallback)
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

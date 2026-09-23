import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserModel(user.uid);
  }

  Future<UserModel?> getUserModel(String uid) async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> streamCurrentUserModel() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return streamUserModel(user.uid);
  }

  Stream<UserModel?> streamUserModel(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, uid);
    });
  }

  /// Safely update allowed profile fields of the currently authenticated user.
  /// Prevents changing role, email, uid, or timestamps.
  Future<void> updateCurrentUserProfile({String? name, String? phone}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (phone != null) {
      updates['phone'] = phone.trim();
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim());
      }
    }
  }

  /// Sign In with human-readable error messages
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();

      if (cleanEmail.isEmpty) throw 'Please enter your email or phone.';
      if (cleanPassword.isEmpty) throw 'Please enter your password.';

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = userCredential.user;
      if (user == null) throw 'Authentication failed. Please try again.';

      // Attempt to retrieve existing profile from Firestore
      final docSnap = await _firestore.collection('users').doc(user.uid).get();

      if (docSnap.exists && docSnap.data() != null) {
        return UserModel.fromMap(docSnap.data()!, user.uid);
      }

      // Only if the document is genuinely missing in Firestore, create default tenant profile
      final defaultModel = UserModel(
        uid: user.uid,
        email: user.email ?? cleanEmail,
        name: user.displayName ?? cleanEmail.split('@')[0],
        role: 'tenant',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(defaultModel.toMap());
      return defaultModel;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Sign Up with role support ('tenant', 'landlord', 'both')
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'tenant', 'landlord', or 'both'
    String? phone,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();
      final cleanName = name.trim();
      final cleanRole = role.trim().toLowerCase();

      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (!emailRegex.hasMatch(cleanEmail)) {
        throw 'Please enter a syntactically valid email address (e.g. name@domain.com).';
      }

      if (!['tenant', 'landlord', 'both'].contains(cleanRole)) {
        throw 'Invalid role selected: $role';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = userCredential.user;
      if (user == null) throw 'Registration failed. Please try again.';

      await user.updateDisplayName(cleanName);

      // Trigger Firebase email verification (Requirement 9)
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Do not fail signup if verification email delivery fails temporarily
      }

      final newUser = UserModel(
        uid: user.uid,
        email: cleanEmail,
        name: cleanName,
        role: cleanRole,
        phone: phone?.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final cleanEmail = email.trim();
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        throw 'Please enter a valid email address.';
      }
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Map Firebase Auth codes to clear, friendly user messages
  String _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again in a few minutes.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact administrator.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }
}

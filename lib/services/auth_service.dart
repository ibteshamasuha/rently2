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
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> streamUserModel(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, uid);
    });
  }

  Future<UserModel> signIn({required String email, required String password}) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user == null) throw Exception('Authentication failed.');

    final userModel = await getUserModel(user.uid);
    if (userModel == null) {
      throw Exception('User profile not found in database.');
    }
    return userModel;
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'tenant' or 'landlord'
    String? phone,
  }) async {
    if (!['tenant', 'landlord'].contains(role)) {
      throw Exception('Invalid role selected: $role');
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user == null) throw Exception('Registration failed.');

    final newUser = UserModel(
      uid: user.uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      phone: phone?.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
    return newUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

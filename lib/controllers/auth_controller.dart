import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user
  Future<String?> register({
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    try {
      // Check if phone already exists
      var existingUsers = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .get();

      if (existingUsers.docs.isNotEmpty) {
        return 'Phone number already registered';
      }

      // Create auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email.trim(),
          phone: phone.trim(),
          username: username.trim(),
        );

        // Save user info to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        print("User created and data saved: ${user.uid}");
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration Failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Login user using email or phone + password
  Future<String?> login({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier.trim();

      // If identifier is phone, look up email
      if (RegExp(r'^\+?\d{10,}$').hasMatch(identifier)) {
        var result = await _firestore
            .collection('users')
            .where('phone', isEqualTo: identifier.trim())
            .limit(1)
            .get();

        if (result.docs.isEmpty) {
          return 'No user found with this phone number';
        }

        email = result.docs.first['email'];
      }

      // Login with email/password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login Failed';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get currently signed-in user
  User? get currentUser => _auth.currentUser;
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final _auth = FirebaseAuth.instance;

  // Sign up method
  Future<UserCredential> signUp(String name, String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Set the user role and additional info (name, email) in Firestore
    await _setUserDetails(userCredential.user!.uid, name, email); 
    return userCredential;
  }

  // Sign in method
  Future<UserCredential> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  }

  // Get the role of the current user
  Future<String> getUserRole(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['role']; // Assumes 'role' is a field in the user's document
    } else {
      return 'user'; // Default to 'user' if the document doesn't exist
    }
  }

  // Set user details (name, email, and role) in Firestore
  Future<void> _setUserDetails(String userId, String name, String email) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'role': 'user', // Default role
      'name': name,
      'email': email,
      'createdAt': Timestamp.now(),
    });
  }
}
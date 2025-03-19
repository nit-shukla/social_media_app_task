import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  
  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();
  
  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword(
    String email, 
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;
      
      if (user != null) {
        // Create user in Firestore
        await _firestoreService.createUser(UserModel(
          id: user.uid,
          email: email,
          username: username,
        ));
      }
      
      notifyListeners();
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      notifyListeners();
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
  
  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      
      if (user != null) {
        // Check if user exists in Firestore
        bool exists = await _firestoreService.userExists(user.uid);
        
        if (!exists) {
          // Create user in Firestore
          await _firestoreService.createUser(UserModel(
            id: user.uid,
            email: user.email ?? '',
            username: user.displayName ?? 'User${user.uid.substring(0, 5)}',
            photoUrl: user.photoURL,
          ));
        }
      }
      
      notifyListeners();
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }
} 
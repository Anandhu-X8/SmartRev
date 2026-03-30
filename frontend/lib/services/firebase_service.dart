import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Store/update user in Firestore
    final user = userCredential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  /// Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  /// Get the current user's ID token for backend authentication
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Save topic to Firestore (flat collection, matches backend structure)
  Future<void> saveTopic(String userId, Map<String, dynamic> topicData) async {
    await _firestore
        .collection('topics')
        .doc(topicData['id'])
        .set({...topicData, 'user_id': userId}, SetOptions(merge: true));
  }

  /// Get topics from Firestore (flat collection, filtered by user_id)
  Future<List<Map<String, dynamic>>> getTopics(String userId) async {
    final snapshot = await _firestore
        .collection('topics')
        .where('user_id', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Delete topic from Firestore (flat collection)
  Future<void> deleteTopic(String userId, String topicId) async {
    await _firestore.collection('topics').doc(topicId).delete();
  }

  /// Save revision result to Firestore (flat collection, matches backend structure)
  Future<void> saveRevisionResult(
    String userId,
    Map<String, dynamic> resultData,
  ) async {
    await _firestore.collection('revision_history').add({
      ...resultData,
      'user_id': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

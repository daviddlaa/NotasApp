import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener usuario actual
  static User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión con Google (usando GoogleSignIn para Android/iOS)
  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'https://www.googleapis.com/auth/plus.login'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        return null;
      }

      // Obtain the auth details from Google Sign In
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }

  // Iniciar sesión con correo y contraseña
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error en signInWithEmail: $e');
      return null;
    }
  }

  // Registrarse con correo y contraseña
  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error en signUpWithEmail: $e');
      return null;
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Also sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      print('Error en signOut: $e');
    }
  }

  // Verificar si está autenticado
  static bool get isAuthenticated => _auth.currentUser != null;
}

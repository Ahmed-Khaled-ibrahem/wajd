import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';
import 'auth_services.dart';
import 'firestore_services.dart';

// Auth Controller
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(AuthInitial()) {
    _init();
  }

  AuthService get _authService => _ref.read(authServiceProvider);

  FirestoreService get _firestoreService => _ref.read(firestoreServiceProvider);

  LocalStorageService get _localStorage => _ref.read(localStorageProvider);

  Future<void> _init() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserProfile(user.uid);
    } else {
      // Try to load from local storage
      final cachedProfile = await _localStorage.getUserProfile();
      if (cachedProfile != null) {
        state = AuthAuthenticated(cachedProfile);
      } else {
        state = const AuthUnauthenticated();
      }
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      state = const AuthLoading();

      // Try to fetch from Firestore
      final profile = await _firestoreService.getUserProfile(userId);

      if (profile != null) {
        // Save to local storage
        await _localStorage.saveUserProfile(profile);
        state = AuthAuthenticated(profile);
      } else {
        state = const AuthError('Profile not found');
      }
    } catch (e) {
      // If offline, try to load from local storage
      final cachedProfile = await _localStorage.getUserProfile();
      if (cachedProfile != null && cachedProfile.userId == userId) {
        state = AuthAuthenticated(cachedProfile);
      } else {
        state = AuthError(e.toString());
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AuthLoading();
      final credential = await _authService.signInWithEmail(email, password);
      await _loadUserProfile(credential.user!.uid);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> createAccount(
    String email,
    String password,
    UserProfile profile,
  ) async {
    try {
      state = const AuthLoading();
      final credential = await _authService.createAccount(email, password);

      // Create profile in Firestore
      final newProfile = profile.copyWith(userId: credential.user!.uid);
      await _firestoreService.createUserProfile(
        credential.user!.uid,
        newProfile,
      );

      // Save to local storage
      await _localStorage.saveUserProfile(newProfile);
      state = AuthAuthenticated(newProfile);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> sendMagicLink(String email) async {
    try {
      await _authService.sendMagicLink(email);
      await _localStorage.saveEmail(email);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signInWithMagicLink(String link) async {
    try {
      state = const AuthLoading();
      final email = await _localStorage.getSavedEmail();

      if (email == null) {
        throw 'Email not found. Please request a new magic link.';
      }

      final credential = await _authService.signInWithMagicLink(email, link);
      await _localStorage.clearEmail();
      await _loadUserProfile(credential.user!.uid);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _localStorage.clearUserProfile();
    state = const AuthUnauthenticated();
  }

  Future<void> refreshProfile() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await _loadUserProfile(currentState.profile.userId);
    }
  }
}

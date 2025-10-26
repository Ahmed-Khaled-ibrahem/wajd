import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../models/auth_state.dart';
import '../../../models/user_profile.dart';
import '../../../services/local_storage_service.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Supabase Service Provider (for database operations)
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

// Local Storage Provider (you'll need to implement this based on your existing service)
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

// Auth Controller
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(ref),
);

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(AuthInitial()) {
    _init();
  }

  SupabaseClient get _supabase => _ref.read(supabaseClientProvider);
  SupabaseService get _supabaseService => _ref.read(supabaseServiceProvider);
  LocalStorageService get _localStorage => _ref.read(localStorageProvider);

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
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

      // Try to fetch from Supabase database
      final profile = await _supabaseService.getUserProfile(userId);

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
      if (cachedProfile != null && cachedProfile.id == userId) {
        state = AuthAuthenticated(cachedProfile);
      } else {
        state = AuthError(e.toString());
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AuthLoading();
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
      } else {
        state = const AuthError('Sign in failed');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> createAccount(
      String email,
      String password,
      AppUser profile,
      ) async {
    try {
      state = const AuthLoading();
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: profile.toJson(), // Optional: store metadata in auth.users
      );

      if (response.user != null) {
        // Create profile in Supabase database
        final newProfile = profile.copyWith(id: response.user!.id);
        await _supabaseService.createUserProfile(
          response.user!.id,
          newProfile,
        );

        // Save to local storage
        await _localStorage.saveUserProfile(newProfile);
        state = AuthAuthenticated(newProfile);
      } else {
        state = const AuthError('Account creation failed');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> sendMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'your-app-scheme://login-callback', // Configure your deep link
      );
      await _localStorage.saveEmail(email);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signInWithMagicLink(String token) async {
    try {
      state = const AuthLoading();

      // Supabase handles magic link verification automatically through the redirect
      // If you need to verify manually:
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.magiclink,
        token: token,
        email: await _localStorage.getSavedEmail() ?? '',
      );

      if (response.user != null) {
        await _localStorage.clearEmail();
        await _loadUserProfile(response.user!.id);
      } else {
        state = const AuthError('Magic link verification failed');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'your-app-scheme://reset-password', // Configure your deep link
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _localStorage.clearUserProfile();
      state = const AuthUnauthenticated();
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> refreshProfile() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await _loadUserProfile(currentState.profile.id);
    }
  }
}

// Supabase Service for database operations
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles') // Change to your table name
          .select()
          .eq('id', userId) // Change to your column name
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUserProfile(String userId, AppUser profile) async {
    await _client.from('profiles').insert({
      'id': userId,
      ...profile.toJson(),
    });
  }

  Future<void> updateUserProfile(String userId, AppUser profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', userId);
  }
}
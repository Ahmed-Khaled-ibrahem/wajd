import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../models/user_profile.dart';

// Current app user provider
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final userNotifier = ref.read(userProfileProvider.notifier);
  return await userNotifier.fetchUserProfile(user.id);
});

// User profile state provider
final userProfileProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<AppUser?>>(
      (ref) => UserProfileNotifier(ref),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;
  late final SupabaseClient _client;

  UserProfileNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _client = _ref.read(supabaseClientProvider);
  }

  Future<AppUser?> fetchUserProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = AppUser.fromJson(response);
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    state = const AsyncValue.loading();
    try {
      await _client
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);

      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createUserProfile(AppUser user) async {
    state = const AsyncValue.loading();
    try {
      await _client.from('users').insert(user.toJson());
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> uploadProfileImage(String userId, String imagePath) async {
    try {
      final fileName = 'profile_$userId${DateTime.now().millisecondsSinceEpoch}';
      final response = await _client.storage
          .from('profile-images')
          .upload(fileName, imagePath as dynamic);

      if (response.isNotEmpty) {
        final imageUrl = _client.storage
            .from('profile-images')
            .getPublicUrl(fileName);
        return imageUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// Staff users provider (for admin)
final staffUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('users')
        .select()
        .inFilter('role', ['staff', 'admin'])
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AppUser.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch staff users: $e');
  }
});

// Search users provider
final searchUsersProvider = FutureProvider.family<List<AppUser>, String>(
      (ref, query) async {
    if (query.isEmpty) return [];

    final client = ref.watch(supabaseClientProvider);
    try {
      final response = await client
          .from('users')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((json) => AppUser.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  },
);
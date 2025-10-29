import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../models/user_profile.dart';

// Staff users provider (only staff role)
final staffUsersListProvider = FutureProvider<List<AppUser>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('profiles')
        .select()
        .eq('role', 'staff')
        .order('created_at', ascending: false);

    return (response as List).map((json) => AppUser.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to fetch staff users: $e');
  }
});

// Parent users provider (for converting to staff)
final parentUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final response = await client
        .from('profiles')
        .select()
        .eq('role', 'parent')
        .order('created_at', ascending: false);

    return (response as List).map((json) => AppUser.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to fetch parent users: $e');
  }
});

// Staff management notifier
final staffManagementProvider =
    StateNotifierProvider<StaffManagementNotifier, AsyncValue<List<AppUser>>>(
      (ref) => StaffManagementNotifier(ref),
    );

class StaffManagementNotifier extends StateNotifier<AsyncValue<List<AppUser>>> {
  final Ref _ref;
  late final SupabaseClient _client;

  StaffManagementNotifier(this._ref) : super(const AsyncValue.loading()) {
    _client = _ref.read(supabaseClientProvider);
    fetchStaffUsers();
  }

  Future<void> fetchStaffUsers() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', 'staff')
          .order('created_at', ascending: false);

      final users = (response as List)
          .map((json) => AppUser.fromJson(json))
          .toList();
      state = AsyncValue.data(users);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> activateStaff(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({
            'metadata': {'status': 'active'},
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await fetchStaffUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> suspendStaff(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({
            'metadata': {'status': 'suspended'},
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await fetchStaffUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> convertToParent(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({
            'role': 'parent',
            'metadata': {'status': 'active'},
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await fetchStaffUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> convertToStaff(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({
            'role': 'staff',
            'metadata': {'status': 'active'},
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await fetchStaffUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  String getStaffStatus(AppUser user) {
    if (user.metadata != null && user.metadata!['status'] != null) {
      return user.metadata!['status'] as String;
    }
    return 'active';
  }
}

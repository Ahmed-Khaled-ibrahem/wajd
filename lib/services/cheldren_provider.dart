import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../models/child_model.dart';

// User's children list provider
final userChildrenProvider = FutureProvider<List<Child>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final notifier = ref.read(childrenProvider.notifier);
  return await notifier.fetchUserChildren(user.id);
});

// Children state provider
final childrenProvider =
StateNotifierProvider<ChildrenNotifier, AsyncValue<List<Child>>>(
      (ref) => ChildrenNotifier(ref),
);

// Selected child provider (for report creation)
final selectedChildProvider = StateProvider<Child?>((ref) => null);

class ChildrenNotifier extends StateNotifier<AsyncValue<List<Child>>> {
  final Ref _ref;
  late final SupabaseClient _client;

  ChildrenNotifier(this._ref) : super(const AsyncValue.data([])) {
    _client = _ref.read(supabaseClientProvider);
  }

  Future<List<Child>> fetchUserChildren(String userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('children')
          .select()
          .eq('parent_id', userId)
          .order('created_at', ascending: false);

      final children = (response as List)
          .map((json) => Child.fromJson(json))
          .toList();

      state = AsyncValue.data(children);
      return children;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<Child?> addChild(Child child) async {
    try {
      final currentChildren = state.value ?? [];
      state = const AsyncValue.loading();

      final response = await _client
          .from('children')
          .insert(child.toJson())
          .select()
          .single();

      final newChild = Child.fromJson(response);
      state = AsyncValue.data([...currentChildren, newChild]);
      return newChild;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> updateChild(Child child) async {
    try {
      final currentChildren = state.value ?? [];
      state = const AsyncValue.loading();

      await _client
          .from('children')
          .update(child.toJson())
          .eq('id', child.id);

      final updatedChildren = currentChildren.map((c) {
        return c.id == child.id ? child : c;
      }).toList();

      state = AsyncValue.data(updatedChildren);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      final currentChildren = state.value ?? [];
      state = const AsyncValue.loading();

      await _client.from('children').delete().eq('id', childId);

      final updatedChildren = currentChildren
          .where((child) => child.id != childId)
          .toList();

      state = AsyncValue.data(updatedChildren);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<String?> uploadChildImage(String childId, String imagePath) async {
    try {
      final fileName = 'child_$childId${DateTime.now().millisecondsSinceEpoch}';
      final response = await _client.storage
          .from('children-images')
          .upload(fileName, imagePath as dynamic);

      if (response.isNotEmpty) {
        final imageUrl = _client.storage
            .from('children-images')
            .getPublicUrl(fileName);
        return imageUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyChildImage(String childId, String imagePath) async {
    try {
      // Implement image comparison logic here
      // This could involve:
      // 1. Uploading the new image temporarily
      // 2. Using a service like AWS Rekognition or Azure Face API
      // 3. Comparing with stored child images
      // 4. Returning similarity score

      // For now, returning true as placeholder
      // In production, implement actual image comparison
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Single child provider
final childByIdProvider = FutureProvider.family<Child?, String>(
      (ref, childId) async {
    final client = ref.watch(supabaseClientProvider);
    try {
      final response = await client
          .from('children')
          .select()
          .eq('id', childId)
          .single();

      return Child.fromJson(response);
    } catch (e) {
      return null;
    }
  },
);
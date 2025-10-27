import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wajd/models/child_model.dart';

// This is a placeholder for the actual implementation
class ChildrenRepository {
  Future<List<Child>> fetchChildren() async {
    // TODO: Implement actual data fetching
    return [];
  }

  Future<void> addChild(Child child) async {
    // TODO: Implement actual add child
  }

  Future<void> updateChild(String id, Child child) async {
    // TODO: Implement actual update
  }

  Future<void> deleteChild(String id) async {
    // TODO: Implement actual delete
  }
}

final childrenRepositoryProvider = Provider<ChildrenRepository>((ref) {
  return ChildrenRepository();
});

final childrenProvider = FutureProvider<List<Child>>((ref) async {
  final repository = ref.watch(childrenRepositoryProvider);
  return await repository.fetchChildren();
});

final childProvider = StateNotifierProvider.family<ChildNotifier, AsyncValue<Child?>, String>((ref, id) {
  return ChildNotifier(ref, id);
});

class ChildNotifier extends StateNotifier<AsyncValue<Child?>> {
  final Ref _ref;
  final String id;
  
  ChildNotifier(this._ref, this.id) : super(const AsyncValue.loading()) {
    _loadChild();
  }
  
  Future<void> _loadChild() async {
    try {
      // TODO: Implement loading a single child
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateChild(Child child) async {
    try {
      state = const AsyncValue.loading();
      final repository = _ref.read(childrenRepositoryProvider);
      await repository.updateChild(child.id, child);
      state = AsyncValue.data(child);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
  
  Future<void> deleteChild() async {
    try {
      state = const AsyncValue.loading();
      final repository = _ref.read(childrenRepositoryProvider);
      await repository.deleteChild(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

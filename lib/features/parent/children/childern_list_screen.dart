import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wajd/models/child_model.dart';
import 'package:wajd/features/parent/children/add_new_child_screen.dart';
import 'package:wajd/features/parent/children/edit_child_screen.dart';
import 'package:wajd/features/parent/children/providers/children_provider.dart';

class ChildrenListScreen extends ConsumerStatefulWidget {
  static const routeName = '/children-list';

  const ChildrenListScreen({Key? key}) : super(key: key);

  @override
  _ChildrenListScreenState createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends ConsumerState<ChildrenListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh the children list when the screen is first loaded
    Future.microtask(() => ref.invalidate(childrenProvider));
  }

  Future<void> _deleteChild(String childId, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // In a real app, you would call your repository or API here
      // For now, we'll just invalidate the provider to refresh the list
      ref.invalidate(childrenProvider);
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Child deleted successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to delete child: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        centerTitle: true,
        elevation: 0,
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (children) {
          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.child_care_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No children added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddChild(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Child'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (ctx, index) => _buildChildCard(children[index], context),
          );
        },
      ),
      floatingActionButton: childrenAsync.maybeWhen(
        data: (children) => children.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _navigateToAddChild(context),
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildChildCard(Child child, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: child.imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    child.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.child_care,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
        ),
        title: Text(
          child.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${child.age} years old • ${child.gender}'),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            // if (value == 'edit') {
            //   ref.read(childrenProvider.notifier).editChild(child);
            // } else if (value == 'delete') {
            //   ref.read(childrenProvider.notifier).deleteChild(child.id);
            // }
          },
          child: const Icon(Icons.more_vert),
        ),)
        // onTap: () => ref.read(childrenProvider.notifier).editChild(child),
    );
  }

  void _navigateToAddChild(BuildContext context) async {
   context.push('/add-child');
  }

  void _navigateToEditChild(BuildContext context, Child child) async {
    final result = await Navigator.pushNamed(
      context,
      EditChildScreen.routeName,
      arguments: child,
    );
    
    if (result == true) {
      // _loadChildren();
    }
  }

  void _showDeleteDialog(String childId, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This will permanently delete this child\'s information.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteChild(childId, context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

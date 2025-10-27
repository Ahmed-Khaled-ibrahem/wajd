import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final List<Map<String, dynamic>> _staffMembers = [
    {'name': 'John Doe', 'email': 'john@example.com', 'status': 'Active'},
    {'name': 'Jane Smith', 'email': 'jane@example.com', 'status': 'Active'},
    {'name': 'Bob Johnson', 'email': 'bob@example.com', 'status': 'Suspended'},
  ];

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Full Name'),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement add staff functionality
              Navigator.pop(context);
            },
            child: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }

  void _showStaffActions(String staffId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Account'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to edit screen
            },
          ),
          ListTile(
            leading: Icon(currentStatus == 'Active' ? Icons.pause_circle_outline : Icons.play_circle_outline),
            title: Text(currentStatus == 'Active' ? 'Suspend Account' : 'Activate Account'),
            onTap: () {
              // TODO: Toggle account status
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Delete account
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStaffDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _staffMembers.length,
        itemBuilder: (context, index) {
          final staff = _staffMembers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(staff['name']),
              subtitle: Text(staff['email']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: staff['status'] == 'Active' ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      staff['status'],
                      style: TextStyle(
                        color: staff['status'] == 'Active' ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showStaffActions('staff_$index', staff['status']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

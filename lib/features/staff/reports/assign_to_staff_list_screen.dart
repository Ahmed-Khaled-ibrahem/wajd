import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wajd/models/user_profile.dart';
import 'package:wajd/providers/report_provider.dart';
import 'package:wajd/providers/staff_management_provider.dart';

class AssignToStaffListScreen extends ConsumerStatefulWidget {
  const AssignToStaffListScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState createState() => _AssignToStaffListScreenState();
}

class _AssignToStaffListScreenState extends ConsumerState<AssignToStaffListScreen> {
  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffUsersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign to staff'),
      ),
      body: staffAsync.when(
        data: (staff) {
          if (staff.isEmpty) {
            return const Center(child: Text('No staff found'));
          }
          return ListView.separated(
            itemCount: staff.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final AppUser user = staff[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () => _confirmAssign(user),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load staff')),
      ),
    );
  }

  Future<void> _confirmAssign(AppUser staff) async {
    final shouldAssign = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm assignment'),
        content: Text('Assign this report to ${staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, assign'),
          ),
        ],
      ),
    );

    if (shouldAssign == true) {
      await _assign(staff.id, staff.name);
    }
  }

  Future<void> _assign(String staffId, String staffName) async {
    final success = await ref
        .read(reportsProvider.notifier)
        .assignReportToStaff(widget.reportId, staffId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to $staffName')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign report')),
      );
    }
  }
}

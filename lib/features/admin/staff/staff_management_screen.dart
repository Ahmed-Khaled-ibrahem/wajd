import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/const/colors.dart';
import '../../../models/user_profile.dart';
import '../../../providers/staff_management_provider.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _searchQuery = '';

  void _showAddStaffDialog() {
    final emailController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Staff Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the email of the parent account to convert to staff:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  prefixIcon:  Icon(Icons.email_rounded, color: AppColors.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: errorMessage,
                ),
                onChanged: (value) {
                  if (errorMessage != null) {
                    setState(() => errorMessage = null);
                  }
                },
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                 Center(
                  child: CircularProgressIndicator(color: AppColors.primaryColor),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      
                      if (email.isEmpty) {
                        setState(() => errorMessage = 'Please enter an email');
                        return;
                      }

                      // Basic email validation
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                        setState(() => errorMessage = 'Please enter a valid email');
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        // Fetch parent users
                        final parentUsers = await ref.read(parentUsersProvider.future);
                        
                        // Check if user exists
                        final user = parentUsers.cast<AppUser?>().firstWhere(
                          (u) => u!.email.toLowerCase() == email.toLowerCase(),
                          orElse: () => null,
                        );

                        if (user == null) {
                          setState(() {
                            isLoading = false;
                            errorMessage = 'This user has not created an account yet';
                          });
                          return;
                        }

                        // User exists, close dialog and convert
                        if (context.mounted) {
                          Navigator.pop(context);
                          await _convertToStaff(user);
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorMessage = 'Error checking user: ${e.toString()}';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffActions(AppUser staff) {
    final notifier = ref.read(staffManagementProvider.notifier);
    final status = notifier.getStaffStatus(staff);
    final isActive = status == 'active';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: isActive ? const Color(0xFFF59E0B) : AppColors.primaryColor,
              ),
              title: Text(isActive ? 'Suspend Account' : 'Activate Account'),
              onTap: () {
                Navigator.pop(context);
                if (isActive) {
                  _suspendStaff(staff);
                } else {
                  _activateStaff(staff);
                }
              },
            ),
            // ListTile(
            //   leading: const Icon(
            //     Icons.person_remove_rounded,
            //     color: Color(0xFFEF4444),
            //   ),
            //   title: const Text(
            //     'Convert to Parent',
            //     style: TextStyle(color: Color(0xFFEF4444)),
            //   ),
            //   subtitle: const Text(
            //     'Remove staff privileges',
            //     style: TextStyle(fontSize: 12),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _showConvertToParentDialog(staff);
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffManagementProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _showAddStaffDialog,
            tooltip: 'Add Staff Member',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(staffManagementProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search staff by name or email...',
                prefixIcon:  Icon(Icons.search_rounded, color: AppColors.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Staff List
          Expanded(
            child: staffAsync.when(
              loading: () =>  Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading staff',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(staffManagementProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              data: (staffList) {
                final filteredStaff = _searchQuery.isEmpty
                    ? staffList
                    : staffList
                        .where((staff) =>
                            staff.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            staff.email
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filteredStaff.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.people_outline
                              : Icons.search_off,
                          size: 64,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No Staff Members'
                              : 'No Results Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add staff members to get started'
                              : 'Try a different search term',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(staffManagementProvider);
                  },
                  color: AppColors.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staff = filteredStaff[index];
                      final notifier =
                          ref.read(staffManagementProvider.notifier);
                      final status = notifier.getStaffStatus(staff);
                      final isActive = status == 'active';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: isActive
                                ? AppColors.primaryColor
                                : const Color(0xFF6B7280),
                            child: Text(
                              staff.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            staff.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                staff.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                              if (staff.phoneNumber != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  staff.phoneNumber!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primaryColor.withOpacity(0.1)
                                      : const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primaryColor
                                        : const Color(0xFFF59E0B),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.check_circle_rounded
                                          : Icons.pause_circle_rounded,
                                      size: 14,
                                      color: isActive
                                          ? AppColors.primaryColor
                                          : const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isActive ? 'Active' : 'Suspended',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? AppColors.primaryColor
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                onPressed: () => _showStaffActions(staff),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _convertToStaff(AppUser user) async {
    final notifier = ref.read(staffManagementProvider.notifier);
    final success = await notifier.convertToStaff(user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${user.name} has been promoted to staff'
                : 'Failed to convert user to staff',
          ),
          backgroundColor: success ? AppColors.primaryColor : const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _activateStaff(AppUser staff) async {
    final notifier = ref.read(staffManagementProvider.notifier);
    final success = await notifier.activateStaff(staff.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${staff.name} has been activated'
                : 'Failed to activate staff member',
          ),
          backgroundColor: success ? AppColors.primaryColor : const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _suspendStaff(AppUser staff) async {
    final notifier = ref.read(staffManagementProvider.notifier);
    final success = await notifier.suspendStaff(staff.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${staff.name} has been suspended'
                : 'Failed to suspend staff member',
          ),
          backgroundColor: success ? AppColors.primaryColor : const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showConvertToParentDialog(AppUser staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Convert to Parent?'),
        content: Text(
          'Are you sure you want to remove staff privileges from ${staff.name}? They will be converted to a parent account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _convertToParent(staff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  Future<void> _convertToParent(AppUser staff) async {
    final notifier = ref.read(staffManagementProvider.notifier);
    final success = await notifier.convertToParent(staff.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${staff.name} has been converted to parent'
                : 'Failed to convert staff to parent',
          ),
          backgroundColor: success ? AppColors.primaryColor : const Color(0xFFEF4444),
        ),
      );
    }
  }
}

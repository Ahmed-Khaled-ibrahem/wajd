import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wajd/models/child_model.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../../../app/const/colors.dart';
import '../../../providers/cheldren_provider.dart';

class ChildrenListScreen extends ConsumerStatefulWidget {
  const ChildrenListScreen({super.key});
  @override
  ConsumerState<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends ConsumerState<ChildrenListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(childrenProvider.notifier).fetchUserChildren(user.id);
    }
  }

  Future<void> _deleteChild(Child child) async {
    final confirmed = await _showDeleteDialog(child);
    if (confirmed == true) {
      final success = await ref
          .read(childrenProvider.notifier)
          .deleteChild(child.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    success
                        ? 'Child deleted successfully'
                        : 'Failed to delete child',
                  ),
                ),
              ],
            ),
            backgroundColor: success
                ? AppColors.primaryColor
                : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteDialog(Child child) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete Child?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${child.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('My Children'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadChildren,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               CircularProgressIndicator(color: AppColors.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading children...',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load children',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadChildren,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (children) {
          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor.withOpacity(0.1),
                            AppColors.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.child_care_rounded,
                        size: isSmallScreen ? 64 : 80,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No children added yet',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your children to keep track of them',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // const SizedBox(height: 32),
                    // ElevatedButton.icon(
                    //   onPressed: () => context.push('/add-child'),
                    //   icon: const Icon(Icons.add_rounded),
                    //   label: const Text('Add Your First Child'),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: const Color(0xFF10B981),
                    //     foregroundColor: Colors.white,
                    //     padding: EdgeInsets.symmetric(
                    //       horizontal: isSmallScreen ? 24 : 32,
                    //       vertical: isSmallScreen ? 14 : 16,
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(14),
                    //     ),
                    //     elevation: 0,
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _loadChildren,
            color: AppColors.primaryColor,
            child: ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              itemCount: children.length,
              itemBuilder: (ctx, index) =>
                  _buildChildCard(children[index], isSmallScreen),
            ),
          );
        },
      ),
      floatingActionButton: childrenAsync.maybeWhen(
        data: (children) => FloatingActionButton.extended(
          onPressed: () => context.push('/add-child'),
          icon: const Icon(Icons.add_rounded),
          label: Text(isSmallScreen ? 'Add' : 'Add Child'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildChildCard(Child child, bool isSmallScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/edit-child', extra: child);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
            child: Row(
              children: [
                // Child Photo
                Stack(
                  children: [
                    Container(
                      width: isSmallScreen ? 70 : 80,
                      height: isSmallScreen ? 70 : 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:  LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.gradientColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child:
                              (child.imageUrl != null &&
                                  child.imageUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: child.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.primaryColor.withOpacity(0.1),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: AppColors.primaryColor.withOpacity(0.1),
                                        child: Icon(
                                          Icons.child_care_rounded,
                                          size: isSmallScreen ? 32 : 36,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.child_care_rounded,
                                    size: isSmallScreen ? 32 : 36,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Verified badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient:  LinearGradient(
                            colors: AppColors.gradientColor,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: isSmallScreen ? 14 : 18),

                // Child Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.cake_rounded,
                            label: '${child.age} years',
                            isSmallScreen: isSmallScreen,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: child.gender.toLowerCase() == 'male'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            label: child.gender,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                      ),
                      // if (child.bloodType != null) ...[
                      //   const SizedBox(height: 6),
                      //   _buildInfoChip(
                      //     icon: Icons.bloodtype_rounded,
                      //     label: 'Blood: ${child.bloodType}',
                      //     isSmallScreen: isSmallScreen,
                      //     color: const Color(0xFFEF4444),
                      //   ),
                      // ],
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:  Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:  Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Edit Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/edit-child', extra: child);
                    } else if (value == 'delete') {
                      _deleteChild(child);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isSmallScreen,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primaryColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 12 : 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

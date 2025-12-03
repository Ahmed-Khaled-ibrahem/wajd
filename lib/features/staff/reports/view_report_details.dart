import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wajd/features/staff/reports/similar_card.dart';
import 'package:wajd/models/report_model.dart';
import '../../../app/const/colors.dart';
import '../../../models/notification_model.dart';
import '../../../models/user_profile.dart';
import '../../../providers/notifi_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../services/supabase_cleint.dart';
import '../../login/controller/current_profile_provider.dart';

class ViewReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ViewReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<ViewReportDetailsScreen> createState() =>
      _ViewReportDetailsScreenState();
}

class _ViewReportDetailsScreenState
    extends ConsumerState<ViewReportDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportByIdProvider(widget.reportId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isAdmin = ref.read(currentUserProfileProvider)?.role.name == 'admin';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF9FAFB),
      body: reportAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (error, stack) => _buildErrorState(error, isDark),
        data: (report) {
          if (report == null) {
            return _buildNotFoundState(isDark);
          }
          return _buildReportDetails(report, isDark, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildReportDetails(Report report, bool isDark, bool isSmallScreen) {
    final statusColor = _getStatusColor(report.status);

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(report, statusColor, isDark, isSmallScreen),
        SliverPadding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          sliver: SliverList(
            delegate:
                SliverChildListDelegate([
                  _buildStatusCard(report, statusColor, isDark, isSmallScreen),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Child Information',
                    Icons.child_care_rounded,
                    isDark,
                    isSmallScreen,
                    [
                      _buildInfoRow(
                        'Name',
                        report.childName,
                        Icons.person_rounded,
                        isDark,
                      ),
                      _buildInfoRow(
                        'Age',
                        '${report.childAge} years',
                        Icons.cake_rounded,
                        isDark,
                      ),
                      _buildInfoRow(
                        'Gender',
                        report.childGender,
                        report.childGender == 'Male'
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                        isDark,
                      ),
                      _buildInfoRow(
                        'Description',
                        report.childDescription,
                        Icons.description_rounded,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Last Seen Details',
                    Icons.location_on_rounded,
                    isDark,
                    isSmallScreen,
                    [
                      _buildInfoRow(
                        'Location',
                        report.lastSeenLocation,
                        Icons.place_rounded,
                        isDark,
                      ),
                      _buildInfoRow(
                        'Date & Time',
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(report.lastSeenTime),
                        Icons.access_time_rounded,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (report.childImageUrl != null ||
                      report.additionalImages.isNotEmpty) ...[
                    _buildImagesSection(report, isDark, isSmallScreen),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionCard(
                    'Reporter Contact',
                    Icons.contact_phone_rounded,
                    isDark,
                    isSmallScreen,
                    [
                      _buildInfoRow(
                        'Phone',
                        report.reporterPhone,
                        Icons.phone_rounded,
                        isDark,
                      ),
                      _buildInfoRow(
                        'Backup Phone',
                        report.metadata?['backup_phone'] ?? '....',
                        Icons.phone_rounded,
                        isDark,
                      ),
                      if (report.reporterEmail != null)
                        _buildInfoRow(
                          'Email',
                          report.reporterEmail!,
                          Icons.email_rounded,
                          isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (report.additionalNotes != null &&
                      report.additionalNotes!.isNotEmpty) ...[
                    _buildSectionCard(
                      'Additional Notes',
                      Icons.note_rounded,
                      isDark,
                      isSmallScreen,
                      [
                        Text(
                          report.additionalNotes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (report.closureNotes != null &&
                      report.closureNotes!.isNotEmpty) ...[
                    _buildSectionCard(
                      'Closure Notes',
                      Icons.check_circle_rounded,
                      isDark,
                      isSmallScreen,
                      [
                        Text(
                          report.closureNotes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildActionButtons(report, isDark, isSmallScreen),
                  Builder(
                    builder: (context) {
                      final isAdmin =
                          ref.read(currentUserProfileProvider)?.role.name ==
                          'admin';
                      if (isAdmin) {
                        return ElevatedButton(
                          onPressed: () {
                            context
                                .push('/assign-to-staff', extra: widget.reportId)
                                .then((value) {
                              if (value == true) {
                                ref.invalidate(reportByIdProvider(widget.reportId));
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFF1F2937)),
                            backgroundColor: isDark
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                            foregroundColor: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                          child: Text('Assign to staff'),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 15),
                  SimilarReportsCard(currentReport: report),
                ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
    Report report,
    Color statusColor,
    bool isDark,
    bool isSmallScreen,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new),
        color: Colors.white,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor, statusColor.withOpacity(0.7)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Report Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${report.id.substring(0, 8)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    Report report,
    Color statusColor,
    bool isDark,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(report.status),
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(report.status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${_formatTimeAgo(report.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    bool isDark,
    bool isSmallScreen,
    List<Widget> children,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(Report report, bool isDark, bool isSmallScreen) {
    final allImages = [
      if (report.childImageUrl != null) report.childImageUrl!,
      ...report.additionalImages,
    ];
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isSmallScreen ? 2 : 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: allImages.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _showImageDialog(allImages[index]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: allImages[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Report report, bool isDark, bool isSmallScreen) {
    final currentUser = ref.read(currentUserProvider);
    final currentUserData = ref.read(currentUserProfileProvider);
    final isAssignedToMe = report.assignedStaffId == currentUser?.id;
    final isAdmin = currentUserData?.role.name == 'admin';
    if (currentUserData?.role == UserRole.parent) {
      return Container();
    }
    return Column(
      children: [
        if (!isAssignedToMe && report.assignedStaffId == null && !isAdmin)
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 48 : 52,
            child: ElevatedButton.icon(
              onPressed: () => _assignToMe(report),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Assign to Me'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: isSmallScreen ? 48 : 52,
                child: OutlinedButton.icon(
                  onPressed: () => _showChangeStatusDialog(report),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Change Status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            if (report.status != ReportStatus.closed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: isSmallScreen ? 48 : 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCloseReportDialog(report),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Close Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'Error Loading Report',
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
              onPressed: () =>
                  ref.invalidate(reportByIdProvider(widget.reportId)),
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
    );
  }

  Widget _buildNotFoundState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Color(0xFF6B7280)),
            const SizedBox(height: 16),
            Text(
              'Report Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The report you are looking for does not exist.',
              style: TextStyle(color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignToMe(Report report) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    try {
      await ref
          .read(reportsProvider.notifier)
          .assignReportToStaff(report.id, currentUser.id);
      ref.invalidate(reportByIdProvider(widget.reportId));
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Report assigned to you successfully'),
      //       backgroundColor: AppColors.primaryColor,
      //     ),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign report: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _assignReportToStaff(Report report, String staffId) {
    try {
      ref
          .read(reportsProvider.notifier)
          .assignReportToStaff(report.id, staffId);
      ref.invalidate(reportByIdProvider(widget.reportId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report assigned to $staffId successfully'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign report: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showChangeStatusDialog(Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              report,
              ReportStatus.open,
              'Open',
              Icons.warning_rounded,
              const Color(0xFFEF4444),
            ),
            _buildStatusOption(
              report,
              ReportStatus.inProgress,
              'In Progress',
              Icons.pending_rounded,
              const Color(0xFFF59E0B),
            ),
            _buildStatusOption(
              report,
              ReportStatus.closed,
              'Closed',
              Icons.check_circle_rounded,
              AppColors.primaryColor,
            ),
            _buildStatusOption(
              report,
              ReportStatus.cancelled,
              'Cancelled',
              Icons.cancel_rounded,
              const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    Report report,
    ReportStatus status,
    String label,
    IconData icon,
    Color color,
  ) {
    final isCurrentStatus = report.status == status;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: isCurrentStatus
          ? Icon(Icons.check_rounded, color: AppColors.primaryColor)
          : null,
      onTap: isCurrentStatus
          ? null
          : () async {
              context.pop();
              await _changeStatus(report, status);
              ref.invalidate(allReportsProvider);
              await ref.read(allReportsProvider.future);
              context.pop();
            },
    );
  }

  Future<void> _changeStatus(Report report, ReportStatus newStatus) async {
    try {
      await ref
          .read(reportsProvider.notifier)
          .updateReportStatus(report.id, newStatus.name);
      ref.invalidate(reportByIdProvider(widget.reportId));
      await notifyParentStatus(report.reporterId, newStatus.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status changed to ${_getStatusText(newStatus)}'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change status: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showCloseReportDialog(Report report) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you sure you want to close this report? Please provide closure notes:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter closure notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              context.pop();
              await _closeReport(report, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Report'),
          ),
        ],
      ),
    );
  }

  notifyParent(parentId) {
    ref
        .read(notificationsProvider.notifier)
        .createNotification(
          userId: parentId,
          type: NotificationType.reportUpdated,
          title: 'your report has been closed',
          message:
              'your report has been closed by our team , we are going to get contact with you soon',
        );
  }

  notifyParentStatus(parentId, status) {
    ref
        .read(notificationsProvider.notifier)
        .createNotification(
          userId: parentId,
          type: NotificationType.reportUpdated,
          title: 'your report status has been changed to $status',
          message: 'your report status has been changed to $status by our team',
        );
  }

  Future<void> _closeReport(Report report, String notes) async {
    try {
      await ref.read(reportsProvider.notifier).closeReport(report.id, notes);
      await notifyParent(report.reporterId);
      ref.invalidate(reportByIdProvider(widget.reportId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report closed successfully'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close report: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return const Color(0xFFEF4444);
      case ReportStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ReportStatus.closed:
        return AppColors.primaryColor;
      case ReportStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return Icons.warning_rounded;
      case ReportStatus.inProgress:
        return Icons.pending_rounded;
      case ReportStatus.closed:
        return Icons.check_circle_rounded;
      case ReportStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return 'OPEN';
      case ReportStatus.inProgress:
        return 'IN PROGRESS';
      case ReportStatus.closed:
        return 'CLOSED';
      case ReportStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

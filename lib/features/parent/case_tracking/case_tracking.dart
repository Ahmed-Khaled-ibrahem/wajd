import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wajd/models/report_model.dart';
import '../../../providers/report_provider.dart';

class CaseTrackingWidget extends ConsumerWidget {
  final int maxItemsToShow;
  final bool showViewAll;

  const CaseTrackingWidget({
    super.key,
    this.maxItemsToShow = 3,
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userReportsAsync = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, userReportsAsync),
          const SizedBox(height: 16),
          _buildReportsList(context, ref, isDark, userReportsAsync),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    AsyncValue<List<Report>> reportsAsync,
  ) {
    final totalCount = reportsAsync.maybeWhen(
      data: (reports) => reports.length,
      orElse: () => 0,
    );

    final activeCount = reportsAsync.maybeWhen(
      data: (reports) => reports
          .where(
            (r) =>
                r.status == ReportStatus.open ||
                r.status == ReportStatus.inProgress,
          )
          .length,
      orElse: () => 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Case Tracking',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCount Active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalCount Total Cases',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => context.push('/reports-history'),
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text('View All'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AsyncValue<List<Report>> reportsAsync,
  ) {
    return reportsAsync.when(
      loading: () => _buildLoadingState(isDark),
      error: (error, stack) => _buildErrorState(error, isDark),
      data: (reports) {
        if (reports.isEmpty) {
          return _buildEmptyState(context, isDark);
        }
        // Show only active reports first, then others
        final activeReports = reports
            .where(
              (r) =>
                  r.status == ReportStatus.open ||
                  r.status == ReportStatus.inProgress,
            )
            .toList();

        final otherReports = reports
            .where(
              (r) =>
                  r.status != ReportStatus.open &&
                  r.status != ReportStatus.inProgress,
            )
            .toList();

        final displayReports = [
          ...activeReports,
          ...otherReports,
        ].take(maxItemsToShow).toList();

        return Column(
          children: displayReports
              .map((report) => _buildReportCard(context, isDark, report))
              .toList(),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, bool isDark) {
    print(error);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            'Error Loading Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.05),
            const Color(0xFF059669).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_add_check_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your case reports will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/report-my-child'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, bool isDark, Report report) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final statusColor = _getStatusColor(report.status);
    final statusBgColor = statusColor.withOpacity(0.15);

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 14),
      child: GestureDetector(
        onTap: () => context.push('/report-details/${report.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withOpacity(0.08),
                      statusColor.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Child Photo with Status Indicator
                    _buildChildAvatar(
                      report,
                      statusColor,
                      isDark,
                      isSmallScreen,
                    ),
                    SizedBox(width: isSmallScreen ? 14 : 16),
                    // Child Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.childName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF047857),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStatusBadge(
                                report.status,
                                statusColor,
                                statusBgColor,
                                isSmallScreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatTimeAgo(report.createdAt),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : const Color(0xFF6B7280),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quick action icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Body Section
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: isSmallScreen ? 14 : 16,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            report.lastSeenLocation,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[300]
                                  : const Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Last Seen Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: isSmallScreen ? 14 : 16,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last seen: ${DateFormat('MMM dd, yyyy - hh:mm a').format(report.lastSeenTime)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      report.childDescription,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF374151),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Footer Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 16,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : const Color(0xFFF9FAFB),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: isSmallScreen ? 14 : 16,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ID: ${report.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/report-details/${report.id}'),
                      icon: Icon(
                        Icons.visibility_rounded,
                        size: isSmallScreen ? 16 : 18,
                      ),
                      label: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildAvatar(
    Report report,
    Color statusColor,
    bool isDark,
    bool isSmallScreen,
  ) {
    return Stack(
      children: [
        Container(
          width: isSmallScreen ? 70 : 80,
          height: isSmallScreen ? 70 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor, statusColor.withOpacity(0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: report.childImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: report.childImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: statusColor.withOpacity(0.1),
                        child: Icon(
                          Icons.child_care_rounded,
                          size: isSmallScreen ? 32 : 36,
                          color: statusColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: statusColor.withOpacity(0.1),
                        child: Icon(
                          Icons.child_care_rounded,
                          size: isSmallScreen ? 32 : 36,
                          color: statusColor,
                        ),
                      ),
                    )
                  : Container(
                      color: statusColor.withOpacity(0.1),
                      child: Icon(
                        Icons.child_care_rounded,
                        size: isSmallScreen ? 32 : 36,
                        color: statusColor,
                      ),
                    ),
            ),
          ),
        ),
        // Status indicator dot
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    ReportStatus status,
    Color statusColor,
    Color statusBgColor,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: isSmallScreen ? 12 : 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.closed:
        return const Color(0xFF10B981); // Green
      case ReportStatus.inProgress:
        return const Color(0xFFF59E0B); // Amber
      case ReportStatus.open:
        return const Color(0xFFEF4444); // Red
      case ReportStatus.cancelled:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.closed:
        return Icons.check_circle_rounded;
      case ReportStatus.inProgress:
        return Icons.pending_rounded;
      case ReportStatus.open:
        return Icons.warning_rounded;
      case ReportStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.closed:
        return 'CLOSED';
      case ReportStatus.inProgress:
        return 'IN PROGRESS';
      case ReportStatus.open:
        return 'OPEN';
      case ReportStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
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

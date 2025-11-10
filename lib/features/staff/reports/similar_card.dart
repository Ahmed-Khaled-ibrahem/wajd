import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:wajd/features/staff/reports/provider_similar.dart';
import 'package:wajd/models/report_model.dart';
import '../../../app/const/colors.dart';

class SimilarReportsCard extends ConsumerWidget {
  final Report currentReport;
  const SimilarReportsCard({super.key, required this.currentReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Get similar reports based on age (±2 years)
    final similarReportsAsync = ref.watch(
      similarReportsByAgeProvider(
        SimilarReportsParams(
          age: currentReport.childAge,
          excludeId: currentReport.id,
        ),
      ),
    );

    return similarReportsAsync.when(
      loading: () => _buildLoadingSkeleton(isDark, isSmallScreen),
      error: (error, stack) => const SizedBox.shrink(),
      data: (similarReports) {
        if (similarReports.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                AppColors.primaryColor.withOpacity(isDark ? 0.1 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(isDark, isSmallScreen, similarReports.length),

              const SizedBox(height: 12),

              // List of similar reports
              ...similarReports.map(
                (report) =>
                    _buildReportTile(context, report, isDark, isSmallScreen),
              ),

              // View All Button (if more than 3)
              if (similarReports.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          _showAllSimilarReports(context, similarReports),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: Text(
                        'View All ${similarReports.length} Similar Reports',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, bool isSmallScreen, int count) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Similar Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count children with similar age',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(
    BuildContext context,
    Report report,
    bool isDark,
    bool isSmallScreen,
  ) {
    final statusColor = _getStatusColor(report.status);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: 6,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContactDialog(context, report),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Child Avatar
                Stack(
                  children: [
                    Container(
                      width: isSmallScreen ? 50 : 56,
                      height: isSmallScreen ? 50 : 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.8)],
                        ),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF1F2937)
                              : Colors.white,
                        ),
                        padding: const EdgeInsets.all(2),
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
                                      size: isSmallScreen ? 20 : 24,
                                      color: statusColor,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: statusColor.withOpacity(0.1),
                                        child: Icon(
                                          Icons.child_care_rounded,
                                          size: isSmallScreen ? 20 : 24,
                                          color: statusColor,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: statusColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.child_care_rounded,
                                    size: isSmallScreen ? 20 : 24,
                                    color: statusColor,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Child Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.childName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF047857),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(
                            report.status,
                            statusColor,
                            isSmallScreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.child_care_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.childAge} years',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            report.childGender == 'Male'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.childGender,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.lastSeenLocation,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
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

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    ReportStatus status,
    Color statusColor,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: isSmallScreen ? 9 : 10,
          fontWeight: FontWeight.bold,
          color: statusColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, Report report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(report.status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: report.childImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: report.childImageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    color: statusColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.child_care_rounded,
                                      size: 40,
                                      color: statusColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: statusColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.child_care_rounded,
                                    size: 40,
                                    color: statusColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        report.childName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.child_care_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${report.childAge} years',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  report.childGender == 'Male'
                                      ? Icons.male_rounded
                                      : Icons.female_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  report.childGender,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Info icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Is This Your Child?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Text(
                        'If you think this might be your child, please contact our staff team immediately for assistance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF6B7280),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              const Color(0xFF2563EB).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              Icons.location_on_rounded,
                              'Last Seen',
                              report.lastSeenLocation,
                              const Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.access_time_rounded,
                              'When',
                              DateFormat(
                                'MMM dd, yyyy - hh:mm a',
                              ).format(report.lastSeenTime),
                              const Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.description_rounded,
                              'Description',
                              report.childDescription,
                              const Color(0xFF6B7280),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // Contact Staff Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _contactStaff(context, report);
                          },
                          icon: const Icon(Icons.support_agent_rounded),
                          label: const Text('Contact Staff Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAllSimilarReports(BuildContext context, List<Report> reports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Similar Reports',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${reports.length} children found',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return _buildReportTile(context, report, isDark, false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactStaff(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Contact Staff')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can contact our staff team through:',
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),
            _buildContactOption(
              Icons.phone_rounded,
              'Phone',
              'not found',
              const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Report ID: ${report.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     Navigator.pop(context);
          //     // Open chat or email
          //   },
          //   icon: const Icon(Icons.chat_rounded),
          //   label: const Text('Open Chat'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: const Color(0xFF10B981),
          //     foregroundColor: Colors.white,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return const Color(0xFFEF4444);
      case ReportStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ReportStatus.closed:
        return const Color(0xFF10B981);
      case ReportStatus.cancelled:
        return const Color(0xFF6B7280);
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
}

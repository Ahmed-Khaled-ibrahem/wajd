import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wajd/models/report_model.dart';
import '../../../providers/report_provider.dart';

class ReportsHistoryScreen extends ConsumerStatefulWidget {
  static const routeName = '/reports-history';

  const ReportsHistoryScreen({super.key});

  @override
  ConsumerState<ReportsHistoryScreen> createState() =>
      _ReportsHistoryScreenState();
}

class _ReportsHistoryScreenState extends ConsumerState<ReportsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userReportsAsync = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: const Text(
          'Reports History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search reports...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF10B981),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              // Tab Bar
              Container(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF10B981),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF10B981),
                  unselectedLabelColor: isDark
                      ? Colors.grey[400]
                      : const Color(0xFF6B7280),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Open'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Closed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: userReportsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, stack) => _buildErrorState(error, isDark),
        data: (reports) {
          final filteredReports = _filterReports(reports);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReportsList(filteredReports, isDark, isSmallScreen),
              _buildReportsList(
                filteredReports
                    .where((r) => r.status == ReportStatus.open)
                    .toList(),
                isDark,
                isSmallScreen,
              ),
              _buildReportsList(
                filteredReports
                    .where((r) => r.status == ReportStatus.inProgress)
                    .toList(),
                isDark,
                isSmallScreen,
              ),
              _buildReportsList(
                filteredReports
                    .where((r) => r.status == ReportStatus.closed)
                    .toList(),
                isDark,
                isSmallScreen,
              ),
            ],
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showReportOptionsDialog(context),
      //   backgroundColor: const Color(0xFF10B981),
      //   icon: const Icon(Icons.add_rounded),
      //   label: const Text('New Report'),
      // ),
    );
  }

  List<Report> _filterReports(List<Report> reports) {
    if (_searchQuery.isEmpty) return reports;

    final query = _searchQuery.toLowerCase();
    return reports.where((report) {
      return report.childName.toLowerCase().contains(query) ||
          report.childDescription.toLowerCase().contains(query) ||
          report.lastSeenLocation.toLowerCase().contains(query) ||
          report.id.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildReportsList(
    List<Report> reports,
    bool isDark,
    bool isSmallScreen,
  ) {
    if (reports.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reportsProvider);
      },
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(reports[index], isDark, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildReportCard(Report report, bool isDark, bool isSmallScreen) {
    final statusColor = _getStatusColor(report.status);
    final statusBgColor = statusColor.withOpacity(0.15);

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
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
                    // Child Photo
                    _buildChildAvatar(
                      report,
                      statusColor,
                      isDark,
                      isSmallScreen,
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 14),
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
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF047857),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (report.isChildRegistered)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 12,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'MY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                              Icon(
                                Icons.circle,
                                size: 4,
                                color: isDark
                                    ? Colors.grey[600]
                                    : const Color(0xFF9CA3AF),
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
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Options Menu
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF6B7280),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 18),
                              const SizedBox(width: 12),
                              const Text('View Details'),
                            ],
                          ),
                          onTap: () =>
                              context.push('/report-details/${report.id}'),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 18),
                              const SizedBox(width: 12),
                              const Text('Share'),
                            ],
                          ),
                          onTap: () => _shareReport(report),
                        ),
                        if (report.status != ReportStatus.closed)
                          PopupMenuItem(
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                const SizedBox(width: 12),
                                const Text('Edit'),
                              ],
                            ),
                            onTap: () => _editReport(report),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body Section
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.child_care_rounded,
                            label: 'Age',
                            value: '${report.childAge} years',
                            isDark: isDark,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatItem(
                            icon: report.childGender == 'Male'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            label: 'Gender',
                            value: report.childGender,
                            isDark: isDark,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: isSmallScreen ? 16 : 18,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
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
                          size: isSmallScreen ? 16 : 18,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last seen: ${DateFormat('MMM dd, yyyy - hh:mm a').format(report.lastSeenTime)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Footer
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
                    Icon(
                      Icons.badge_rounded,
                      size: isSmallScreen ? 14 : 16,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Report ID: ${report.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (report.updatedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.update_rounded,
                            size: isSmallScreen ? 14 : 16,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated ${_formatTimeAgo(report.updatedAt!)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
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
          width: isSmallScreen ? 60 : 70,
          height: isSmallScreen ? 60 : 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
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
                          size: isSmallScreen ? 28 : 32,
                          color: statusColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: statusColor.withOpacity(0.1),
                        child: Icon(
                          Icons.child_care_rounded,
                          size: isSmallScreen ? 28 : 32,
                          color: statusColor,
                        ),
                      ),
                    )
                  : Container(
                      color: statusColor.withOpacity(0.1),
                      child: Icon(
                        Icons.child_care_rounded,
                        size: isSmallScreen ? 28 : 32,
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
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                width: 2.5,
              ),
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
            size: isSmallScreen ? 11 : 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.08),
            const Color(0xFF059669).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 16 : 18,
            color: const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF047857),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF059669).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reports Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF047857),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No reports match your search'
                  : 'No reports in this category',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
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
              'Error Loading Reports',
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
              onPressed: () => ref.invalidate(reportsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create New Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: Colors.white,
                ),
              ),
              title: const Text('Report My Child'),
              subtitle: const Text('Report your registered child as missing'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(context);
                context.push('/report-my-child');
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                ),
              ),
              title: const Text('Report Other Child'),
              subtitle: const Text('Report an unknown missing child'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(context);
                context.push('/report-other-child');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareReport(Report report) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _editReport(Report report) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.closed:
        return const Color(0xFF10B981);
      case ReportStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ReportStatus.open:
        return const Color(0xFFEF4444);
      case ReportStatus.cancelled:
        return const Color(0xFF6B7280);
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

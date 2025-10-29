import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wajd/models/report_model.dart';
import '../../../providers/report_provider.dart';
import '../../../services/supabase_cleint.dart';

class StaffReportsScreen extends ConsumerStatefulWidget {
  const StaffReportsScreen({super.key});
  @override
  ConsumerState<StaffReportsScreen> createState() => _StaffReportsScreenState();
}

class _StaffReportsScreenState extends ConsumerState<StaffReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, assigned, unassigned
  String _selectedSort = 'recent'; // recent, oldest, priority

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allReportsAsync = ref.watch(allReportsProvider);
    final statsAsync = ref.watch(reportStatisticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Stats
          _buildSliverAppBar(isDark, isSmallScreen, statsAsync),

          // Search and Filter Section
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(isDark, isSmallScreen),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF10B981),
                indicatorWeight: 3,
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: isDark
                    ? Colors.grey[400]
                    : const Color(0xFF6B7280),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 15,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 18),
                        const SizedBox(width: 8),
                        const Text('Active'),
                        const SizedBox(width: 6),
                        _buildCountBadge(
                          statsAsync.maybeWhen(
                            data: (stats) => stats.open + stats.inProgress,
                            orElse: () => 0,
                          ),
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.archive_rounded, size: 18),
                        const SizedBox(width: 8),
                        const Text('Archived'),
                        const SizedBox(width: 6),
                        // _buildCountBadge(
                        //   statsAsync.maybeWhen(
                        //     data: (stats) => (stats.closed + stats.cancelled).toInt(),
                        //     orElse: () => 0,
                        //   ),
                        //   const Color(0xFF6B7280),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              isDark: isDark,
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveReportsTab(allReportsAsync, isDark, isSmallScreen),
                _buildArchivedReportsTab(
                  allReportsAsync,
                  isDark,
                  isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    bool isDark,
    bool isSmallScreen,
    AsyncValue<ReportStatistics> statsAsync,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: false,
      elevation: 0,
      leading: Container(),
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => context.pop(),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staff Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Monitor & Manage Reports',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.invalidate(allReportsProvider),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(statsAsync, isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<ReportStatistics> statsAsync,
    bool isSmallScreen,
  ) {
    return statsAsync.when(
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox(),
      data: (stats) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              '${stats.total}',
              Icons.cases_rounded,
              Colors.white,
              isSmallScreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Open',
              '${stats.open}',
              Icons.warning_rounded,
              const Color(0xFFEF4444),
              isSmallScreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Progress',
              '${stats.inProgress}',
              Icons.pending_rounded,
              const Color(0xFFFBBF24),
              isSmallScreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Closed',
              '${stats.closed}',
              Icons.check_circle_rounded,
              const Color(0xFF10B981),
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 10,
        horizontal: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark, bool isSmallScreen) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search reports by name, ID, location...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF10B981),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Icons.all_inclusive),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Assigned to Me',
                  'assigned',
                  Icons.person_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Unassigned',
                  'unassigned',
                  Icons.assignment_late_rounded,
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 30,
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                _buildSortChip('Recent', 'recent', Icons.access_time_rounded),
                const SizedBox(width: 8),
                _buildSortChip('Oldest', 'oldest', Icons.history_rounded),
                const SizedBox(width: 8),
                _buildSortChip(
                  'Priority',
                  'priority',
                  Icons.priority_high_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : const Color(0xFF10B981),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFilter = value),
      selectedColor: const Color(0xFF10B981),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF10B981),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.3)),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _selectedSort == value;
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onPressed: () => setState(() => _selectedSort = value),
      backgroundColor: isSelected
          ? const Color(0xFF6B7280)
          : Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF6B7280),
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      side: BorderSide(color: const Color(0xFF6B7280).withOpacity(0.3)),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    if (count == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveReportsTab(
    AsyncValue<List<Report>> reportsAsync,
    bool isDark,
    bool isSmallScreen,
  ) {
    return reportsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
      error: (error, stack) => _buildErrorState(error, isDark),
      data: (reports) {
        final activeReports = reports
            .where(
              (r) =>
                  r.status == ReportStatus.open ||
                  r.status == ReportStatus.inProgress,
            )
            .toList();

        final filteredReports = _filterAndSortReports(activeReports);

        if (filteredReports.isEmpty) {
          return _buildEmptyState(
            'No Active Reports',
            _searchQuery.isNotEmpty
                ? 'No reports match your search'
                : 'All reports are archived',
            Icons.inbox_rounded,
            isDark,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allReportsProvider);
            await ref.read(allReportsProvider.future);
          },
          color: const Color(0xFF10B981),
          child: ListView.builder(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              return _buildStaffReportCard(
                filteredReports[index],
                isDark,
                isSmallScreen,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildArchivedReportsTab(
    AsyncValue<List<Report>> reportsAsync,
    bool isDark,
    bool isSmallScreen,
  ) {
    return reportsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
      error: (error, stack) => _buildErrorState(error, isDark),
      data: (reports) {
        final archivedReports = reports
            .where(
              (r) =>
                  r.status == ReportStatus.closed ||
                  r.status == ReportStatus.cancelled,
            )
            .toList();

        final filteredReports = _filterAndSortReports(archivedReports);

        if (filteredReports.isEmpty) {
          return _buildEmptyState(
            'No Archived Reports',
            _searchQuery.isNotEmpty
                ? 'No reports match your search'
                : 'No archived reports yet',
            Icons.archive_rounded,
            isDark,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allReportsProvider);
            await ref.read(allReportsProvider.future);
          },
          color: const Color(0xFF10B981),
          child: ListView.builder(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              return _buildStaffReportCard(
                filteredReports[index],
                isDark,
                isSmallScreen,
              );
            },
          ),
        );
      },
    );
  }

  List<Report> _filterAndSortReports(List<Report> reports) {
    var filtered = reports;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.childName.toLowerCase().contains(query) ||
            r.id.toLowerCase().contains(query) ||
            r.lastSeenLocation.toLowerCase().contains(query) ||
            r.childDescription.toLowerCase().contains(query);
      }).toList();
    }

    // Apply assignment filter
    if (_selectedFilter == 'assigned') {
      final currentUser = ref.read(currentUserProvider);
      filtered = filtered
          .where((r) => r.assignedStaffId == currentUser?.id)
          .toList();
    } else if (_selectedFilter == 'unassigned') {
      filtered = filtered.where((r) => r.assignedStaffId == null).toList();
    }

    // Apply sort
    switch (_selectedSort) {
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'priority':
        // Sort by status: open > inProgress > closed > cancelled
        filtered.sort((a, b) {
          final priorityA = a.status == ReportStatus.open ? 0 : 1;
          final priorityB = b.status == ReportStatus.open ? 0 : 1;
          return priorityA.compareTo(priorityB);
        });
        break;
    }

    return filtered;
  }

  Widget _buildStaffReportCard(Report report, bool isDark, bool isSmallScreen) {
    final statusColor = _getStatusColor(report.status);
    final isAssignedToMe =
        report.assignedStaffId == ref.read(currentUserProvider)?.id;

    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 14),
      child: GestureDetector(
        onTap: () => context.push('/report-details/${report.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: isAssignedToMe ? 2 : 1.5,
            ),
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
              // Header
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
                    _buildChildAvatar(
                      report,
                      statusColor,
                      isDark,
                      isSmallScreen,
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 14),
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
                              if (isAssignedToMe)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
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
                                        Icons.person_rounded,
                                        size: 12,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'MINE',
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
                                isSmallScreen,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 4,
                                color: Colors.grey[400],
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
                    // Quick Actions Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF6B7280),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) => _handleStaffAction(value, report),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'assign',
                          child: Row(
                            children: [
                              Icon(Icons.person_add_rounded, size: 18),
                              SizedBox(width: 12),
                              Text('Assign to Me'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 18),
                              SizedBox(width: 12),
                              Text('Change Status'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 18),
                              SizedBox(width: 12),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        if (report.status != ReportStatus.closed)
                          const PopupMenuItem(
                            value: 'close',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 12),
                                Text('Close Report'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.child_care_rounded,
                            '${report.childAge} yrs',
                            isDark,
                            isSmallScreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoChip(
                            report.childGender == 'Male'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            report.childGender,
                            isDark,
                            isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                        'ID: ${report.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (report.assignedStaffId == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_late_rounded,
                              size: 12,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'UNASSIGNED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
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
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
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

  Widget _buildInfoChip(
    IconData icon,
    String text,
    bool isDark,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 10,
        vertical: isSmallScreen ? 6 : 8,
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 14 : 16,
            color: const Color(0xFF059669),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String message,
    IconData icon,
    bool isDark,
  ) {
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
              child: Icon(icon, size: 64, color: const Color(0xFF10B981)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF047857),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, bool isDark) {
    print(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
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
                onPressed: () => ref.invalidate(allReportsProvider),
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
      ),
    );
  }

  void _handleStaffAction(String action, Report report) {
    switch (action) {
      case 'assign':
        _assignToMe(report);
        break;
      case 'status':
        _showChangeStatusDialog(report);
        break;
      case 'view':
        context.push('/report-details/${report.id}');
        break;
      case 'close':
        _showCloseReportDialog(report);
        break;
    }
  }

  Future<void> _assignToMe(Report report) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await ref
          .read(reportsProvider.notifier)
          .assignReportToStaff(report.id, currentUser.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report assigned to you successfully'),
            backgroundColor: Color(0xFF10B981),
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
              const Color(0xFF10B981),
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
          ? const Icon(Icons.check_rounded, color: Color(0xFF10B981))
          : null,
      onTap: isCurrentStatus
          ? null
          : () async {
              Navigator.pop(context);
              await _changeStatus(report, status);
            },
    );
  }

  Future<void> _changeStatus(Report report, ReportStatus newStatus) async {
    try {
      await ref
          .read(reportsProvider.notifier)
          .updateReportStatus(report.id, newStatus.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status changed to ${_getStatusText(newStatus)}'),
            backgroundColor: const Color(0xFF10B981),
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
              Navigator.pop(context);
              await _closeReport(report, notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeReport(Report report, String notes) async {
    try {
      await ref.read(reportsProvider.notifier).closeReport(report.id, notes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report closed successfully'),
            backgroundColor: Color(0xFF10B981),
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
        return const Color(0xFF10B981);
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

// Custom Tab Bar Delegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate({required this.tabBar, required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

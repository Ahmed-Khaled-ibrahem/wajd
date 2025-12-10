import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wajd/services/supabase_cleint.dart';
import '../models/report_model.dart';

final allReportsProvider = FutureProvider<List<Report>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('reports')
      .select()
      .order('created_at', ascending: false);

  return (response as List)
      .map((e) => Report.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Active reports provider
final activeReportsProvider = FutureProvider<List<Report>>((ref) async {
  final notifier = ref.read(reportsProvider.notifier);
  return await notifier.fetchActiveReports();
});

// Reports state provider
final reportsProvider =
StateNotifierProvider<ReportsNotifier, AsyncValue<List<Report>>>((ref) {
  final notifier = ReportsNotifier(ref);

  // Listen for user changes
  ref.listen(currentUserProvider, (previous, next) {
    if (next != null && previous?.id != next.id) {
      // 👇 Schedule after build to avoid modifying during initialization
      Future.microtask(() => notifier.fetchUserReports(next.id));
    }
  });

  // Optionally, trigger once if already logged in user exists
  final user = ref.read(currentUserProvider);
  if (user != null) {
    Future.microtask(() => notifier.fetchUserReports(user.id));
  }

  return notifier;
});

// Report filters provider
final reportFiltersProvider = StateProvider<ReportFilters>((ref) {
  return ReportFilters();
});

// Filtered reports provider
final filteredReportsProvider = Provider<List<Report>>((ref) {
  final reportsAsync = ref.watch(reportsProvider);
  final filters = ref.watch(reportFiltersProvider);

  return reportsAsync.maybeWhen(
    data: (reports) {
      var filtered = reports;

      // Apply status filter
      if (filters.status != null) {
        filtered = filtered
            .where((report) => report.status == filters.status)
            .toList();
      }

      // Apply date range filter
      if (filters.startDate != null) {
        filtered = filtered
            .where((report) => report.createdAt.isAfter(filters.startDate!))
            .toList();
      }

      if (filters.endDate != null) {
        filtered = filtered
            .where((report) => report.createdAt.isBefore(filters.endDate!))
            .toList();
      }

      // Apply search query
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final query = filters.searchQuery!.toLowerCase();
        filtered = filtered.where((report) {
          return report.childName.toLowerCase().contains(query) ||
              report.childDescription.toLowerCase().contains(query) ||
              report.lastSeenLocation.toLowerCase().contains(query);
        }).toList();
      }

      // Sort reports
      filtered.sort((a, b) {
        switch (filters.sortBy) {
          case SortBy.dateDesc:
            return b.createdAt.compareTo(a.createdAt);
          case SortBy.dateAsc:
            return a.createdAt.compareTo(b.createdAt);
          case SortBy.status:
            return a.status.index.compareTo(b.status.index);
        }
      });

      return filtered;
    },
    orElse: () => [],
  );
});

class ReportsNotifier extends StateNotifier<AsyncValue<List<Report>>> {
  final Ref _ref;
  late final SupabaseClient _client;

  ReportsNotifier(this._ref) : super(const AsyncValue.data([])) {
    _client = _ref.read(supabaseClientProvider);
  }

  Future<List<Report>> fetchUserReports(String userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('reports')
          .select()
          .eq('reporter_id', userId)
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json))
          .toList();

      state = AsyncValue.data(reports);
      return reports;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<List<Report>> fetchAllReports() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json))
          .toList();

      state = AsyncValue.data(reports);
      return reports;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<List<Report>> fetchActiveReports() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('reports')
          .select()
          .inFilter('status', ['open', 'inProgress'])
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json))
          .toList();

      state = AsyncValue.data(reports);
      return reports;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<List<Report>> fetchStaffAssignedReports(String staffId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('reports')
          .select()
          .eq('assigned_staff_id', staffId)
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((json) => Report.fromJson(json))
          .toList();

      state = AsyncValue.data(reports);
      return reports;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }

  Future<Report?> createReport(Report report) async {
    try {
      final response = await _client
          .from('reports')
          .insert(report.toJson())
          .select()
          .single();

      final newReport = Report.fromJson(response);

      // Update local state
      final currentReports = state.value ?? [];
      state = AsyncValue.data([newReport, ...currentReports]);

      return newReport;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> updateReport(Report report) async {
    try {
      await _client.from('reports').update(report.toJson()).eq('id', report.id);

      // Update local state
      final currentReports = state.value ?? [];
      final updatedReports = currentReports.map((r) {
        return r.id == report.id ? report : r;
      }).toList();

      state = AsyncValue.data(updatedReports);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> assignReportToStaff(String reportId, String staffId) async {
    try {
      await _client
          .from('reports')
          .update({
            'assigned_staff_id': staffId,
            'status': 'inProgress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);

      // Refresh reports
      await fetchAllReports();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> closeReport(String reportId, String closureNotes) async {
    try {
      await _client
          .from('reports')
          .update({
            'status': 'closed',
            'closure_notes': closureNotes,
            'closed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);

      // Refresh reports
      await fetchAllReports();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadReportImage(String reportId, File image) async {
    try {
      final fileName =
          'report_$reportId${DateTime.now().millisecondsSinceEpoch}';
      final imageInBytes = await image.readAsBytes();
      final response = await _client.storage
          .from('report-images')
          .uploadBinary(fileName, imageInBytes);

      if (response.isNotEmpty) {
        final imageUrl = _client.storage
            .from('report-images')
            .getPublicUrl(fileName);
        return imageUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  updateReportStatus(String reportId, String status) async {
    try {
      await _client
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);

      await fetchAllReports();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Single report provider
final reportByIdProvider = FutureProvider.family<Report?, String>((
  ref,
  reportId,
) async {
  final client = ref.watch(supabaseClientProvider);
  final rep = ref.watch(reportsProvider);
  try {
    final response = await client
        .from('reports')
        .select()
        .eq('id', reportId)
        .single();

    return Report.fromJson(response);
  } catch (e) {
    return null;
  }
});

final reportStatisticsProvider = FutureProvider<ReportStatistics>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  ref.watch(allReportsProvider);

  try {
    final totalReports = await client
        .from('reports')
        .select('id')
        .count(CountOption.exact);

    final openReports = await client
        .from('reports')
        .select('id')
        .eq('status', 'open')
        .count(CountOption.exact);

    final closedReports = await client
        .from('reports')
        .select('id')
        .eq('status', 'closed')
        .count(CountOption.exact);

    final inProgressReports = await client
        .from('reports')
        .select('id')
        .eq('status', 'inProgress')
        .count(CountOption.exact);

    return ReportStatistics(
      total: totalReports.count ?? 0,
      open: openReports.count ?? 0,
      closed: closedReports.count ?? 0,
      inProgress: inProgressReports.count ?? 0,
    );
  } catch (e) {
    return ReportStatistics.empty();
  }
});

// Report Filters Model
class ReportFilters {
  final ReportStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final SortBy sortBy;

  ReportFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.sortBy = SortBy.dateDesc,
  });

  ReportFilters copyWith({
    ReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    SortBy? sortBy,
  }) {
    return ReportFilters(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SortBy { dateDesc, dateAsc, status }

// Report Statistics Model
class ReportStatistics {
  final int total;
  final int open;
  final int closed;
  final int inProgress;

  ReportStatistics({
    required this.total,
    required this.open,
    required this.closed,
    required this.inProgress,
  });

  factory ReportStatistics.empty() {
    return ReportStatistics(total: 0, open: 0, closed: 0, inProgress: 0);
  }
}

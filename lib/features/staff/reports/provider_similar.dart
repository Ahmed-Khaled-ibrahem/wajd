import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wajd/models/report_model.dart';
import '../../../providers/report_provider.dart';

// Provider to get similar reports based on age
final similarReportsByAgeProvider = FutureProvider.family<List<Report>, SimilarReportsParams>(
      (ref, params) async {
    final allReports = await ref.watch(allReportsProvider.future);

    // Filter reports by age range (±2 years) and exclude current report
    final similarReports = allReports.where((report) {
      // Exclude the current report
      if (report.id == params.excludeId) return false;

      // Check if age is within range (±2 years)
      final ageDifference = (report.childAge - params.age).abs();
      if (ageDifference > 2) return false;

      // Only show active reports (open or in progress)
      if (report.status != ReportStatus.open &&
          report.status != ReportStatus.inProgress) return false;

      return true;
    }).toList();

    // Sort by most recent first
    similarReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Limit to top 10 most recent
    return similarReports.take(10).toList();
  },
);

// Parameters class for similar reports
class SimilarReportsParams {
  final int age;
  final String excludeId;

  const SimilarReportsParams({
    required this.age,
    required this.excludeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SimilarReportsParams &&
              runtimeType == other.runtimeType &&
              age == other.age &&
              excludeId == other.excludeId;

  @override
  int get hashCode => age.hashCode ^ excludeId.hashCode;
}

// Extension to make it easier to call
extension SimilarReportsProviderX on Ref {
  AsyncValue<List<Report>> watchSimilarReports({
    required int age,
    required String excludeId,
  }) {
    return watch(
      similarReportsByAgeProvider(
        SimilarReportsParams(age: age, excludeId: excludeId),
      ),
    );
  }
}
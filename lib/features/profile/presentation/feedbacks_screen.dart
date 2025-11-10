import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wajd/models/feedback_model.dart';
import 'package:wajd/services/feedback_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wajd/app/const/colors.dart';

class FeedbacksScreen extends ConsumerWidget {
  const FeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackService = FeedbackService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('User Feedbacks'), centerTitle: false),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: feedbackService.getAllFeedbacks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final feedbacks = snapshot.data ?? [];

          if (feedbacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No feedbacks yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFeedbackAnalyticsCard(
                totalFeedbacks: feedbacks.length,
                averageRating:
                    feedbacks.fold<double>(0, (sum, feedback) {
                      return sum + feedback.rating;
                    }).isFinite
                    ? feedbacks.fold<double>(0, (sum, feedback) {
                            return sum + feedback.rating;
                          }) /
                          feedbacks.length
                    : 0,

                newFeedbacks: feedbacks
                    .where((feedback) => !feedback.isRead)
                    .length,
              ),
              ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  return _buildFeedbackCard(context, feedback, feedbackService);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedbackAnalyticsCard({
    required int totalFeedbacks,
    required double averageRating,
    required int newFeedbacks,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = true;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient:  LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.gradientColor,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Feedbacks Overview',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactStatItem(
                          icon: Icons.feedback_rounded,
                          label: 'Total Feedback',
                          value: totalFeedbacks.toString(),
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: const Color(0xFFE5E7EB),
                      ),
                      Expanded(
                        child: _buildCompactStatItem(
                          icon: Icons.star_rounded,
                          label: 'Average Rating',
                          value: '${averageRating.toStringAsFixed(1)} / 5',
                          isSmallScreen: isSmallScreen,
                          iconColor: const Color(0xFFF59E0B),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: const Color(0xFFE5E7EB),
                      ),
                      Expanded(
                        child: _buildCompactStatItem(
                          icon: Icons.mark_email_unread_rounded,
                          label: 'New Feedback',
                          value: newFeedbacks.toString(),
                          isSmallScreen: isSmallScreen,
                          showBadge: newFeedbacks > 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
    Color? iconColor,
    bool showBadge = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 0 : 12,
        vertical: isSmallScreen ? 0 : 8,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconColor != null
                        ? [
                            iconColor.withOpacity(0.2),
                            iconColor.withOpacity(0.1),
                          ]
                        : [
                      AppColors.primaryColor.withOpacity(0.2),
                      AppColors.primaryColor.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryColor,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(
    BuildContext context,
    FeedbackModel feedback,
    FeedbackService service,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final timeAgo = feedback.createdAt != null
        ? timeago.format(feedback.createdAt!)
        : 'Recently';

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: feedback.isRead
              ? [Colors.white, const Color(0xFFF9FAFB)]
              : [
            AppColors.primaryColor.withOpacity(0.05),
            AppColors.primaryColor.withOpacity(0.02),
                ],
        ),
        border: Border.all(
          color: feedback.isRead
              ? AppColors.primaryColor
              : AppColors.primaryColor.withOpacity(0.3),
          width: feedback.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: feedback.isRead
                ? Colors.black.withOpacity(0.04)
                : AppColors.primaryColor.withOpacity(0.1),
            blurRadius: feedback.isRead ? 8 : 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!feedback.isRead) {
              service.markAsRead(feedback.id ?? '');
            }
            _showFeedbackDetails(context, feedback, service);
          },
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primaryColor.withOpacity(0.08),
          highlightColor: AppColors.primaryColor.withOpacity(0.04),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    // Avatar with gradient
                    Container(
                      width: isSmallScreen ? 48 : 52,
                      height: isSmallScreen ? 48 : 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: feedback.isRead
                              ? [
                                  const Color(0xFFD1FAE5),
                                  const Color(0xFFA7F3D0),
                                ]
                              : [
                            AppColors.primaryColor,
                            AppColors.primaryColor,
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: feedback.isRead
                            ? AppColors.primaryColor
                            : Colors.white,
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  feedback.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 15 : 17,
                                    color: AppColors.primaryColor,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!feedback.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:  LinearGradient(
                                      colors: [
                                        AppColors.primaryColor,
                                        AppColors.primaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 9 : 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feedback.userEmail,
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: isSmallScreen ? 12 : 13,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Time Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: isSmallScreen ? 10 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 14 : 16),

                // Message Container
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.message_rounded,
                          size: isSmallScreen ? 14 : 16,
                          color:AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feedback.message.length > 100
                              ? '${feedback.message.substring(0, 100)}...'
                              : feedback.message,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: const Color(0xFF374151),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 14),

                // Footer with Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rating Display
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFBBF24).withOpacity(0.2),
                            const Color(0xFFF59E0B).withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFBBF24).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: const Color(0xFFF59E0B),
                            size: isSmallScreen ? 18 : 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            feedback.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 15,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '/5',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tap to view indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: isSmallScreen ? 14 : 16,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetails(
    BuildContext context,
    FeedbackModel feedback,
    FeedbackService service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      feedback.userEmail,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Rating',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${feedback.rating.toStringAsFixed(1)} / 5.0',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Message',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(feedback.message),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, feedback, service);
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.red.shade300),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                // const SizedBox(width: 12),
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: () {
                //       Navigator.pop(context);
                //       if (!feedback.isRead) {
                //         service.markAsRead(feedback.id ?? '');
                //       }
                //     },
                //     icon: const Icon(Icons.check, size: 20),
                //     label: Text(
                //       feedback.isRead ? 'Marked as Read' : 'Mark as Read',
                //     ),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.primaryColor,
                //       padding: const EdgeInsets.symmetric(vertical: 14),
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FeedbackModel feedback,
    FeedbackService service,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.deleteFeedback(feedback.id ?? "");
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wajd/models/feedback_model.dart';

class FeedbackService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'feedbacks';

  // Add new feedback
  Future<void> addFeedback(FeedbackModel feedback) async {
    try {
      await _supabase
          .from(_tableName)
          .insert(feedback.toJson())
          .maybeSingle();
    } catch (e) {
      throw Exception('Failed to add feedback: $e');
    }
  }

  // Get all feedbacks (for admin)
  Stream<List<FeedbackModel>> getAllFeedbacks() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => FeedbackModel.fromJson(json))
            .toList()
            .cast<FeedbackModel>());
  }

  // Mark feedback as read
  Future<void> markAsRead(String feedbackId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({'is_read': true})
          .eq('id', feedbackId);
    } catch (e) {
      throw Exception('Failed to update feedback status: $e');
    }
  }

  // Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', feedbackId);
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }
}


import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

final localStorageProvider = Provider((ref) => LocalStorageService());

class LocalStorageService {
  static const String _userProfileKey = 'user_profile';
  static const String _emailKey = 'saved_email';

  // Save User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(profile.toJson());
    await prefs.setString(_userProfileKey, json);
  }

  // Get User Profile
  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userProfileKey);
    if (json != null) {
      return UserProfile.fromJson(jsonDecode(json));
    }
    return null;
  }

  // Clear User Profile
  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
  }

  // Save Email for Magic Link
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  // Get Saved Email
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Clear Email
  Future<void> clearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
  }
}
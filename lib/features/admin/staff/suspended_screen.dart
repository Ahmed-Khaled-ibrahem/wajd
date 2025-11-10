import 'package:flutter/material.dart';
import 'package:wajd/app/providers/all_app_provider.dart';

import '../../../app/const/colors.dart';
import '../../login/controller/auth_controller.dart';

class SuspendedScreenV2 extends StatefulWidget {
  const SuspendedScreenV2({super.key});

  @override
  State<SuspendedScreenV2> createState() => _SuspendedScreenV2State();
}

class _SuspendedScreenV2State extends State<SuspendedScreenV2> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Account Suspended'),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with pulse animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.95, end: 1.05),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, double value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  onEnd: () => setState(() {}),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.no_accounts_rounded,
                      size: 80,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                const Text(
                  'Access Suspended',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your account access has been temporarily restricted',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () {
                    globalContainer
                        .read(authControllerProvider.notifier)
                        .signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

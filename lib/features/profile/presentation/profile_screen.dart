import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wajd/app/const/colors.dart';
import 'package:wajd/features/login/controller/auth_controller.dart';
import 'package:wajd/models/auth_state.dart';
import 'package:wajd/models/user_profile.dart';
import '../../login/controller/current_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(currentUserProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String userName = 'User';
    String? imageUrl;
    String? email;
    UserRole role = UserRole.parent;

    if (authState is AuthAuthenticated) {
      userName = profile?.name ?? '';
      imageUrl = profile?.profileImageUrl;
      email = profile?.email;
      role = profile?.role ?? UserRole.parent;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, size: 50),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      border: Border.all(
                        color: isDark ? Colors.black26 : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (email != null) ...{
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            },
            const SizedBox(height: 2),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: const Radius.circular(8),
                  bottomRight: const Radius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  role.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Options
            _buildProfileOption(
              context,
              icon: Iconsax.profile_2user,
              title: 'Edit Profile',
              onTap: () {
                context.push('/edit-profile');
              },
            ),

            // Builder(
            //   builder: (context) {
            //     if (role == UserRole.admin) {
            //       return _buildProfileOption(
            //         context,
            //         icon: Icons.feedback_outlined,
            //         title: 'Users Feedbacks',
            //         onTap: () {
            //           context.push('/all-feedbacks');
            //         },
            //       );
            //     }
            //     return _buildProfileOption(
            //       context,
            //       icon: Iconsax.message_question,
            //       title: 'Help & Support',
            //       onTap: () {
            //         context.push('/help-support');
            //       },
            //     );
            //   },
            // ),

            // _buildProfileOption(
            //   context,
            //   icon: Iconsax.info_circle,
            //   title: 'About App',
            //   onTap: () {
            //     showAboutDialog(
            //       context: context,
            //       applicationName: 'Wajd',
            //       applicationVersion: '2.1.0',
            //       children: [const Text('A child safety application.')],
            //     );
            //   },
            // ),
            const SizedBox(height: 24),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                icon: const Icon(Iconsax.logout_1),
                label: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryColor),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wajd/features/staff/home/staff_home_screen.dart';
import '../../admin/staff/suspended_screen.dart';
import '../../login/controller/current_profile_provider.dart';
import '../../profile/presentation/profile_screen.dart';

class StaffLayout extends ConsumerStatefulWidget {
  const StaffLayout({super.key});
  @override
  ConsumerState<StaffLayout> createState() => _ParentLayoutState();
}

class _ParentLayoutState extends ConsumerState<StaffLayout> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    StaffHomeScreen(),
    // const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended =
        ref.watch(currentUserProfileProvider)?.metadata?['status'] == 'suspended';

    if (isSuspended) {
      return const SuspendedScreenV2();
    }

    return Scaffold(
      body: _screens.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.notifications),
          //   label: 'Notifications',
          // ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

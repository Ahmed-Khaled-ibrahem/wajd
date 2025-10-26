import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../login/controller/auth_controller.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});
  @override
  ConsumerState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Home'),
        actions: [
          ElevatedButton(onPressed: (){
            ref.read(authControllerProvider.notifier).signOut();
          }, child: const Text('Logout'))
        ],
      ),

    );
  }
}

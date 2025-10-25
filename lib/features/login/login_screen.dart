import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/const/colors.dart';
import '../../services/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authController = ref.watch(authControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? AppColors.backgroundGradDark : AppColors.backgroundGrad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Form(
            key: formKey,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.transparent :  Colors.white.withOpacity(0.4),
                              spreadRadius: 20,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        // child: Image.asset("assets/images/logo.png", height: 150),
                      ),
                      const SizedBox(height: 30),
                       Text(
                        "Welcome !".tr(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        validator: (value){
                          if(value == null || value.isEmpty){
                            return 'Please enter your email'.tr();
                          }
                          if(!value.contains('@')){
                            return 'Please enter a valid email'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Email".tr(),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: true,
                        controller: passwordController,
                        validator: (value){
                          if(value == null || value.isEmpty){
                            return 'Please enter a password'.tr();
                          }
                          if(value.length < 6){
                            return 'Password must be at least 6 characters'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: "Password".tr(),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push('/reset-password');
                          },
                          child: Text(
                            "Forgot Password?".tr(),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          authController.signInWithEmail(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );
                        },
                        child:  Text("Sign in".tr()),
                      ),
                      const SizedBox(height: 30),
                       Text(
                        "Don't Have an Account?".tr(),
                      ),
                      TextButton(
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: Colors.white,
                          foregroundColor: Colors.purpleAccent,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          context.push('/signup');
                        },
                        child:  Text("Create Account".tr()),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

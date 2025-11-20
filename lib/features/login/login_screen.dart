import 'dart:io';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/const/colors.dart';
import '../../models/auth_state.dart';
import 'controller/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  LoginScreen({super.key});
  final isLinux = Platform.isLinux;
  @override
  ConsumerState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = authState is AuthLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildWelcomeText(isDark),
                    const SizedBox(height: 8),
                    _buildSubtitleText(isDark),
                    const SizedBox(height: 40),
                    _buildEmailField(isDark),
                    const SizedBox(height: 16),
                    _buildPasswordField(isDark, authController),
                    const SizedBox(height: 25),
                    // _buildForgotPasswordButton(),
                    // const SizedBox(height: 32),
                    _buildSignInButton(isLoading, authController),
                    const SizedBox(height: 24),
                    _buildDivider(isDark),
                    const SizedBox(height: 12),
                    _buildSignUpSection(isDark),
                    const SizedBox(height: 20),
                    widget.isLinux ? _buildKiosikSection(isDark) : const SizedBox(),
                    SizedBox(height: 20,)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: CircleAvatar(
        radius: 100,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            "assets/images/logo.png",
            fit: BoxFit.cover,
          ),
        ),
      )
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Text(
       "Welcome Back!".tr(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitleText(bool isDark) {
    return Text(
      "Sign in to continue".tr(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white70 : Colors.grey[600],
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildEmailField(bool isDark) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: "Email".tr(),
        hintText: "Enter your email".tr(),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: isDark ? Colors.white70 : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : Colors.grey[200]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:  BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email'.tr();
        }
        if (!value.contains('@') || !value.contains('.')) {
          return 'Please enter a valid email'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isDark, authController) {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: "Password".tr(),
        hintText: "Enter your password".tr(),
        prefixIcon: Icon(
          Icons.lock_outlined,
          color: isDark ? Colors.white70 : Colors.grey[600],
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : Colors.grey[200]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:  BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password'.tr();
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters'.tr();
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleSignIn(authController),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.push('/reset-password'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        child: Text(
          "Forgot Password?".tr(),
          style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(bool isLoading, AuthController authController) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.86)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleSignIn(authController),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          "Sign In".tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.white24 : Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "or".tr(),
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white24 : Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?".tr(),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/signup'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text(
            "Sign Up".tr(),
            style:  TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSignIn(AuthController authController) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    authController.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  Widget _buildKiosikSection(bool isDark) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 6),
          curve: Curves.easeInOut,
          onEnd: () {
            // Force rebuild to repeat animation
          },
          builder: (context, value, child) {
            final glowValue = sin(value * 2 * pi);
            final glowOpacity = 0.4 + (glowValue * 0.4);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(glowOpacity * 0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Main button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(glowOpacity),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.push('/report_other_child'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.green.shade300.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade300,
                            Colors.green.shade500,
                            Colors.green.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.7 + glowValue * 0.3),
                                  Colors.white,
                                ],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.report_problem_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Quick Report".tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.white,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
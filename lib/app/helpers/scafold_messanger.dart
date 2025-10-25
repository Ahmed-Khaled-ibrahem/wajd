import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

class SnackbarService {
  void showMessage(String message, {Color? backgroundColor}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  void showToast(String message) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      title: Text(message),
      // description: RichText(text: const TextSpan(text: 'This is a sample toast message. ')),
      alignment: Alignment.topCenter,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      icon: const Icon(Icons.check),
      showIcon: true, // show or hide the icon
      primaryColor: Colors.green,
      // backgroundColor: Colors.white,
      // foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 16,
          offset: Offset(0, 16),
          spreadRadius: 0,
        )
      ],
      // showProgressBar: true,
      // closeButton: ToastCloseButton(
      //   showType: CloseButtonShowType.onHover,
      //   buttonBuilder: (context, onClose) {
      //     return OutlinedButton.icon(
      //       onPressed: onClose,
      //       icon: const Icon(Icons.close, size: 20),
      //       label: const Text('Close'),
      //     );
      //   },
      // ),
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
    );
  }


}

// example of usage

// SnackbarService().showMessage(
// "Hello from SnackbarService 🎉",
// backgroundColor: Colors.green,
// );


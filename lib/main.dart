import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app/providers/all_app_provider.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Supabase.initialize(
        url: 'https://oagdbgjivuawxyauknrx.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hZ2RiZ2ppdnVhd3h5YXVrbnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0NTA0NzMsImV4cCI6MjA3NzAyNjQ3M30.84X3sBjgJJtgS110Ujmd_QWj2yfll9jKjB8zmPNRW3M',
      );

      await EasyLocalization.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Center(
          child: Text(
            "Something went wrong 😢",
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        );
      };

      runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: globalContainer,
            child: App(),
          ),
        ),
      );
    },
    (error, stack) {
      print("Uncaught async error: $error");
      print(stack);
    },
  );
}

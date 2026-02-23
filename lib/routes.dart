import 'package:flutter/material.dart';
import 'package:zephyron/splash.dart';
import 'package:zephyron/auth/index.dart';
import 'package:zephyron/auth/middleware.dart';
import 'package:zephyron/auth/reset.dart';
import 'package:zephyron/dashboard/index.dart';

/// Application route definitions.
///
/// Maps route paths to their corresponding screen widget builders
/// for MaterialApp's navigation system.
final Map<String, WidgetBuilder> routes = {
  /// Splash screen displayed when the application launches.
  '/': (context) => const SplashScreen(),

  /// Authentication screen for user login and registration.
  '/auth': (context) => const AuthScreen(),

  /// Email verification middleware for authentication flow.
  '/auth/middleware': (context) => const MiddlewareScreen(),

  /// Password reset screen for account recovery.
  '/auth/reset': (context) => const AccountResetScreen(),

  /// Main application screen after successful authentication.
  '/dashboard': (context) => const DashboardScreen(),
};

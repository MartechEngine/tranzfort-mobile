import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/presentation/screens/otp_screen.dart';
import '../../auth/presentation/screens/role_selection_screen.dart';
import '../../auth/presentation/screens/profile_setup_screen.dart';
import '../../supplier/presentation/screens/supplier_home_screen.dart';
import '../../supplier/presentation/screens/post_load_screen.dart';
import '../../trucker/presentation/screens/trucker_home_screen.dart';
import '../../trucker/presentation/screens/find_load_screen.dart';
import '../../chat/presentation/screens/chat_list_screen.dart';
import '../../chat/presentation/screens/chat_thread_screen.dart';
import '../../verification/presentation/screens/verification_center_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) {
        final role = state.extra as String? ?? 'SUPPLIER';
        return ProfileSetupScreen(role: role);
      },
    ),
    GoRoute(
      path: '/supplier-home',
      builder: (context, state) => const SupplierHomeScreen(),
    ),
    GoRoute(
      path: '/post-load',
      builder: (context, state) => const PostLoadScreen(),
    ),
    GoRoute(
      path: '/trucker-home',
      builder: (context, state) => const TruckerHomeScreen(),
    ),
    GoRoute(
      path: '/find-load',
      builder: (context, state) => const FindLoadScreen(),
    ),
    GoRoute(
      path: '/chat-list',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat-thread/:chatId',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        return ChatThreadScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: '/verification-center',
      builder: (context, state) => const VerificationCenterScreen(),
    ),
    // TODO: Add more routes as we develop
  ],
);

import 'package:go_router/go_router.dart';
import '../../ui/modules/splash/splash_screen.dart';
import '../../ui/modules/authentication/login_screen.dart';
import '../../ui/modules/authentication/account_type_screen.dart';
import '../../ui/modules/authentication/citizen_form_screen.dart';
import '../../ui/modules/home/home_screen.dart';
import '../../ui/modules/profile/profile_screen.dart';
import '../../ui/modules/messaging/messages_screen.dart';
import '../../ui/modules/appointment/appointments_screen.dart';
import '../../ui/modules/resources/resources_screen.dart';
import '../../ui/modules/community/community_screen.dart';
import '../../ui/modules/support/support_screen.dart';

// Clean router configuration for Sainte app
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/test',
        name: 'test',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/account-type',
        name: 'account-type',
        builder: (context, state) => const AccountTypeScreen(),
      ),
      GoRoute(
        path: '/citizen-form',
        name: 'citizen-form',
        builder: (context, state) => const CitizenFormScreen(),
      ),
      GoRoute(
        path: '/mentor-form',
        name: 'mentor-form',
        builder: (context, state) => const HomeScreen(), // TODO: Create mentor form
      ),
      GoRoute(
        path: '/admin-form',
        name: 'admin-form',
        builder: (context, state) => const HomeScreen(), // TODO: Create admin form
      ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/appointments',
            name: 'appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/resources',
            name: 'resources',
            builder: (context, state) => const ResourcesScreen(),
          ),
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: '/support',
            name: 'support',
            builder: (context, state) => const SupportScreen(),
          ),
        ],
      );
    }
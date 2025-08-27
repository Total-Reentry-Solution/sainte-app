import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/di/get_it.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_bloc.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_cubit.dart';
import 'package:reentry/ui/modules/admin/admin_stat_cubit.dart';
import 'package:reentry/ui/modules/appointment/appointment_graph/appointment_graph_cubit.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_bloc.dart';
import 'package:reentry/ui/modules/authentication/bloc/onboarding_cubit.dart';
// import 'package:reentry/ui/modules/blog/bloc/blog_bloc.dart';
// import 'package:reentry/ui/modules/blog/bloc/blog_cubit.dart';
import 'package:reentry/ui/modules/careTeam/bloc/care_team_profile_cubit.dart';
import 'package:reentry/ui/modules/citizens/bloc/citizen_profile_cubit.dart';
import 'package:reentry/ui/modules/clients/bloc/client_bloc.dart';
import 'package:reentry/ui/modules/clients/bloc/client_cubit.dart';
import 'package:reentry/ui/modules/clients/bloc/client_profile_cubit.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_bloc.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_cubit.dart';
import 'package:reentry/ui/modules/incidents/cubit/report_cubit.dart';
import 'package:reentry/ui/modules/messaging/bloc/conversation_cubit.dart';
import 'package:reentry/ui/modules/organizations/cubit/organization_cubit.dart';
import 'package:reentry/ui/modules/profile/bloc/profile_cubit.dart';
import 'package:reentry/ui/modules/root/cubit/feelings_cubit.dart';
import 'package:reentry/ui/modules/shared/cubit/admin_cubit.dart';
import 'package:reentry/ui/modules/shared/cubit/fetch_users_list_cubit.dart';
import 'package:reentry/ui/modules/splash/splash_screen.dart';
import 'package:reentry/ui/modules/verification/bloc/submit_verification_question_cubit.dart';
import 'package:reentry/ui/modules/verification/bloc/verification_question_bloc.dart';
import 'package:reentry/ui/modules/verification/bloc/verification_question_cubit.dart';
import 'package:reentry/ui/modules/verification/bloc/verification_request_cubit.dart';
import 'core/routes/router.dart';
import 'core/config/supabase_config.dart';
import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for all platforms
  await SupabaseConfig.initialize();
  
  final storage = await HydratedStorage.build(
    storageDirectory: kIsWeb 
        ? HydratedStorage.webStorageDirectory 
        : await getTemporaryDirectory(),
  );
  HydratedBloc.storage = storage;

  setupDi();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _authReady = false;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Always wait for auth state to be determined, don't assume session exists
    _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen((event) {
      if (!_authReady) {
        setState(() {
          _authReady = true;
        });
        _authSubscription?.cancel();
      }
    });
    // Fallback: after a short delay, assume auth state is ready
    Future.delayed(const Duration(seconds: 2), () {
      if (!_authReady) {
        setState(() {
          _authReady = true;
        });
        _authSubscription?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (!_authReady) {
      return MaterialApp(
        title: 'Sainte',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: AppColors.white, fontSize: 14),
            displaySmall: TextStyle(color: AppColors.white, fontSize: 12),
            bodyLarge: TextStyle(color: AppColors.white, fontSize: 16),
            bodySmall: TextStyle(color: AppColors.white, fontSize: 12),
            titleLarge: TextStyle(
              color: AppColors.primary,
              fontSize: 40,
              fontFamily: 'InterBold',
              fontWeight: FontWeight.bold,
            ),
            titleSmall: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontFamily: 'InterBold',
            ),
            titleMedium: TextStyle(color: AppColors.white, fontSize: 20),
          ),
          fontFamily: 'Inter',
        ),
        home: const SplashScreen(),
      );
    }
    return _SupabaseAuthListener(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc()),
          BlocProvider(create: (context) => SubmitVerificationQuestionCubit()),
          BlocProvider(create: (context) => AccountCubit()),
          BlocProvider(create: (context) => OrganizationMembersCubit()),
          BlocProvider(create: (context) => ProfileCubit()),
          BlocProvider(create: (context) => VerificationQuestionBloc()),
          BlocProvider(create: (context) => VerificationQuestionCubit()),
          BlocProvider(create: (context) => VerificationRequestCubit()),
          BlocProvider(create: (context) => GoalCubit()),
          BlocProvider(create: (context) => CareTeamProfileCubit()),
          BlocProvider(create: (context) => ReportCubit()),
          BlocProvider(create: (context) => GoalsBloc()),
          // BlocProvider(create: (context) => MessageCubit()),
          BlocProvider(create: (context) => ConversationUsersCubit()),
          BlocProvider(create: (context) => UserAppointmentCubit()),
          BlocProvider(create: (context) => AppointmentCubit()),
          // BlocProvider(create: (context) => BlogBloc()),
          // BlocProvider(create: (context) => BlogCubit()),
          // BlocProvider(create: (context) => AppointmentGraphCubit()),
          BlocProvider(create: (context) => ActivityBloc()),
          BlocProvider(create: (context) => ActivityCubit()),
          BlocProvider(create: (context) => OnboardingCubit()),
          BlocProvider(create: (context) => ClientBloc()),
          BlocProvider(create: (context) => AdminUsersCubit()),
          BlocProvider(create: (context) => ClientProfileCubit()),
          BlocProvider(create: (context) => OrganizationCubit()),
          BlocProvider(create: (context) => FeelingsCubit()),
          BlocProvider(create: (context) => CitizenProfileCubit()),
          BlocProvider(create: (context) => AdminUserCubitNew()),
          BlocProvider(create: (context) => AdminStatCubit()),
          // BlocProvider(create: (context) => AppointmentGraphCubit()),
          // BlocProvider(create: (context) => UserProfileCubit()),
          BlocProvider(create: (context) => ConversationCubit()),
          BlocProvider(create: (context) => ClientCubit()),
          BlocProvider(create: (context) => AdminCitizenCubit()),
          BlocProvider(create: (context) => FetchUserListCubit()),
          BlocProvider(create: (context) => RecommendedClientCubit()),
        ],
        child: kIsWeb
            ? MaterialApp.router(
                title: 'Sainte',
                debugShowCheckedModeBanner: false,
                themeAnimationDuration: const Duration(
                    seconds: 0, minutes: 0, milliseconds: 0, microseconds: 0),
                themeMode: ThemeMode.dark,
                darkTheme: ThemeData(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: MaterialStateProperty.all(Colors.white),
                      // Color of the scrollbar thumb
                      trackColor:
                          MaterialStateProperty.all(Colors.grey.shade300),
                      // Track color
                      trackBorderColor:
                          MaterialStateProperty.all(Colors.grey.shade400),
                      // Track border color
                      radius: Radius.circular(8),
                      // Rounded corners
                      thickness: MaterialStateProperty.all(6), // Thickness of the scrollbar
                    ),
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: AppColors.primary),
                    useMaterial3: true,
                    appBarTheme:
                        const AppBarTheme(backgroundColor: AppColors.black),
                    primaryColor: AppColors.primary,
                    bottomNavigationBarTheme:
                        const BottomNavigationBarThemeData(
                            backgroundColor: AppColors.black),
                    textTheme: const TextTheme(
                      bodyMedium:
                          TextStyle(color: AppColors.white, fontSize: 14),
                      displaySmall:
                          TextStyle(color: AppColors.white, fontSize: 12),
                      bodyLarge:
                          TextStyle(color: AppColors.white, fontSize: 16),
                      bodySmall:
                          TextStyle(color: AppColors.white, fontSize: 12),
                      titleLarge: TextStyle(
                          color: AppColors.primary,
                          fontSize: 40,
                          fontFamily: 'InterBold',
                          fontWeight: FontWeight.bold),
                      titleSmall: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontFamily: 'InterBold'),
                      titleMedium:
                          TextStyle(color: AppColors.white, fontSize: 20),
                    ),
                    fontFamily: 'Inter'),
                routeInformationParser: AppRouter.router.routeInformationParser,
                routeInformationProvider:
                    AppRouter.router.routeInformationProvider,
                routerDelegate: AppRouter.router.routerDelegate,
              )
            : MaterialApp(
                title: 'Sainte',
                debugShowCheckedModeBanner: false,
                themeMode: ThemeMode.dark,
                darkTheme: ThemeData(
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: AppColors.primary),
                    highlightColor: Colors.white,
                    useMaterial3: true,
                    scrollbarTheme: ScrollbarThemeData(
                        trackColor: MaterialStateProperty.all(Colors.white),
                        trackVisibility: MaterialStateProperty.all(true)),
                    appBarTheme:
                        const AppBarTheme(backgroundColor: AppColors.black),
                    primaryColor: AppColors.primary,
                    bottomNavigationBarTheme:
                        const BottomNavigationBarThemeData(
                            backgroundColor: AppColors.black),
                    textTheme: const TextTheme(
                      bodyMedium:
                          TextStyle(color: AppColors.white, fontSize: 14),
                      displaySmall:
                          TextStyle(color: AppColors.white, fontSize: 12),
                      bodyLarge:
                          TextStyle(color: AppColors.white, fontSize: 16),
                      bodySmall:
                          TextStyle(color: AppColors.white, fontSize: 12),
                      titleLarge: TextStyle(
                          color: AppColors.primary,
                          fontSize: 40,
                          fontFamily: 'InterBold',
                          fontWeight: FontWeight.bold),
                      titleSmall: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontFamily: 'InterBold'),
                      titleMedium:
                          TextStyle(color: AppColors.white, fontSize: 20),
                    ),
                    fontFamily: 'Inter'),
                home: const SplashScreen(),
              ),
      ),
    );
  }
}

class _SupabaseAuthListener extends StatefulWidget {
  final Widget child;
  const _SupabaseAuthListener({required this.child});

  @override
  State<_SupabaseAuthListener> createState() => _SupabaseAuthListenerState();
}

class _SupabaseAuthListenerState extends State<_SupabaseAuthListener> {
  @override
  void initState() {
    super.initState();
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      if (data.event.name == 'signedIn') {
        final userId = data.session?.user.id;
        if (userId != null) {
          final userProfile = await UserRepository().getUserById(userId);
          if (userProfile != null) {
            await PersistentStorage.cacheUserInfo(userProfile);
          }
        }
        // Don't automatically redirect - let the splash screen handle navigation
      } else if (data.event.name == 'signedOut') {
        await PersistentStorage.logout();
        if (mounted) {
          if (kIsWeb) {
            // Only redirect to login on logout
            final context = this.context;
            if (context.mounted) {
              context.goNamed('login');
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

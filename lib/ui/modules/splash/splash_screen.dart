import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/routes/routes.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/di/get_it.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/authentication/signin_options.dart';
import 'package:reentry/ui/modules/root/root_page.dart';
import '../../../generated/assets.dart';
import '../root/mobile_root.dart';

class SplashScreen extends HookWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showButton = useState(false);
    _launchRoot(PersistentStorage pref) async {
      try {
        if (kIsWeb) {
          print('Starting web authentication flow...');
          try {
            context.read<AccountCubit>().readFromLocalStorage();
          } catch (e) {
            print('Error reading from local storage: $e');
            // Clear any corrupted local data
            pref.destroy();
          }
          
          // Add a small delay to ensure cubit state is updated
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if user is actually logged in
          final user = SupabaseConfig.currentUser;
          final accountState = context.read<AccountCubit>().state;
          print('Current user: $user');
          print('Account state: $accountState');
          
          if (user != null && accountState != null) {
            // Check if user has completed onboarding by looking for the special marker
            final hasCompletedOnboarding = accountState.name != '__INCOMPLETE_ONBOARDING__';
            
            if (hasCompletedOnboarding) {
              print('User has completed onboarding, navigating to dashboard');
              context.go(AppRoutes.dashboard.path);
            } else {
              print('User needs to complete identity selection');
              context.go(AppRoutes.accountType.path);
            }
          } else {
            print('No user or account state found, showing login button');
            showButton.value = true;
          }
        } else {
          context.pushRemoveUntil(const MobileRootPage());
        }
      } catch (e) {
        print('Error in _launchRoot: $e');
        print('Stack trace: ${StackTrace.current}');
        // Clear any corrupted data and show login
        try {
          pref.destroy();
        } catch (e2) {
          print('Error clearing storage: $e2');
        }
        showButton.value = true;
      }
    }

    useEffect(() {
      final pref = locator.getAsync<PersistentStorage>();
      Future.delayed(const Duration(seconds: 1, milliseconds: 500))
          .then((value) {
        pref.then((val) {
          final user = val.getUser();
          if (user == null) {
            showButton.value = true;
          } else {
            _launchRoot(val);
          }
        });
      });
    }, []);

    return Scaffold(
        backgroundColor: AppColors.black,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Image.asset(
                Assets.imagesPeople,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(.5),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sainte',
                      style: context.textTheme.titleLarge,
                    ),
                    Text(
                      'For The People\nFor Humanity',
                      style:
                          context.textTheme.bodyLarge?.copyWith(fontSize: 20),
                    ),
                    50.height,
                    if (showButton.value)
                      ConstrainedBox(constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width/2
                      ),child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: PrimaryButton(
                              text: "Test Navigation",
                              onPress: () {
                                context.go('/test');
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: PrimaryButton(
                              text: "Let's get started",
                              onPress: () {
                                if (kIsWeb) {
                                   context.goNamed(AppRoutes.login.name);
                                } else {
                                  context.pushReplace(SignInOptionsScreen());
                                }
                              },
                            ),
                          ),
                        ],
                      ),)
                  ],
                ),
              ).animate().fadeIn(
                  duration: Duration(milliseconds: 500),
                  delay: Duration(seconds: 2))
            ],
          ),
        ));
  }
}

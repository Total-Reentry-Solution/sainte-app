import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/routes/routes.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/shared/share_preference.dart';
import 'package:reentry/di/get_it.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import '../../../generated/assets.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/repository/user/user_repository.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';

class WebSplashScreen extends HookWidget {
  const WebSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
   final showButton = useState(false);
    _launchRoot(PersistentStorage pref) async {
      // final showFeeling = await PersistentStorage.showFeeling();
      // if (showFeeling) {
      //   context.pushRemoveUntil(const FeelingScreen());
      //   return;
      // }

      // Initialize account data before navigating
      await context.read<AccountCubit>().readFromLocalStorage();
      await context.read<AccountCubit>().loadFromCloud();
      context.goNamed(AppRoutes.root.name);
    }

    useEffect(() {
      Future.delayed(const Duration(seconds: 1, milliseconds: 500)).then((_) async {
        showButton.value = true;
        // Optionally cache user info if session exists, but do not redirect
        final supabaseUser = SupabaseConfig.currentUser;
        if (supabaseUser != null) {
          final userProfile = await UserRepository().getUserById(supabaseUser.id);
          if (userProfile != null) {
            await PersistentStorage.cacheUserInfo(userProfile);
          }
        }
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
                width: double.infinity,
                height: double.infinity,
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(.75),
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
                      ConstrainedBox(constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width/2
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: PrimaryButton(
                          minWidth: 200,
                          text: "Let's get started",
                          onPress: () async {
                            // Check if user is logged in
                            final supabaseUser = SupabaseConfig.currentUser;
                            if (supabaseUser != null) {
                              // User is logged in, initialize account data and go to dashboard
                              await context.read<AccountCubit>().readFromLocalStorage();
                              await context.read<AccountCubit>().loadFromCloud();
                              context.goNamed('dashboard');
                            } else {
                              // User is not logged in, go to login
                              context.goNamed(AppRoutes.login.name);
                            }
                          },
                        ),
                      ),)
                  ],
                ),
              ).animate().fadeIn(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(seconds: 2))
            ],
          ),
        )
    );
  }
}

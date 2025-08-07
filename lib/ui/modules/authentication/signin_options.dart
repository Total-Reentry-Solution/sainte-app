import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:reentry/core/extensions.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/main.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/authentication/account_type_screen.dart';
import 'package:reentry/ui/modules/authentication/basic_info_screen.dart';
import 'package:reentry/ui/modules/authentication/bloc/auth_events.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_bloc.dart';
import 'package:reentry/ui/modules/authentication/bloc/onboarding_cubit.dart';
import 'package:reentry/ui/modules/authentication/continue_with_email_screen.dart';
import 'package:reentry/ui/modules/authentication/login_screen.dart';
import 'package:reentry/ui/modules/root/feeling_screen.dart';
import 'package:reentry/ui/modules/root/mobile_root.dart';
import '../../../generated/assets.dart';
import '../../components/buttons/primary_button.dart';
import 'bloc/authentication_state.dart';

class SignInOptionsScreen extends StatelessWidget {
  const SignInOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final vm = context.watch<AuthBloc>();

    return BlocListener<AuthBloc, AuthState>(
      listener: (_, state) {
        if (state is OAuthSuccess) {
          if (state.user == null) {
            final entity = OnboardingEntity(
                email: state.email, id: state.id, password: '');
            context.read<OnboardingCubit>().setOnboarding(entity);
            context.pushRoute(const AccountTypeScreen());
          } else {
            if (state.user?.accountType == AccountType.citizen) {
              if (state.user?.showFeeling() ?? true) {
                context.pushRemoveUntil(const FeelingScreen());
                return;
              }
            }
            context.pushRemoveUntil(const MobileRootPage());
          }
        }
        if (state is AuthError) {
          context.showSnackbarError(state.message);
        }
      },
      child: BaseScaffold(
          isLoading: vm.state is AuthLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sainte',
                style: textTheme.titleLarge,
              ),
              50.height,
              Text(
                'Sign up',
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              20.height,
              Text("Let's get you all set up", style: textTheme.titleSmall),
              20.height,
              PrimaryButton(
                text: 'Sign up with Email',
                enable: true,
                startIcon: SvgPicture.asset(Assets.svgMailOutline),
                onPress: () =>
                    context.pushRoute(const ContinueWithEmailScreen()),
              ),
              15.height,
              PrimaryButton.dark(
                text: 'Sign up with Google',
                enable: true,
                onPress: () {
                  context.read<AuthBloc>().add(SignInWithGoogleEvent());
                },
                startIcon: SvgPicture.asset(Assets.svgGoogle),
              ),
              if (Platform.isIOS) ...[
                15.height,
                PrimaryButton.dark(
                  text: 'Sign up with Apple',
                  onPress: () {
                    context.read<AuthBloc>().add(SignInWithAppleEvent());
                  },
                  startIcon: SvgPicture.asset(Assets.svgApple),
                )
              ],
              40.height,
              GestureDetector(
                onTap: () => context.pushRoute(const LoginScreen()),
                child: Text("Already have an account? Tap to Sign in",
                    style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
              )
            ],
          )),
    );
  }


}

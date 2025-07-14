import 'package:beamer/beamer.dart';
import 'package:easy_animate/animation/pulse_animation.dart';
import 'package:easy_animate/animation/shake_animation.dart';
import 'package:easy_animate/enum/animate_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/routes/routes.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/mood.dart';
import 'package:reentry/data/repository/moods/moods_repository.dart';
import 'package:reentry/data/repository/mood_logs/mood_logs_repository.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/scaffold/onboarding_scaffold.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/root/cubit/feelings_cubit.dart';
import 'package:reentry/ui/modules/root/navigations/home_navigation_screen.dart';
import 'package:reentry/ui/modules/root/root_page.dart';

import '../../../generated/assets.dart';
import 'mobile_root.dart';

class FeelingScreen extends HookWidget {
  const FeelingScreen({super.key, this.onboarding = true});

  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final selectedMood = useState<Mood?>(null);
    final moodsFuture = useMemoized(() => MoodsRepository().getAllMoods());
    final moodsSnapshot = useFuture(moodsFuture);

    return OnboardingScaffold(
      title: "Hello, Welcome!",
      description: "How are you feeling today?",
      showBack: !onboarding,
      children: [
        if (moodsSnapshot.connectionState == ConnectionState.waiting)
          const CircularProgressIndicator(),
        if (moodsSnapshot.hasData)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 30),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: AppColors.white))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "I am feeling...",
                  style: textTheme.bodyMedium,
                ),
                20.height,
                GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, mainAxisSpacing: 20),
                  shrinkWrap: true,
                  children: moodsSnapshot.data!
                      .map<Widget>((mood) => GestureDetector(
                            onTap: () => selectedMood.value = mood,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: selectedMood.value?.id != mood.id
                                      ? null
                                      : const ShapeDecoration(
                                          shape: CircleBorder(), color: AppColors.white),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(mood.icon ?? ''),
                                ),
                                Text(mood.name)
                              ],
                            ),
                          ))
                      .toList(),
                )
              ],
            ),
          ),
        30.height,
        PrimaryButton(
          text: 'Continue',
          enable: selectedMood.value != null,
          onPress: () async {
            if (selectedMood.value == null) {
              return;
            }
            final userId = context.read<AccountCubit>().state?.userId;
            if (userId == null) return;
            await MoodLogsRepository(moodsRepository: MoodsRepository()).insertMoodLog(
              userId: userId,
              moodId: selectedMood.value!.id,
            );
            context.read<FeelingsCubit>().setFeeling();
            if (onboarding) {
              if (kIsWeb) {
                context.popRoute();
              } else {
                context.pushRemoveUntil(const MobileRootPage());
              }
              return;
            }
            context.popRoute();
          },
        )
      ],
    );
  }
}

import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/activity_dto.dart';
import 'package:reentry/data/model/goal_dto.dart';
import 'package:reentry/ui/components/app_check_box.dart';
import 'package:reentry/ui/components/date_dialog.dart';
import 'package:reentry/ui/components/date_time_picker.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_bloc.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_cubit.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_event.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_state.dart';
import 'package:reentry/ui/modules/citizens/component/icon_button.dart';
import '../../../../generated/assets.dart';
import '../../../components/input/dropdownField.dart';
import '../../goals/bloc/goals_cubit.dart';
import '../../goals/bloc/goals_state.dart';
import '../../goals/create_goal_screen.dart';
import '../../../../core/config/supabase_config.dart';

class CreateAcitivityPage extends StatefulWidget {
  const CreateAcitivityPage({super.key});

  @override
  _CreateAcitivityPageState createState() => _CreateAcitivityPageState();
}

class _CreateAcitivityPageState extends State<CreateAcitivityPage> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDate;
  bool _isDaily = false;

  GoalDto? goal;

  @override
  void initState() {
    super.initState();
    final goalCubit = context.read<GoalCubit>();
    if (goalCubit.state.goals.isEmpty) {
      goalCubit.fetchGoals();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCheckboxChanged(bool? value, bool isDaily) {
    setState(() {
      _isDaily = isDaily ? (value ?? false) : !(value ?? false);
    });
  }

  void _onDateSelected(BuildContext context) async {
    context.displayDialog(
      DateTimeDialog(
        onSelect: (result) {
          setState(() {
            _selectedDate = result;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityBloc, ActivityState>(
      listener: (_, state) {
        if (state is CreateActivityError) {
          context.showSnackbarError(state.message);
        }
        if (state is CreateActivitySuccess) {
          context.showSnackbarSuccess("New activity set");
          context.go('/activities');
          context.read<ActivityCubit>().fetchActivities();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.greyDark,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: AppBar(
              backgroundColor: AppColors.greyDark,
              flexibleSpace: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Activities",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.greyWhite,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    CustomIconButton(
                        backgroundColor: AppColors.greyDark,
                        textColor: AppColors.greyWhite,
                        label: "Daily affirmations",
                        borderColor: AppColors.greyWhite,
                        onPressed: () {})
                  ],
                ),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Activity",
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.greyWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  10.height,
                  InputField(
                    hint: "Describe your activity...",
                    radius: 5.0,
                    lines: 6,
                    maxLines: 10,
                    controller: _controller,
                  ),
                  15.height,
                  BlocBuilder<GoalCubit, GoalCubitState>(
                    builder: (context, state) {
                      if (state.goals.isEmpty) {
                        return InkWell(
                          onTap: () {
                            if (kIsWeb) {
                              context.displayDialog(CreateGoalScreen(successCallback: () {
                                Navigator.pop(context);
                              }));
                              return;
                            }
                            context.pushRoute(const CreateGoalScreen());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            width: double.infinity,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                  side: BorderSide(color: AppColors.white)),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(Assets.svgAddButton),
                                const SizedBox(width: 8),
                                Text(
                                  'Create a goal',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return DropdownField<GoalDto>(
                        hint: 'Select a goal',
                        value: goal,
                        items: state.goals
                            .map((e) => DropdownMenuItem<GoalDto>(
                                value: e, child: Text(e.title)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            goal = value;
                          });
                        },
                      );
                    },
                  ),
                  30.height,
                  SizedBox(
                    width: double.infinity,
                    child: CustomIconButton(
                      loading: state is ActivityLoading,
                      loaderColor: AppColors.white,
                      backgroundColor: AppColors.white,
                      textColor: AppColors.black,
                      label: "Create a new activity",
                      onPressed: () async {
                        if (_controller.text.isEmpty) {
                          context.showSnackbarError("Please describe your activity.");
                          return;
                        }
                        if (_selectedDate == null) {
                          context.showSnackbarError("Please select an end date.");
                          return;
                        }
                        if (goal == null) {
                          context.showSnackbarError('Please select a goal');
                          return;
                        }

                        final userId = SupabaseConfig.currentUser?.id;
                        if (userId == null) {
                          context.showSnackbarError('ERROR: User not logged in.');
                          return;
                        }
/*
                        Map<String, dynamic>? response;
                        try {
                          response = await SupabaseConfig.client
                              .from('user_profiles')
                              .select('person_id')
                              .eq('id', userId)
                              .single();
                        } catch (e) {
                          context.showSnackbarError('ERROR: Failed to fetch user profile: ' + e.toString());
                          return;
                        }

                        final personId = response['person_id'] as String?;
                        if (personId == null || personId.isEmpty) {
                          context.showSnackbarError('ERROR: Could not find your person ID. Please log in again.');
                          return;
                        }
*/
                        final event = CreateActivityEvent(
                          title: _controller.text,
                          goalId: goal!.goalId!, // always a valid UUID
                          startDate: DateTime.now().millisecondsSinceEpoch,
                          endDate: _selectedDate!.millisecondsSinceEpoch,
                          frequency: _isDaily ? Frequency.weekly : Frequency.daily,
                          userId: userId,
                        );

                        context.read<ActivityBloc>().add(event);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

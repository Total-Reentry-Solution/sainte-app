import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/routes/routes.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/model/mood.dart';
import 'package:reentry/data/repository/mood_logs/mood_logs_repository.dart';
import 'package:reentry/data/repository/moods/moods_repository.dart';
import 'package:reentry/ui/components/buttons/app_button.dart';
import 'package:reentry/ui/components/container/box_container.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/view_appointments_screen.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/root/component/change_feeling_card_component.dart';
import 'package:reentry/ui/modules/root/component/feeling_list_item.dart';
import 'package:reentry/ui/modules/root/feeling_screen.dart';
import 'package:reentry/ui/modules/verification/bloc/submit_verification_question_cubit.dart';
import 'package:reentry/ui/modules/verification/dialog/verification_form_review_dialog.dart';
import '../../../../generated/assets.dart';
import '../../../components/add_button.dart';
import '../../../components/error_component.dart';
import '../../../components/loading_component.dart';
import '../../activities/bloc/activity_cubit.dart';
import '../../activities/bloc/activity_state.dart';
import '../../activities/components/activity_component.dart';
import '../../admin/admin_stat_cubit.dart';
import '../../admin/admin_stat_state.dart';
import '../../appointment/component/appointment_component.dart';
import '../../profile/profile_screen.dart';
import '../../verification/dialog/verification_form_dialog.dart';
import 'package:reentry/ui/modules/activities/activity_navigation_screen.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';

class HabitTrackerEntity {
  final String title;
  final String assets;
  final String route;
  final String description;

  const HabitTrackerEntity({
    required this.title,
    required this.description,
    required this.assets,
    required this.route,
  });
}

class HomeNavigationScreen extends StatefulWidget {
  const HomeNavigationScreen({super.key});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  late Future<List<MoodLog>> _moodLogsFuture;
  String? _userId;
  List<MoodLog> _moodLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = context.read<AccountCubit>().state;
      if (account == null) {
        setState(() => _userId = null);
        return;
      }
      _userId = account.userId;
      if (_userId != null) {
        _moodLogsFuture = _fetchMoodLogs(_userId!);
        _moodLogsFuture.then((logs) {
          if (mounted) {
            setState(() {
              _moodLogs = logs;
            });
          }
        });
      }
    });
  }

  Future<List<MoodLog>> _fetchMoodLogs(String userId) async {
    return await MoodLogsRepository(moodsRepository: MoodsRepository()).getMoodLogsForUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: Text('Please log in again.'));
    }

    final textTheme = context.textTheme;
    final accountCubit = context.watch<AccountCubit>().state;
    final latestMood = _moodLogs.isNotEmpty ? _moodLogs.first.mood : null;

    return BlocProvider(
      create: (_) => ActivityCubit()..fetchActivities(),
      child: BaseScaffold(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<AccountCubit>().loadFromCloud();
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                15.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.pushRoute(ProfileScreen());
                          },
                          child: SizedBox(
                            height: 44,
                            width: 44,
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                accountCubit?.avatar ?? AppConstants.avatar,
                              ),
                            ),
                          ),
                        ),
                        10.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, ${accountCubit?.name.split(' ')[0] ?? ''}",
                              style: textTheme.titleSmall,
                            ),
                            5.height,
                            if (accountCubit?.verificationStatus != null &&
                                accountCubit?.verificationStatus != VerificationStatus.none.name)
                              Builder(builder: (context) {
                                String text = 'Verification Pending';
                                Color color = Colors.orange;
                                IconData icon = Icons.pending;

                                if (accountCubit?.verificationStatus == VerificationStatus.rejected.name) {
                                  text = 'Verification Rejected';
                                  color = Colors.red;
                                  icon = Icons.cancel;
                                }
                                if (accountCubit?.verificationStatus == VerificationStatus.verified.name) {
                                  text = 'Verified';
                                  color = Colors.green;
                                  icon = Icons.verified;
                                }

                                return Row(
                                  children: [
                                    Icon(icon, color: color),
                                    5.width,
                                    InkWell(
                                      onTap: () {
                                        context.read<SubmitVerificationQuestionCubit>().seResponse(
                                          accountCubit?.verification?.form ?? {},
                                        );
                                        if (accountCubit?.verificationStatus == VerificationStatus.pending.name ||
                                            accountCubit?.verificationStatus == VerificationStatus.rejected.name) {
                                          context.displayDialog(VerificationFormDialog());
                                        } else {
                                          context.displayDialog(
                                            VerificationFormReviewDialog(
                                              form: accountCubit?.verification?.form ?? {},
                                              user: accountCubit,
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        text,
                                        style: textTheme.displaySmall?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                );
                              })
                            else
                              Text(
                                DateTime.now().formatDate(),
                                style: textTheme.displaySmall,
                              )
                          ],
                        )
                      ],
                    ),
                    if (accountCubit?.accountType == AccountType.citizen)
                      Row(
                        children: [
                          if (latestMood != null)
                            Text(
                              latestMood.icon ?? '',
                              style: const TextStyle(fontSize: 30),
                            )
                          else
                            const Icon(Icons.emoji_emotions, size: 30),
                        ],
                      ),
                  ],
                ),
                10.height,
                const Divider(color: AppColors.gray1, height: .4),
                if (accountCubit?.accountType == AccountType.citizen) ...[
                  20.height,
                  const ChangeFeelingCardComponent(),
                  20.height,
                ],
                FutureBuilder<List<MoodLog>>(
                  future: _moodLogsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final moodLogs = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Track your feelings'),
                        10.height,
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: moodLogs.length > 3 ? 3 : moodLogs.length,
                          itemBuilder: (context, index) {
                            return FeelingListItem(moodLog: moodLogs[index]);
                          },
                        ),
                        if (moodLogs.length > 3)
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppFilledButton(
                              title: 'View All',
                              onPress: () {
                                context.pushRoute(const FeelingScreen());
                              },
                            ),
                          ),
                        30.height,
                      ],
                    );
                  },
                ),
                if (accountCubit?.accountType == AccountType.citizen)
                  BlocBuilder<ActivityCubit, ActivityCubitState>(
                    builder: (context, state) {
                      return BoxContainer(
                        horizontalPadding: 10,
                        verticalPadding: 10,
                        filled: false,
                        constraints: const BoxConstraints(minHeight: 150),
                        radius: 10,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                label('Daily activities'),
                                AddButton(onTap: () {
                                  context.pushRoute(const ActivityNavigationScreen());
                                })
                              ],
                            ),
                            5.height,
                            Builder(builder: (context) {
                              if (state is ActivityLoading) {
                                return const LoadingComponent();
                              }
                              if (state.state is ActivitySuccess) {
                                if (state.activity.isEmpty) {
                                  return ErrorComponent(
                                    showButton: true,
                                    title: "Oops!",
                                    description: "You do not have any saved activities yet",
                                    actionButtonText: 'Create new activities',
                                    onActionButtonClick: () {
                                      context.pushRoute(const ActivityNavigationScreen());
                                    },
                                  );
                                }
                                return Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: state.activity.length > 3 ? 3 : state.activity.length,
                                      itemBuilder: (context, index) {
                                        return ActivityComponent(activity: state.activity[index]);
                                      },
                                    ),
                                    if (state.activity.length > 3)
                                      Align(
                                        alignment: Alignment.center,
                                        child: InkWell(
                                          onTap: () {
                                            context.pushRoute(const ActivityNavigationScreen());
                                          },
                                          child: const Text(
                                            "View All",
                                            style: TextStyle(decoration: TextDecoration.underline),
                                          ),
                                        ),
                                      )
                                  ],
                                );
                              }
                              return ErrorComponent(
                                showButton: false,
                                title: "Something went wrong",
                                description: "Please try again!",
                                onActionButtonClick: () {
                                  context.read<ActivityCubit>().fetchActivities();
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                if (accountCubit?.accountType != AccountType.citizen) ...[
                  30.height,
                  Text('Overview', style: textTheme.titleSmall),
                  10.height,
                  BlocBuilder<AdminStatCubit, AdminStatCubitState>(
                    builder: (context, state) {
                      AdminStatEntity data = const AdminStatEntity(
                        appointments: 0,
                        careTeam: 0,
                        totalCitizens: 0,
                        goals: 0,
                        milestones: 0,
                        incidents: 0,
                      );
                      if (state is AdminStatSuccess) data = state.data;
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: ShapeDecoration(
                          shape: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.greyWhite, width: .7),
                          ),
                        ),
                        child: Row(
                          children: [
                            careTeamDashboardData('Total citizens', data.totalCitizens),
                            10.width,
                            Container(height: 50, width: .5, color: Colors.white),
                            10.width,
                            careTeamDashboardData('Appointments', data.appointments),
                          ],
                        ),
                      );
                    },
                  ),
                  30.height,
                ],
                if (accountCubit?.accountType == AccountType.citizen) ...[
                  30.height,
                  label('Appointments'),
                  10.height,
                  BlocProvider(
                    create: (context) => AppointmentCubit()..fetchAppointments(),
                    child: const AppointmentComponent(),
                  ),
                  10.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppFilledButton(
                        title: 'View All',
                        onPress: () {
                          context.pushRoute(const ViewAppointmentsScreen());
                        },
                      ),
                    ],
                  ),
                ],
                if (accountCubit?.accountType == AccountType.citizen) ...[
                  20.height,
                  label('Habit Tracker'),
                  20.height,
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _habitOptions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 140,
                    ),
                    itemBuilder: (context, index) {
                      final e = _habitOptions[index];
                      final route = AppRoutes.routes[e.route];
                      return buildBoxContainer(e, onPress: () {
                        if (route != null) {
                          context.pushRoute(route);
                        }
                      });
                    },
                  ),
                ],
                50.height,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget careTeamDashboardData(String title, int value) {
    return Column(
      children: [
        Text(title, style: context.textTheme.bodyMedium?.copyWith(fontSize: 16)),
        10.height,
        Text(
          NumberFormat().format(value),
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget buildBoxContainer(HabitTrackerEntity e, {required VoidCallback onPress}) {
    final theme = context.textTheme;
    return BoxContainer(
      onPress: onPress,
      radius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(e.assets),
          8.height,
          Text(e.title, style: theme.bodyMedium?.copyWith(fontFamily: 'InterBold')),
          8.height,
          Expanded(child: Text(e.description, style: theme.displaySmall)),
        ],
      ),
    );
  }

  List<HabitTrackerEntity> get _habitOptions => const [
        HabitTrackerEntity(
          title: 'Goals',
          description: 'View your goals',
          route: AppRoutes.goals,
          assets: Assets.imagesGoals,
        ),
        HabitTrackerEntity(
          title: 'Personal growth',
          description: 'View your personal vision',
          route: AppRoutes.progress,
          assets: Assets.imagesGrowth,
        ),
        HabitTrackerEntity(
          title: 'Daily actions',
          description: 'View your daily progress',
          route: AppRoutes.dailyActions,
          assets: Assets.imagesDailyAction,
        ),
      ];
}

Widget label(String text) {
  return Builder(builder: (context) {
    return Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(fontSize: 16),
    );
  });
}

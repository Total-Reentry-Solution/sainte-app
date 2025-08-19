import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/data/repository/org/organization_repository.dart';
import 'package:reentry/generated/assets.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/authentication/bloc/auth_events.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_bloc.dart';
import 'package:reentry/ui/modules/authentication/bloc/authentication_state.dart';
import 'package:reentry/ui/modules/organizations/organization_screen.dart';
import 'package:reentry/ui/modules/root/feeling_screen.dart';
import 'package:reentry/ui/modules/verification/web/verification_request_screen.dart';
import '../../../../core/routes/routes.dart';
import '../../../../data/enum/account_type.dart';
import '../../../../data/shared/share_preference.dart';
import '../../activities/bloc/activity_cubit.dart';
import '../../activities/dialog/create_activity_dialog.dart';
import '../../activities/web/web_activity_screen.dart';
import '../../admin/dashboard.dart';
// import '../../appointment/bloc/appointment_cubit.dart';
import '../../appointment/web/appointment_screen.dart';
// All blog and appointment sidebar/menu items commented out for auth testing.
import '../../blog/web/blog_screen.dart';
import '../../citizens/citizens_screen.dart';
import '../../citizens/citizen_care_team_screen.dart';
import '../../goals/bloc/goals_cubit.dart';
import '../../goals/web/web_goals_screen.dart';
import '../../messaging/bloc/conversation_cubit.dart';
import '../../officers/officers_screen.dart';
import '../../profile/bloc/profile_cubit.dart';
import '../../report/web/view_report_screen.dart';
import '../../settings/web/settings_screen.dart';
import '../../verification/bloc/submit_verification_question_cubit.dart';
import '../../verification/dialog/verification_form_dialog.dart';
import '../../verification/dialog/verification_form_review_dialog.dart';
import '../../verification/web/verification_question_screen.dart';
import '../navigations/messages_navigation_screen.dart';
import '../../resource/resource_screen.dart';
import '../../appointment/appointment_invitations_screen.dart';

class Webroot extends StatefulWidget {
  final StatefulNavigationShell child;

  const Webroot({super.key, required this.child});

  @override
  _WebSideBarLayoutState createState() => _WebSideBarLayoutState();
}

class _WebSideBarLayoutState extends State<Webroot> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void clearStackAndNavigate(BuildContext context, String path) {
    while (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    }
    GoRouter.of(context).pushReplacement(path);
  }

  @override
  void initState() {
    super.initState();
    // Initialize account data first
    context.read<AccountCubit>().readFromLocalStorage();
    context.read<AccountCubit>().loadFromCloud();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AccountCubit>().state;
      if (currentUser == null || !_isUserOnboarded(currentUser)) {
        // Show error or redirect to login/onboarding
        context.go('/login');
        return;
      }
    });
    context.read<SubmitVerificationQuestionCubit>().fetchQuestions();
    // All usages of BlogPage, AppointmentCubit, and related widgets are commented out for auth testing.
    // context.read<AppointmentCubit>()
    //   ..fetchAppointmentInvitations(currentUser?.userId ?? '')
    //   ..fetchAppointments(userId: currentUser?.userId ?? '');
    context.read<ProfileCubit>().registerPushNotificationToken();
    
    // Get current user from AccountCubit state
    final currentUser = context.read<AccountCubit>().state;
    if (currentUser?.accountType == AccountType.citizen) {
      context.read<GoalCubit>()
        ..fetchGoals(personId: currentUser?.userId ?? '')
        ..fetchHistory();
    }
    context.read<ActivityCubit>()
      ..fetchActivities()
      ..fetchHistory();

    context.read<ConversationCubit>()
      ..cancel()
      ..listenForConversationsUpdate()
      ..onNewMessage(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PersistentStorage.showActivity().then((show) {
        if (show) {
          context.displayDialog(const CreateActivityDialog());
        }
        // if(user?.accountType==AccountType.reentry_orgs){
        //   OrganizationRepository().matchCareTeamToOrg(user?.userId ?? '');
        // }
      });

      PersistentStorage.showFeeling().then((value) {
        if (value) {
          context.displayDialog(const FeelingScreen(
            onboarding: false,
          ));
        }
      });
    });
  }

  bool _isUserOnboarded(UserDto? user) {
    if (user == null) return false;
    // Consider user onboarded if they have a name, accountType, and email
    return (user.name.isNotEmpty && user.accountType != null && (user.email?.isNotEmpty ?? false));
  }

  @override
  Widget build(BuildContext context) {

    return MultiBlocListener(listeners: [
      BlocListener<AuthBloc, AuthState>(listener: (context, state) {
        if (state is LogoutSuccess) {
          clearStackAndNavigate(context, AppRoutes.login.path);
          // html.window.location.assign('/');
        }
        if (state is AuthError) {
          context.showSnackbarError(state.message);
        }
      },
      ),
      BlocListener<AccountCubit,UserDto?>(  listenWhen: (prev, current) =>
      prev?.verificationStatus != current?.verificationStatus,
        listener: (_, state) {
          if (state?.accountType == AccountType.citizen) {
            if (state?.verificationStatus == null ||
                state?.verificationStatus == VerificationStatus.rejected.name ||
                state?.verificationStatus == VerificationStatus.none.name) {
              //todo show verification dialog
              print('kebilate -> show verification dialog');
              if (state?.verificationStatus == VerificationStatus.rejected.name) {
                final verification = state?.verification;
                context
                    .read<SubmitVerificationQuestionCubit>()
                    .seResponse(verification?.form ?? {});
                // TODO: Refactor AppAlertDialog and MoodLog.getLatestMood usages to new logic
                // AppAlertDialog.show(context,
                //     title: 'Rejected verification',
                //     description:
                //     'Your verification was rejected\n${verification?.rejectionReason ?? ''}\n please proceed to resubmit',
                //     action: 'Resubmit', onClickAction: () {
                //       context.displayDialog(VerificationFormDialog());
                //     });
                return;
              }
              // TODO: Refactor AppAlertDialog and MoodLog.getLatestMood usages to new logic
              // AppAlertDialog.show(context,
              //     title: 'Verification form',
              //     description: 'Please fill and submit the verification form.',
              //     action: 'Proceed', onClickAction: () {
              //       context.displayDialog(VerificationFormDialog());
              //     });
              //todo show modal for new verification
            }
          }
        },)
    ], child:  BlocBuilder<AccountCubit, UserDto?>(builder: (context, state) {
      if (state == null) {
        // Redirect to login if user data is not available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return const Center(child: CircularProgressIndicator());
      }
      final accountType = state.accountType;
      List<Widget> pages = [];

      if (accountType == AccountType.citizen) {
        pages = [
          DashboardPage(),
          ...[WebGoalsPage(), WebActivityScreen()],
          // WebAppointmentScreen(),
          ConversationNavigation(),
                        CitizenCareTeamScreen(),
          BlogPage.withProvider(),
          
          SettingsPage(),
        ];
      }
      if (accountType == AccountType.admin) {
        pages = [
          DashboardPage(),
          CitizensScreen(),
          CareTeamScreen(accountType: AccountType.mentor),
          OrganizationScreen(),
          ViewReportPage(),
          VerificationQuestionScreen(),
          VerificationRequestScreen(),
          BlogPage.withProvider(),
          SettingsPage()
        ];
      }
      if (accountType == AccountType.reentry_orgs) {
        pages = [
          DashboardPage(),
          CitizensScreen(),
          CareTeamScreen(accountType: AccountType.mentor),
          BlogPage.withProvider(),
          SettingsPage()
        ];
      }
      if (accountType == AccountType.case_manager) {
        pages = [
          DashboardPage(),
          CitizensScreen(),
          CareTeamScreen(accountType: AccountType.case_manager),
          WebAppointmentScreen(),
          AppointmentInvitationsScreen(),
          OrganizationScreen(),
          ConversationNavigation(),
          ViewReportPage(),
          BlogPage.withProvider(),
          SettingsPage()
        ];
      }
      if (accountType != AccountType.citizen &&
          accountType != AccountType.admin &&
          accountType != AccountType.reentry_orgs &&
          accountType != AccountType.case_manager) {
          pages = [
            DashboardPage(),
            CitizensScreen(),
            CareTeamScreen(accountType: AccountType.mentor),
            WebAppointmentScreen(),
            AppointmentInvitationsScreen(),
            OrganizationScreen(),
            ConversationNavigation(),
            BlogPage.withProvider(),
            SettingsPage()
          ];
        }

      return Scaffold(
        backgroundColor: AppColors.greyDark,
        key: _scaffoldKey,
        drawer: Drawer(
          backgroundColor: AppColors.greyDark,
          child: _buildSidebar(state),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return Row(
              children: [
                if (isDesktop)
                  Container(
                    width: 250,
                    color: AppColors.greyDark,
                    child: _buildSidebar(state),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: AppColors.greyDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isDesktop)
                              IconButton(
                                icon: const Icon(Icons.menu,
                                    color: AppColors.white),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                          ],
                        ),
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }));

  }

  int currentIndex = 0;

  Widget _buildSidebar(UserDto? state) {
    return BlocBuilder<AccountCubit, UserDto?>(builder: (context, state) {
      if (state == null) {
        return const SizedBox();
      }
      final accountType = state.accountType;
      final items = [
        if (accountType == AccountType.citizen) ...[
          (Assets.webDashboard, 'Dashboard', AppRoutes.dashboard.name),
          (Assets.svgAppointments, 'Goals', AppRoutes.goal.name),
          (Assets.svgCalender, 'Daily Activities', AppRoutes.activity.name),
          (Assets.svgAppointments, 'Appointments', AppRoutes.appointment.name),
          (Assets.svgChatBubble, 'Conversations', AppRoutes.conversation.name),
                      (Assets.webCitizens, 'Care Team', AppRoutes.citizenCareTeam.name),
          (Assets.webBlog, 'Blogs', AppRoutes.blog.name),
          (Assets.webResources, 'Resources', AppRoutes.resources.name),
          (Assets.webSettings, 'Settings', AppRoutes.settings.name),
          (Assets.webLogout, 'Logout', ''),
        ],
        if (accountType == AccountType.admin) ...[
          (Assets.webDashboard, 'Dashboard', AppRoutes.dashboard.name),
          (Assets.webCitizens, 'Citizen', AppRoutes.citizens.name),
          (Assets.webPeer, 'Care team', AppRoutes.mentors.name),
          (
          Assets.svgAppointments,
          'Organizations',
          AppRoutes.organization.name
          ),
          (Assets.webIncident, 'Reports', AppRoutes.reports.name),
          (Assets.webIncident, 'Questions', AppRoutes.verificationQuestion.name),
          (Assets.webIncident, 'Verification Request', AppRoutes.verificationRequest.name),
          (Assets.webBlog, 'Blog', AppRoutes.blog.name),
          (Assets.svgSettings, 'Settings', AppRoutes.settings.name),
          (Assets.webLogout, 'Logout', ''),
        ],
        if (accountType == AccountType.reentry_orgs) ...[
          (Assets.webDashboard, 'Dashboard', AppRoutes.dashboard.name),
          (Assets.webCitizens, 'Citizen', AppRoutes.citizens.name),
          (Assets.webPeer, 'Care team', AppRoutes.mentors.name),
          (Assets.webBlog, 'Blog', AppRoutes.blog.name),
          (Assets.svgSettings, 'Settings', AppRoutes.settings.name),
          (Assets.webLogout, 'Logout', ''),
        ],
        if (accountType == AccountType.case_manager) ...[
          (Assets.webDashboard, 'Dashboard', AppRoutes.dashboard.name),
          (Assets.webCitizens, 'Citizen', AppRoutes.citizens.name),
          (Assets.svgAppointments, 'Appointments', AppRoutes.appointment.name),
          (Assets.svgAppointments, 'Organizations', AppRoutes.organization.name),
          (Assets.svgChatBubble, 'Conversations', AppRoutes.conversation.name),
          (Assets.webIncident, 'Reports', AppRoutes.reports.name),
          (Assets.webBlog, 'Blog', AppRoutes.blog.name),
          (Assets.svgSettings, 'Settings', AppRoutes.settings.name),
          (Assets.webLogout, 'Logout', ''),
        ],
        if (accountType != AccountType.citizen &&
            accountType != AccountType.admin &&
            accountType != AccountType.reentry_orgs &&
            accountType != AccountType.case_manager) ...[
          (Assets.webDashboard, 'Dashboard', AppRoutes.dashboard.name),
          (Assets.webCitizens, 'Citizen', AppRoutes.citizens.name),
          (Assets.svgAppointments, 'Appointments', AppRoutes.appointment.name),
          (
            Assets.svgAppointments,
            'Organizations',
            AppRoutes.organization.name
          ),
          (Assets.svgChatBubble, 'Conversations', AppRoutes.conversation.name),
          (Assets.webBlog, 'Blog', AppRoutes.blog.name),
          (Assets.svgSettings, 'Settings', AppRoutes.settings.name),
          (Assets.webLogout, 'Logout', ''),
        ],
      ];

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Sainte',
                style: context.textTheme.titleLarge?.copyWith(fontSize: 30),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<AccountCubit, UserDto?>(
                  builder: (context, state) {
                if (state == null) return const SizedBox();
                // final accountType = state.accountType;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          NetworkImage(state.avatar ?? AppConstants.avatar),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.name, style: context.textTheme.bodyMedium),
                          Text(
                            state.email ?? 'jane.doe@example.com',
                            style: context.textTheme.bodyMedium!
                                .copyWith(fontSize: 11, color: AppColors.grey1),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          Builder(builder: (context) {
                            print('kebilate -> ${state.userId}');
                            return Text(
                              "ID:${state.userCode?.toString() ?? ''}",
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.white),
                            );
                          }),
                          2.height,
                          if (state.verificationStatus != null &&
                              state.verificationStatus !=
                                  VerificationStatus.none.name)
                            Builder(builder: (context) {
                              String text = 'Verification Pending';
                              Color color = Colors.orange;
                              IconData icon = Icons.pending;
                              if (state.verificationStatus ==
                                  VerificationStatus.rejected.name) {
                                text = 'Verification Rejected';
                                icon = Icons.cancel;
                                color = Colors.red;
                              }
                              if (state.verificationStatus ==
                                  VerificationStatus.verified.name) {
                                text = 'Verified';
                                icon = Icons.verified;
                                color = Colors.green;
                              }

                              return Row(
                                children: [
                                  Icon(
                                    icon,
                                    color: color,
                                  ),
                                  5.width,
                                  InkWell(
                                    onTap: () {
                                      if (state
                                          .verificationStatus ==
                                          VerificationStatus
                                              .verified.name) {
                                        context.displayDialog(
                                            VerificationFormReviewDialog(
                                              form: state
                                                  .verification?.form ??
                                                  {},
                                              user: state,
                                            ));
                                        return;
                                      }
                                    },
                                    child: Text(
                                      text,
                                      style: context.textTheme.displaySmall
                                          ?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              );
                            }),
                          2.height,
                          if (state.accountType == AccountType.citizen)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // TODO: Refactor AppAlertDialog and MoodLog.getLatestMood usages to new logic
                                // Image.asset(
                                //   MoodLog.getLatestMood(state.userId)?.asset ??
                                //       Assets.imagesLoved,
                                //   width: 24,
                                // ),
                              ],
                            )
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
            30.height,
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  _buildSidebarItem(item.$1, item.$2, item.$3, index,
                      isSelected: index == currentIndex
                      //widget.child.currentIndex
                      ),
                  15.height,
                ],
              );
            }),
          ],
        ),
      );
    });
  }

  Padding _buildSubGroupTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          title,
          style: context.textTheme.bodySmall!
              .copyWith(fontSize: 11, color: AppColors.grey1),
        ),
      ),
    );
  }

  void closeApp(BuildContext context, void Function() callback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutEvent());
              callback();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String icon, String label, String route, int index,
      {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: AppColors.gray2,
                  width: 1.0,
                )
              : null,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: InkWell(
          onTap: () {
            if (label.toLowerCase().contains('logout')) {
              closeApp(context, () {
                context.read<AuthBloc>().add(LogoutEvent());
              });
              return;
            }
            setState(() {
              currentIndex = index;
            });
            context.goNamed(route);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SvgPicture.asset(icon),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: context.textTheme.bodySmall
                    ?.copyWith(color: AppColors.greyWhite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

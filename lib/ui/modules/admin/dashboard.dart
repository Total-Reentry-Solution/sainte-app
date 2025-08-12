import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/data/enum/account_type.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/admin/admin_stat_cubit.dart';
import 'package:reentry/ui/modules/admin/components/over_view_component.dart';
import 'package:reentry/ui/modules/appointment/appointment_graph/appointment_graph_component.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_state.dart';
import 'package:reentry/ui/modules/appointment/web/appointment_screen.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/goals/bloc/goals_cubit.dart';
import 'package:reentry/ui/modules/shared/cubit/admin_cubit.dart';
import '../goals/bloc/goals_state.dart';
import 'admin_stat_state.dart';
import 'package:reentry/data/repository/mood_logs/mood_logs_repository.dart';
import 'package:reentry/data/repository/moods/moods_repository.dart';
import 'package:reentry/data/model/mood.dart';
import 'package:reentry/ui/modules/root/feeling_screen.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_cubit.dart';
import 'package:reentry/ui/modules/activities/bloc/activity_state.dart';
import 'package:reentry/ui/modules/activities/dialog/create_activity_dialog.dart';
import 'package:reentry/ui/modules/appointment/create_appointment_screen.dart';
import 'package:reentry/ui/modules/goals/goals_screen.dart';
import 'package:reentry/ui/modules/goals/goals_navigation_screen.dart';
import 'package:reentry/ui/modules/activities/create_activity_screen.dart';
import 'package:reentry/ui/modules/activities/components/activity_component.dart';

class DashboardPage extends HookWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.read<AccountCubit>().state;
    useEffect(() {
      context.read<AdminStatCubit>().fetchStats();
      if (account?.accountType == AccountType.citizen) {
        context.read<GoalCubit>().fetchGoals();
        // context
        //     .read<AppointmentCubit>()
        //     .fetchAppointments(userId: account?.userId);
      }
    }, []);
    return BlocProvider(
      create: (context) => AdminUserCubitNew()..fetchCitizens(account: account),
      child: BlocBuilder<AdminUserCubitNew, MentorDataState>(
          builder: (context, adminUserCubitState) {
        return BaseScaffold(child:
            BlocBuilder<AdminStatCubit, AdminStatCubitState>(
                builder: (context, state) {
          if (state is AdminStatLoading) {
            return const LoadingComponent();
          }
          if (state is AdminStatError) {
            return ErrorComponent(
              description: state.error,
              title: 'Something went wrong!',
              onActionButtonClick: () {
                context.read<AdminStatCubit>().fetchStats();
              },
            );
          }
          if (state is AdminStatSuccess) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<AppointmentCubit>(create: (_) => AppointmentCubit()..fetchAppointments(dashboard: true)),
                BlocProvider<ActivityCubit>(create: (_) => ActivityCubit()..fetchActivities()),
                BlocProvider<GoalCubit>(create: (_) => GoalCubit()..fetchGoals()),
              ],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<AccountCubit, UserDto?>(
                  builder: (context, accountState) {
                    if (accountState == null) {
                      return Column(
                        children: [
                          const Center(child: Text('Please log in again.', style: TextStyle(color: Colors.white))),
                          16.height,
                          const Text('User account data is missing. This may be a bug. Please try restarting the app.', style: TextStyle(color: Colors.red)),
                        ],
                      );
                    }
                    final userName = accountState.name;
                    final today = DateTime.now();
                    final todayStr = '${today.month}/${today.day}/${today.year}';
                    
                    // Route to appropriate dashboard based on account type
                    if (accountState.accountType == AccountType.citizen) {
                      return citizenDashboard(context, state, adminUserCubitState.data.length);
                    } else if (accountState.accountType == AccountType.admin) {
                      return adminDashboard(context, state);
                    } else {
                      // All other non-citizen types (mentor, officer, case_manager, etc.) use care team dashboard
                      return careTeamDashboard(context, state);
                    }
                  },
                ),
              ),
            );
          }
          return ErrorComponent(
            onActionButtonClick: () {
              context.read<AdminStatCubit>().fetchStats();
            },
          );
        }));
      }),
    );
  }

  Widget citizenDashboard(BuildContext context, AdminStatSuccess state, int citizenCount) {
    return BlocBuilder<AccountCubit, UserDto?>(builder: (context, account) {
      return Builder(builder: (context) {
        return BlocBuilder<GoalCubit, GoalCubitState>(
          builder: (context, goalState) {
            int goalCount = goalState.all.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text('Hello, ${account?.name ?? ''}!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                Text('${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                24.height,
                // Track your feelings
                Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<List<MoodLog>>(
                          future: MoodLogsRepository(moodsRepository: MoodsRepository()).getMoodLogsForUser(account?.userId ?? ''),
                          builder: (context, snapshot) {
                            final moods = snapshot.data ?? [];
                            final mood = moods.isNotEmpty ? moods.first : null;
                            return Row(
                              children: [
                                Text('Track your feelings', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
                                16.width,
                                if (mood != null) ...[
                                  if (mood.mood.icon != null && mood.mood.icon!.isNotEmpty) ...[
                                    Text(mood.mood.icon!, style: const TextStyle(fontSize: 20)),
                                    6.width,
                                  ],
                                  Text(mood.mood.name, style: const TextStyle(color: Colors.white)),
                                  8.width,
                                  Text('${mood.createdAt.month}/${mood.createdAt.day}/${mood.createdAt.year}', style: const TextStyle(color: Colors.white70)),
                                ]
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: 'Add Mood',
                          onPressed: () {
                            context.displayDialog(const FeelingScreen(onboarding: false));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                16.height,
                // Daily activities
                Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: BlocBuilder<ActivityCubit, ActivityCubitState>(
                            builder: (context, activityState) {
                              if (activityState.state is ActivityLoading) {
                                return const Center(child: CircularProgressIndicator(color: Colors.white));
                              }
                              if (activityState.state is ActivityError) {
                                final errorMsg = (activityState.state as ActivityError).message;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Something went wrong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    4.height,
                                    Text(errorMsg, style: const TextStyle(color: Colors.white70)),
                                    8.height,
                                    ElevatedButton(
                                      onPressed: () => context.read<ActivityCubit>().fetchActivities(),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                );
                              }
                              final activities = activityState.activity;
                              if (activities.isEmpty) {
                                return const Text('No daily activities', style: TextStyle(color: Colors.white70));
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activities.length,
                                separatorBuilder: (context, index) => 8.height,
                                itemBuilder: (context, index) {
                                  return ActivityComponent(activity: activities[index]);
                                },
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: 'Add Activity',
                          onPressed: () {
                            context.pushRoute(const CreateActivityScreen());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                16.height,
                // Appointments
                Card(
                  color: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: BlocBuilder<AppointmentCubit, AppointmentCubitState>(
                            builder: (context, appointmentState) {
                              if (appointmentState.state is AppointmentLoading) {
                                return const Center(child: CircularProgressIndicator(color: Colors.white));
                              }
                              if (appointmentState.state is AppointmentError) {
                                final errorMsg = (appointmentState.state as AppointmentError).message;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Something went wrong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    4.height,
                                    Text(errorMsg, style: const TextStyle(color: Colors.white70)),
                                    8.height,
                                                                          ElevatedButton(
                                        onPressed: () => context.read<AppointmentCubit>().fetchAppointments(dashboard: true),
                                        child: const Text('Retry'),
                                      ),
                                  ],
                                );
                              }
                              final appointments = appointmentState.data;
                              if (appointments.isEmpty) {
                                return const Text('There is nothing here\nYou don\'t have an appointment to view', style: TextStyle(color: Colors.white70));
                              }
                              final appt = appointments.first;
                              return Text(appt.title ?? 'No title', style: const TextStyle(color: Colors.white));
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: 'Add Appointment',
                          onPressed: () {
                            context.pushRoute(const CreateAppointmentScreen());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                16.height,
                // Habit Tracker
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    GestureDetector(
                      onTap: () => context.pushRoute(const GoalsNavigationScreen()),
                      child: Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.flag, color: Colors.white),
                              SizedBox(height: 8),
                              Text('Goals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('View your goals', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.show_chart, color: Colors.white),
                              SizedBox(height: 8),
                              Text('Personal growth', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('View your personal vision', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Card(
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.check_box, color: Colors.white),
                              SizedBox(height: 8),
                              Text('Daily actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('View your daily progress', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Add more cards as needed
                  ],
                ),
              ],
            );
          },
        );
      });
    });
  }

  Widget careTeamDashboard(BuildContext context, AdminStatSuccess state) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          BlocBuilder<AccountCubit, UserDto?>(builder: (context, account) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${account?.name ?? ''}!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                Text('${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                24.height,
              ],
            );
          }),
          
          // Overview Section
          OverViewComponent(
            entity: state.data,
          ),
          24.height,
          
          // Appointments Chart Section
          Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appointments Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  16.height,
                  BlocBuilder<AppointmentCubit, AppointmentCubitState>(
                    builder: (context, appointmentState) {
                      if (appointmentState.state is AppointmentLoading) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (appointmentState.state is AppointmentError) {
                        return Center(child: Text('Error loading appointments', style: TextStyle(color: Colors.white70)));
                      }
                      final appointments = appointmentState.data;
                      return AppointmentGraphComponent(appointments: appointments);
                    },
                  ),
                ],
              ),
            ),
          ),
          24.height,
          
          // Appointments Section
          Card(
            color: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Appointments', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'Add Appointment',
                        onPressed: () {
                          context.pushRoute(const CreateAppointmentScreen());
                        },
                      ),
                    ],
                  ),
                16.height,
                BlocBuilder<AppointmentCubit, AppointmentCubitState>(
                  builder: (context, appointmentState) {
                    if (appointmentState.state is AppointmentLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (appointmentState.state is AppointmentError) {
                      final errorMsg = (appointmentState.state as AppointmentError).message;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Something went wrong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          4.height,
                          Text(errorMsg, style: const TextStyle(color: Colors.white70)),
                          8.height,
                          ElevatedButton(
                            onPressed: () => context.read<AppointmentCubit>().fetchAppointments(dashboard: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    final appointments = appointmentState.data;
                    if (appointments.isEmpty) {
                      return const Text('No appointments found', style: TextStyle(color: Colors.white70));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appointments.take(5).length, // Show only first 5
                      separatorBuilder: (context, index) => 8.height,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(appointment.title ?? 'No title', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(appointment.date?.toString() ?? 'No date', style: const TextStyle(color: Colors.white70)),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          onTap: () {
                            // TODO: Navigate to appointment details
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        24.height,
        
        // Citizens Section
        Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Citizens', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to citizens page
                      },
                      child: Text('View All', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
                16.height,
                BlocBuilder<AdminUserCubitNew, MentorDataState>(
                  builder: (context, citizenState) {
                    if (citizenState.data.isEmpty) {
                      return const Text('No citizens found', style: TextStyle(color: Colors.white70));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: citizenState.data.take(5).length, // Show only first 5
                      separatorBuilder: (context, index) => 8.height,
                      itemBuilder: (context, index) {
                        final citizen = citizenState.data[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(citizen.avatar ?? 'https://via.placeholder.com/40'),
                          ),
                          title: Text(citizen.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(citizen.email ?? '', style: const TextStyle(color: Colors.white70)),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          onTap: () {
                            // TODO: Navigate to citizen profile
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget adminDashboard(BuildContext context, AdminStatSuccess state) {
    return Column(
      children: [
        50.height,
        OverViewComponent(
          entity: state.data,
        ),
        50.height,
        
        // Appointments Chart Section
        Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointments Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                16.height,
                BlocBuilder<AppointmentCubit, AppointmentCubitState>(
                  builder: (context, appointmentState) {
                    if (appointmentState.state is AppointmentLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (appointmentState.state is AppointmentError) {
                      return Center(child: Text('Error loading appointments', style: TextStyle(color: Colors.white70)));
                    }
                    final appointments = appointmentState.data;
                    return AppointmentGraphComponent(appointments: appointments);
                  },
                ),
              ],
            ),
          ),
        ),
        50.height,
        
        BlocBuilder<AccountCubit, UserDto?>(builder: (context, state) {
          return const SizedBox.shrink();
        }),
        50.height,
      ],
    );
  }
}

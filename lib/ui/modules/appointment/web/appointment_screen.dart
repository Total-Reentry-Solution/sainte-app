import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/generated/assets.dart';
import 'package:reentry/ui/components/error_component.dart';
import 'package:reentry/ui/components/loading_component.dart';
import 'package:reentry/ui/components/pill_selector_component.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_state.dart';
import 'package:reentry/ui/modules/appointment/component/appointment_card.dart';
import 'package:reentry/ui/modules/appointment/component/table.dart';
import 'package:reentry/ui/modules/appointment/create_appointment_screen.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/citizens/component/icon_button.dart';
import 'package:reentry/ui/modules/shared/cubit_state.dart';
import '../../../dialog/alert_dialog.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../view_single_appointment_screen.dart';

class WebAppointmentScreen extends HookWidget {
  const WebAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();
    final scrollController = useScrollController();
    String _searchQuery = '';
    // Add logic to fetch and display appointments using AppointmentCubit/Bloc
    return BaseScaffold(
      child: Stack(
        children: [
          BlocProvider(
            create: (context) => AppointmentCubit()..fetchAppointments(),
            child: BlocBuilder<AppointmentCubit, AppointmentCubitState>(
              builder: (context, state) {
                if (state.state is CubitStateLoading) {
                  return const LoadingComponent();
                }
                if (state.state is CubitStateError) {
                  return ErrorComponent(
                    showButton: true,
                    onActionButtonClick: () {
                      context.read<AppointmentCubit>().fetchAppointments();
                    },
                  );
                }
                final appointments = state.data;
                if (appointments.isEmpty) {
                  return const Center(child: Text('No appointments found.'));
                }
                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return ListTile(
                      title: Text(appointment.title ?? 'No title'),
                      subtitle: Text(appointment.date?.toString() ?? 'No date'),
                      onTap: () {
                        print('Appointment tapped: ${appointment.id}');
                        context.displayDialog(ViewSingleAppointmentScreen(
                          entity: appointment,
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton(
              onPressed: () {
                context.displayDialog(const CreateAppointmentScreen());
              },
              child: const Icon(Icons.add),
              tooltip: 'Create Appointment',
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentHistoryTable extends HookWidget {
  const AppointmentHistoryTable(
      {super.key,
      this.userId,
      this.admin = false,
      this.dashboard = false,
      this.data = const []});

  final String? userId;
  final bool admin;
  final bool dashboard;
  final List<NewAppointmentDto> data;

  @override
  Widget build(BuildContext context) {
    // useEffect(() {
    //  context.read<AppointmentCubit>();
    // }, []);
    // print('kariaki1 -> ${userId}');
    final selected = useState(AppointmentStatus.all);
    if (data.isEmpty) {
      return const ErrorComponent(
        showButton: false,
        title: "There is nothing here",
        description: "You don't have an appointment to view",
      );
    }
    final List<NewAppointmentDto> history =
        _filterAppointments(data, selected.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dashboard) ...[
          selector(onChange: (result) {
            selected.value = result ?? AppointmentStatus.all;
          })
        ],
        10.height,
        _buildTable(context, history),
        10.height,
        if (history.isEmpty)
          const ErrorComponent(
            showButton: false,
            title: "There is nothing here",
            description: "You don't have an appointment to view",
          )
      ],
    );
  }

  List<NewAppointmentDto> _filterAppointments(
      List<NewAppointmentDto> data, AppointmentStatus status) {
    if (status == AppointmentStatus.upcoming) {
      return data
          .where((e) =>
              e.date.isAfter(DateTime.now()) &&
              e.status != AppointmentStatus.canceled)
          .toList();
    }
    if (status == AppointmentStatus.missed) {
      return data
          .where((e) =>
              e.date.isBefore(DateTime.now()) &&
              e.status == AppointmentStatus.upcoming)
          .toList();
    }

    if (status == AppointmentStatus.canceled) {
      return data.where((e) => e.status == AppointmentStatus.canceled).toList();
    }

    return data;
  }

  Widget selector({required Function(AppointmentStatus?) onChange}) {
    final names = [
      'All',
      'Upcoming',
      'Passed',
      'Canceled',
    ];
    return HookBuilder(builder: (context) {
      final selected = useState(names[0]);
      return Wrap(
        direction: Axis.horizontal,
        children: names
            .map((value) => PillSelectorComponent2(
                text: value,
                selected: selected.value == value,
                callback: () {
                  selected.value = value;
                  onChange(AppointmentStatus.values.where((e) {
                    var selectedString = selected.value.toLowerCase();
                    if (selectedString == 'passed') {
                      selectedString = 'missed';
                    }
                    return e.name == selectedString;
                  }).firstOrNull);
                }))
            .toList(),
      );
    });
  }

  Widget _buildTable(BuildContext context, List<NewAppointmentDto> history) {
    final columns = [
      const DataColumn(label: TableHeader("Title")),
      const DataColumn(label: TableHeader("Location")),
      const DataColumn(label: TableHeader("Created By")),
      const DataColumn(label: TableHeader("Status")),
      const DataColumn(label: TableHeader("Date")),
    ];

    final rows = _buildRows(context, history);

    return Container(
      color: Colors.black,
      child: ReusableTable(
        columns: columns,
        rows: rows,
        headingRowColor: AppColors.white,
        dataRowColor: AppColors.greyDark,
        columnSpacing: 20.0,
        dataRowHeight: 56.0,
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  List<DataRow> _buildRows(context, List<NewAppointmentDto> history) {
    return history.map((item) {
      return DataRow(
        onSelectChanged: (isSelected) {
          if (admin) {
            return;
          }
          if (isSelected == true) {
            context.displayDialog(ViewSingleAppointmentScreen(
              entity: item,
            ));
          }
        },
        cells: [
          DataCell(Text(item.title ?? '')),
          DataCell(Text(item.location ?? 'No location provider')),
          DataCell(Text(item.creatorName ?? '')),
          DataCell(Text(item.status?.name ?? '')),
          DataCell(Text(item.date != null ? formatDate(item.date!) : '')),
        ],
      );
    }).toList();
  }
}

class AppointmentInvitationTable extends StatelessWidget {
  const AppointmentInvitationTable(
      {super.key, required this.invitation, this.userId});

  final String? userId;
  final List<NewAppointmentDto> invitation;

  @override
  Widget build(BuildContext context) {
    final columns = [
      const DataColumn(label: TableHeader("Title")),
      const DataColumn(label: TableHeader("Location")),
      const DataColumn(label: TableHeader("Invited By")),
      const DataColumn(label: TableHeader("Date")),
    ];

    if (invitation.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: const ErrorComponent(
          showButton: false,
          title: "There is nothing here",
          description: "You don't have any invitations",
        ),
      );
    }

    final rows = _buildRows(context);

    return Container(
      color: Colors.black,
      child: ReusableTable(
        columns: columns,
        rows: rows,
        headingRowColor: AppColors.white,
        dataRowColor: AppColors.greyDark,
        columnSpacing: 20.0,
        dataRowHeight: 56.0,
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  List<DataRow> _buildRows(context) {
    return invitation.map((item) {
      return DataRow(
        onSelectChanged: (isSelected) {
          context.displayDialog(ViewSingleAppointmentScreen(
            entity: item,
          ));
          _showAppointmentModal(context, item, false, false);
        },
        cells: [
          DataCell(Text(item.title)),
          DataCell(Text(item.location!)),
          DataCell(Text(item.creatorName)),
          DataCell(Text(formatDate(item.date))),
        ],
      );
    }).toList();
  }
}

void _showAppointmentModal(
    BuildContext context, item, bool cancel, bool reschedule) {
  context.displayDialog(CreateAppointmentScreen(
    appointment: item,
    cancel: cancel,
    reschedule: reschedule,
  ));
}

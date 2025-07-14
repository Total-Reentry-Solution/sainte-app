import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/ui/components/line_chart.dart';
import 'package:reentry/ui/modules/appointment/appointment_graph/appointment_graph_cubit.dart';
import 'package:reentry/ui/modules/appointment/appointment_graph/appointment_graph_state.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/model/appointment_dto.dart';
import '../../../components/container/box_container.dart';
import '../../activities/chart/graph_component.dart';
import 'package:flutter/material.dart';

class AppointmentGraphComponent extends StatelessWidget {
  final String? userId;
  final List<NewAppointmentDto>? appointments;

  const AppointmentGraphComponent({super.key, this.userId,this.appointments});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppointmentGraphCubit()
        ..appointmentGraphData(userId: userId, appointment: appointments),
      child: BlocBuilder<AppointmentGraphCubit, AppointmentGraphState>(
        builder: (context, state) {
          if (state is AppointmentGraphLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AppointmentGraphError) {
            return Center(child: Text(state.error));
          }
          if (state is AppointmentGraphSuccess) {
            // return LineChartWidget(data: state.data);
            return Center(child: Text('Line chart not implemented'));
          }
          return const SizedBox();
        },
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_bloc.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_event.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_state.dart';
import 'package:reentry/ui/modules/appointment/create_appointment_screen.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/shared/success_screen.dart';
import '../../../core/theme/colors.dart';
import '../../../data/model/appointment_dto.dart';
import '../admin/admin_stat_cubit.dart';
import 'modal/rejection_reason_modal.dart';

class ViewSingleAppointmentScreen extends HookWidget {
  final NewAppointmentDto entity;

  const ViewSingleAppointmentScreen({super.key, required this.entity});

  Widget label(String text) {
    return Builder(builder: (context) {
      final textTheme = context.textTheme;
      return Text(
        text,
        style: textTheme.titleSmall?.copyWith(color: AppColors.gray2),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Add logic to display appointment details using entity
    return BaseScaffold(
      appBar: AppBar(title: Text('Appointment Details')),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('Title'),
            Text(entity.title),
            label('Date'),
            Text(entity.date.toString()),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}

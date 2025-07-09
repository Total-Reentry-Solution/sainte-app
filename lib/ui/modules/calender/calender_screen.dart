import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get_common/get_reset.dart';
import 'package:intl/intl.dart';
import 'package:reentry/core/enum/days.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/appointment_dto.dart';
import 'package:reentry/data/model/user_dto.dart';
import 'package:reentry/main.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/components/buttons/primary_button.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_cubit.dart';
import 'package:reentry/ui/modules/appointment/bloc/appointment_state.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/profile/bloc/profile_cubit.dart';
import 'package:reentry/ui/modules/profile/bloc/profile_state.dart';
import 'package:reentry/ui/modules/shared/success_screen.dart';
import '../../../core/extensions.dart';

class CalenderScreen extends HookWidget {
  const CalenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Calendar temporarily disabled for auth testing'));
  }
}

List<String> computeTime() {
  List<String> result = [];
  for (int i = 9; i <= 16; i++) {
    for (int mins = 0; mins <= 1; mins++) {
      String min = mins == 0 ? '00' : '30';
      result.add('$i:$min');
    }
  }
  return result;
}

Widget dateComponent(String value,
    {bool selected = false,
    bool highlighted = false,
    required Function(String) onClick}) {
  final date = DateTime.parse(value);
  final year = date.year.toString().substring(2);
  final month = date.formatDate().split(" ")[0];
  final day = date.day;
  return Builder(builder: (context) {
    final textTheme = context.textTheme;
    return InkWell(
      onTap: () {
        //onClick(day);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: !selected
            ? null
            : ShapeDecoration(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: const BorderSide(color: AppColors.white))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${day < 10 ? '0$day' : day}',
                    style: textTheme.bodySmall,
                  ),
                ),
                if (selected || highlighted)
                  const Positioned(
                      right: 0,
                      top: 0,
                      child: Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 10,
                        ),
                      ))
              ],
            ),
            3.height,
            Text(
              '$month $year',
              style: textTheme.bodySmall?.copyWith(fontSize: 8),
            )
          ],
        ),
      ),
    );
  });
}

Widget dayComponent(Days day,
    {bool selected = false,
    bool secondarySelect = false,
    required Function(Days) onClick}) {
  return Builder(builder: (context) {
    final textTheme = context.textTheme;
    return InkWell(
      onTap: () {
        if (secondarySelect) {
          return;
        }
        onClick(day);
      },
      child: Container(
        decoration: (!selected && !secondarySelect)
            ? null
            : ShapeDecoration(
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: secondarySelect
                            ? AppColors.gray1
                            : AppColors.white))),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: Text(
                day.name.capitalize,
                style: textTheme.bodySmall,
              ),
            ),
            if (selected)
              const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 10,
                  ))
          ],
        ),
      ),
    );
  });
}

/*

 */
List<String> getOrderedTime(List<String> time) {
  Map<String, String> timeMap = {};
  for (var t in time) {
    timeMap[t] = t;
  }
  return computeTime()
      .map((index) {
        final split = index.split(':');
        int hour = int.parse(split[0]);
        final one = split[1].split(" ");
        int mins = int.tryParse(one[0]) ?? 0;
        String time =
            '${hour < 10 ? '0$hour' : hour}:${mins < 10 ? '0$mins' : mins}';
        time = '$time ${hour >= 12 ? 'PM' : 'AM'}';
        return time;
      })
      .where((e) => timeMap.containsKey(e))
      .toList();
}

Widget timeComponent(
    {required int hour,
    required int mins,
    required Set<String> selected,
    required Function(String) onClick}) {
  return Builder(builder: (context) {
    String time =
        '${hour < 10 ? '0$hour' : hour}:${mins < 10 ? '0$mins' : mins}';
    time = '$time ${hour >= 12 ? 'PM' : 'AM'}';
    final textTheme = context.textTheme;
    return InkWell(
      onTap: () {
        onClick(time);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: !selected.contains(time)
            ? null
            : const ShapeDecoration(
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.white))),
        child: Text(
          time,
          style: textTheme.bodySmall,
        ),
      ),
    );
  });
}

Widget selectableComponent(
    {required String text,
    required bool selected,
    required Function() onClick}) {
  return Builder(builder: (context) {
    final textTheme = context.textTheme;
    return InkWell(
      onTap: () {
        onClick();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: !selected
            ? null
            : const ShapeDecoration(
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.white))),
        child: Text(
          text,
          style: textTheme.bodySmall,
        ),
      ),
    );
  });
}

List<String> getCurrentWeekDays() {
  DateTime now = DateTime.now();

  // Find the start of the week (assuming Sunday is the first day of the week)
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday % 7));

  // Get each day of the week
  List<String> weekDays = List.generate(7, (index) {
    DateTime weekDay = startOfWeek.add(Duration(days: index));
    return weekDay.toIso8601String();
    // return DateFormat('EEEE, MMM d').format(weekDay); // Format: "Monday, Jan 1"
  });

  return weekDays;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/activity_dto.dart';
import 'package:reentry/data/model/goal_dto.dart';
import 'package:reentry/ui/modules/activities/update_activity_screen.dart';
import 'package:reentry/ui/modules/goals/goal_progress_screen.dart';

import '../../../../generated/assets.dart';

class ActivityComponent extends StatelessWidget {
  final ActivityDto activity;

  const ActivityComponent({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = context.textTheme;
    // Use UTC time to avoid timezone issues on web
    final now = DateTime.now().toUtc();
    final startDate = DateTime.fromMillisecondsSinceEpoch(activity.startDate, isUtc: true);
    final isStartDateBeforeNow = startDate.isBefore(now);
    print('kebilate -> $isStartDateBeforeNow');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      constraints: const BoxConstraints(
        minHeight: 40
      ),
      child: Row(
        children: [
          Expanded(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(Assets.svgGoal),
              3.width,
              Expanded(
                  child: Text(
                activity.title,
                style: theme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ))
            ],
          )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 8,
                width: 54,
                child: LinearProgressIndicator(
                  value: activity.progress / 100,
                  borderRadius: BorderRadius.circular(50),
                  color: activity.progress == 100 ? Colors.green : Colors.white, // white bar
                 // backgroundColor: Colors.white24, // subtle white background
                ),
              ),
              5.width,
              Text(
                '${activity.progress}%',
                style: theme.bodySmall?.copyWith(color: Colors.white), // white text
              ),
              if (activity.progress < 100 &&
                  startDate
                      .add(const Duration(days: 1))
                      .isAfter(now)) ...[
                5.width,
                IconButton(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    onPressed: () {
                      context.pushRoute(ActivityProgressScreen(
                        activity: activity,
                      ));
                    },
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.white,
                      size: 18,
                    ))
              ]
            ],
          )
        ],
      ),
    );
  }
}

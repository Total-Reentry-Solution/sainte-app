import 'package:flutter/cupertino.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/data/model/mood.dart';

class FeelingListItem extends StatelessWidget {
  final MoodLog moodLog;

  const FeelingListItem({super.key, required this.moodLog});

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: const BorderSide(color: AppColors.greyWhite)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(moodLog.mood.icon ?? ''),
              10.width,
              Text(
                moodLog.mood.name,
                style: const TextStyle(fontWeight: FontWeight.w400),
              )
            ],
          )),
          Text(
            moodLog.createdAt.formatDate(),
            style: textStyle.bodySmall?.copyWith(color: AppColors.gray2),
          )
        ],
      ),
    );
  }
}

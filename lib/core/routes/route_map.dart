import 'package:flutter/cupertino.dart';
import 'package:reentry/core/routes/routes.dart';
import 'package:reentry/ui/modules/calender/calender_screen.dart';
import 'package:reentry/ui/modules/goals/goals_navigation_screen.dart';
import 'package:reentry/ui/modules/activities/daily_progress_screen.dart';
import 'package:reentry/ui/modules/activities/activity_navigation_screen.dart';

class RouteMap{

  static Map<String,Widget> maps = {
    AppRoutes.calender: const CalenderScreen(),
    AppRoutes.goals: const GoalsNavigationScreen(),
    AppRoutes.progress: const DailyProgressScreen(),
    AppRoutes.dailyActions: const ActivityNavigationScreen(),
  };
}
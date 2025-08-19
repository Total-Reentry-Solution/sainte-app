import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/ui/modules/blog/bloc/blog_cubit.dart';
import 'package:reentry/ui/modules/resource/resource_screen.dart';

class ResourcesNavigationScreen extends StatelessWidget {
  const ResourcesNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BlogCubit()..fetchBlogs(),
      child: const ResourceScreen(),
    );
  }
}

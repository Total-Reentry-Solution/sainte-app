// ignore_for_file: library_private_types_in_public_api
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:reentry/core/const/app_constants.dart';
import 'package:reentry/core/extensions.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/input/input_field.dart';
import 'package:reentry/ui/components/pagination.dart';
import 'package:reentry/ui/components/scaffold/base_scaffold.dart';
import 'package:reentry/ui/modules/appointment/component/table.dart';
import 'package:reentry/ui/modules/authentication/bloc/account_cubit.dart';
import 'package:reentry/ui/modules/citizens/bloc/citizen_profile_cubit.dart';
import 'package:reentry/ui/modules/citizens/bloc/citizen_profile_state.dart';
import 'package:reentry/ui/modules/shared/cubit/admin_cubit.dart';
import 'package:reentry/ui/modules/shared/cubit_state.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/routes.dart';
import '../../../data/model/user_dto.dart';
import 'dialog/assignment_request_dialog.dart';

class CitizensScreen extends StatefulWidget {
  const CitizensScreen({super.key});

  @override
  _CitizensScreenState createState() => _CitizensScreenState();
}

class _CitizensScreenState extends State<CitizensScreen>
    with WidgetsBindingObserver {
  final int itemsPerPage = 10;
  int currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("widget state -> App is in the foreground (on resume)");
        break;
      case AppLifecycleState.inactive:
        print("widget state -> App is inactive (e.g., phone call)");
        break;
      case AppLifecycleState.paused:
        print("widget state -> App is in the background (on pause)");
        break;
      case AppLifecycleState.detached:
        print("widget state -> App is detached (e.g., being terminated)");
        break;
      case AppLifecycleState.hidden:
        print('widget state -> widget hidden');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      // Debounce search to avoid too many API calls
      _debounceSearch();
    });
  }

  Timer? _debounceTimer;
  
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final account = context.read<AccountCubit>().state;
        context.read<AdminUserCubitNew>().searchCitizens(_searchQuery, account: account);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<UserDto> getPaginatedItems(List<UserDto> citizensList) {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    return citizensList.sublist(
      startIndex,
      endIndex > citizensList.length ? citizensList.length : endIndex,
    );
  }

  void setPage(int pageNumber) {
    setState(() {
      currentPage = pageNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<AccountCubit>().state;

    return BlocProvider(
      key: const ValueKey('citizens_cubit'),
      create: (context) {
        final cubit = AdminUserCubitNew();
        cubit.fetchCitizens(account: account);
        return cubit;
      },
      child: BlocBuilder<AdminUserCubitNew, MentorDataState>(
          builder: (_context, _state) {
        final state = _state.state;
        return BlocListener<CitizenProfileCubit, CitizenProfileCubitState>(
          listener: (_, state1) {
            if (state1.state is AdminCitizenCubit ||
                state1.state is UpdateCitizenProfileSuccess) {
              _context
                  .read<AdminUserCubitNew>()
                  .fetchCitizens(account: account);
            }
          },
          child: BaseScaffold(
            isLoading: state is CubitStateLoading,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: AppBar(
                backgroundColor: AppColors.greyDark,
                flexibleSpace: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Search",
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: AppColors.greyWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      InputField(
                        controller: _searchController,
                        hint: 'Enter name or email to search',
                        radius: 10.0,
                        onChange: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          // Trigger search immediately when user types
                          final account = context.read<AccountCubit>().state;
                          _context.read<AdminUserCubitNew>().searchCitizens(value, account: account);
                        },
                        preffixIcon: const Icon(
                          CupertinoIcons.search,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Builder(builder: (
                      context,
                    ) {
                      if (state is CubitStateLoading) {
                        return const SizedBox();
                      }
                      if (state is CubitStateError) {
                        return Center(
                          child: Text(
                            "Error: ${state.message}",
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: AppColors.red,
                            ),
                          ),
                        );
                      }

                      final data = _state.data;
                      final citizensList = data;
                      
                      if (citizensList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 100,
                                color: AppColors.greyWhite,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No citizens available",
                                style: context.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.greyWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Search Name or Email",
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: AppColors.gray2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final totalPages =
                          (citizensList.length / itemsPerPage).ceil();
                      final paginatedItems = getPaginatedItems(citizensList);
                      final columns = [
                        const DataColumn(label: TableHeader("Name")),
                        const DataColumn(label: TableHeader("Email")),
                        const DataColumn(label: TableHeader("DOB")),
                        const DataColumn(label: TableHeader("Date Joined")),
                        const DataColumn(label: TableHeader("Actions")),
                      ];
                      List<DataRow> buildRows(context) {
                        return paginatedItems.map((item) {
                          return DataRow(
                            onSelectChanged: (isSelected) {
                              if (isSelected == true) {
                                _navigate(item);
                              }
                            },
                            cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          item.avatar ?? AppConstants.avatar),
                                    ),
                                  ),
                                  10.width,
                                  Text(item.name)
                                ],
                              )),
                              DataCell(Text(item.email ?? '')),
                              DataCell(Text(DateTime.tryParse(item.dob ?? '')
                                      ?.formatDate() ??
                                  '')),
                              DataCell(
                                  Text(item.createdAt?.formatDate() ?? '')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person_add, color: AppColors.primary),
                                      tooltip: 'Request Assignment',
                                      onPressed: () async {
                                        final account = context.read<AccountCubit>().state;
                                        if (account != null) {
                                          final result = await context.displayDialog(
                                            AssignmentRequestDialog(
                                              citizen: item,
                                              caseManager: account,
                                            ),
                                          );
                                          if (result == true) {
                                            // Refresh the citizens list if request was successful
                                            context.read<AdminUserCubitNew>().fetchCitizens(account: account);
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility, color: AppColors.greyWhite),
                                      tooltip: 'View Profile',
                                      onPressed: () => _navigate(item),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      }

                      final rows = buildRows(context);

                      return Column(
                        children: [
                          Container(
                            color: Colors.black,
                            child: ReusableTable(
                              columns: columns,
                              rows: rows,
                              headingRowColor: AppColors.white,
                              dataRowColor: AppColors.greyDark,
                              columnSpacing: 20.0,
                              dataRowHeight: 56.0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Pagination(
                            totalPages: totalPages,
                            currentPage: currentPage,
                            onPageSelected: setPage,
                          ),
                        ],
                      );
                    }),
                  ),
                )),
          ),
        );
      }),
    );
  }

  _navigate(UserDto profile) async {
    context.read<CitizenProfileCubit>()
      ..setCurrentUser(profile)
      ..fetchCitizenProfileInfo(profile);
    await Future.delayed(Duration(seconds: 1));

    context.goNamed(AppRoutes.citizenProfile.name,
        queryParameters: {'id': profile.userId});
  }
}

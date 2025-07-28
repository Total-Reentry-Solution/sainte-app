import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/core/theme/colors.dart';
import 'package:reentry/ui/components/app_bar.dart';
import 'package:reentry/ui/modules/blog/bloc/blog_cubit.dart';
import 'package:reentry/ui/modules/blog/bloc/blog_state.dart';
import 'package:reentry/data/model/blog_dto.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:reentry/ui/components/quill_text.dart';
import 'dart:convert';

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String category = 'All';

  final List<String> categories = [
    'All', 'Food', 'Housing', 'Health', 'Education', 'Money', 'Legal', 'Codes', 'Work'
  ];

  @override
  void initState() {
    super.initState();
    context.read<BlogCubit>().fetchResources();
  }

  List<BlogDto> filterResources(List<BlogDto> resources) {
    List<BlogDto> filtered = resources;
    if (category != 'All') {
      filtered = filtered.where((r) => (r.category ?? '') == category).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) =>
        (r.title.toLowerCase().contains(_searchQuery.toLowerCase())) ||
        (r.content.isNotEmpty && quill.Document.fromJson(r.content).toPlainText().toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    return filtered;
  }

  void showResourceDetail(BuildContext context, BlogDto resource) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.greyDark,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resource.imageUrl != null && resource.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(resource.imageUrl!, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    resource.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: 20),
                  QuillTextView(
                    text: resource.content.map((e) => jsonEncode(e)).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyDark,
      appBar: const CustomAppbar(title: 'Resources'),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Tabs
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: category == cat,
                    onSelected: (_) {
                      setState(() {
                        category = cat;
                      });
                    },
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for resources...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: AppColors.gray2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
            const SizedBox(height: 20),
            // Resource Cards
            Expanded(
              child: BlocBuilder<BlogCubit, BlogCubitState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state.isError) {
                    return Center(child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)));
                  } else if (state.data.isEmpty) {
                    return const Center(child: Text('No resources found', style: TextStyle(color: Colors.white)));
                  }
                  final filtered = filterResources(state.data);
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final resource = filtered[index];
                      return GestureDetector(
                        onTap: () => showResourceDetail(context, resource),
                        child: Container(
                          decoration: ShapeDecoration(
                            color: AppColors.greyDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          margin: const EdgeInsets.all(10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (resource.imageUrl != null && resource.imageUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: Image.network(
                                      resource.imageUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        resource.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        resource.content.isNotEmpty
                                            ? quill.Document.fromJson(resource.content).toPlainText()
                                            : '',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: AppColors.gray2,
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

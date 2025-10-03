import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Clean Resources Screen
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  String _selectedCategory = 'all';

  final List<ResourceCategory> _categories = [
    ResourceCategory(id: 'all', name: 'All', icon: Icons.apps),
    ResourceCategory(id: 'education', name: 'Education', icon: Icons.school),
    ResourceCategory(id: 'employment', name: 'Employment', icon: Icons.work),
    ResourceCategory(id: 'housing', name: 'Housing', icon: Icons.home),
    ResourceCategory(id: 'healthcare', name: 'Healthcare', icon: Icons.medical_services),
    ResourceCategory(id: 'legal', name: 'Legal', icon: Icons.gavel),
    ResourceCategory(id: 'financial', name: 'Financial', icon: Icons.account_balance),
    ResourceCategory(id: 'mental_health', name: 'Mental Health', icon: Icons.psychology),
  ];

  final List<Resource> _resources = [
    Resource(
      id: '1',
      title: 'Job Training Program',
      description: 'Comprehensive job training program for reentry citizens',
      category: 'employment',
      type: 'program',
      url: 'https://example.com/job-training',
      isFeatured: true,
    ),
    Resource(
      id: '2',
      title: 'Housing Assistance Guide',
      description: 'Step-by-step guide to finding affordable housing',
      category: 'housing',
      type: 'guide',
      url: 'https://example.com/housing-guide',
      isFeatured: false,
    ),
    Resource(
      id: '3',
      title: 'GED Preparation Course',
      description: 'Free online GED preparation course',
      category: 'education',
      type: 'course',
      url: 'https://example.com/ged-course',
      isFeatured: true,
    ),
    Resource(
      id: '4',
      title: 'Mental Health Support',
      description: '24/7 mental health support hotline',
      category: 'mental_health',
      type: 'service',
      url: 'https://example.com/mental-health',
      isFeatured: false,
    ),
    Resource(
      id: '5',
      title: 'Legal Aid Services',
      description: 'Free legal aid services for reentry citizens',
      category: 'legal',
      type: 'service',
      url: 'https://example.com/legal-aid',
      isFeatured: false,
    ),
    Resource(
      id: '6',
      title: 'Financial Literacy Workshop',
      description: 'Learn about budgeting, credit, and financial planning',
      category: 'financial',
      type: 'workshop',
      url: 'https://example.com/financial-literacy',
      isFeatured: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredResources = _selectedCategory == 'all'
        ? _resources
        : _resources.where((r) => r.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Resources',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category.id;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3AE6BD) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Resources List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredResources.length,
              itemBuilder: (context, index) {
                final resource = filteredResources[index];
                return _buildResourceCard(resource);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3AE6BD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getResourceIcon(resource.type),
                    color: const Color(0xFF3AE6BD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resource.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (resource.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resource.type.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              resource.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getCategoryName(resource.category),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openResource(resource),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AE6BD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('View Resource'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'program':
        return Icons.school;
      case 'guide':
        return Icons.article;
      case 'course':
        return Icons.play_circle;
      case 'service':
        return Icons.support_agent;
      case 'workshop':
        return Icons.groups;
      default:
        return Icons.description;
    }
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => ResourceCategory(id: categoryId, name: categoryId, icon: Icons.folder),
    );
    return category.name;
  }

  void _openResource(Resource resource) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            resource.title,
            style: const TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.description,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type: ${resource.type.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                'Category: ${_getCategoryName(resource.category)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Open resource URL
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening resource...'),
                    backgroundColor: Color(0xFF3AE6BD),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AE6BD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Search Resources',
            style: TextStyle(
              color: Color(0xFF3AE6BD),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This feature will allow you to search through all available resources.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF3AE6BD),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Data Models
class ResourceCategory {
  final String id;
  final String name;
  final IconData icon;

  ResourceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class Resource {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type;
  final String url;
  final bool isFeatured;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.url,
    this.isFeatured = false,
  });
}

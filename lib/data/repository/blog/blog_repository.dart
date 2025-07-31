import 'dart:io';
import 'dart:convert';
import 'package:reentry/data/model/blog_dto.dart';
import 'package:reentry/data/model/blog_request_dto.dart';
import 'package:reentry/data/repository/blog/blog_repository_interface.dart';
import 'package:reentry/exception/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/config/supabase_config.dart';
import '../../../ui/modules/blog/bloc/blog_event.dart';

class BlogRepository extends BlogRepositoryInterface {

  @override
  Future<String> uploadBlogImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await SupabaseConfig.client.storage
          .from('blog_images') // You'll need to create this bucket
          .upload(fileName, file);
      
      final url = SupabaseConfig.client.storage
          .from('blog_images')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      throw BaseExceptions('Failed to upload blog image: ${e.toString()}');
    }
  }

  @override
  Future<void> createBlog(CreateBlogEvent event) async {
    try {
      final blog = BlogDto(
        id: event.blogId,
        title: event.title,
        content: event.content,
        imageUrl: event.url,
        category: event.category,
        dateCreated: DateTime.now().toIso8601String(),
      );

      await SupabaseConfig.client
          .from(SupabaseConfig.blogPostsTable)
          .insert({
            'title': blog.title,
            'data': blog.content,
            'image_url': blog.imageUrl,
            'category': blog.category,
            'date': blog.dateCreated,
            'author_id': event.authorId,
            'author_name': event.authorName,
            'content': blog.content,
          });
    } catch (e) {
      throw BaseExceptions('Failed to create blog: ${e.toString()}');
    }
  }

  @override
  Future<List<BlogDto>> getBlogs() async {
    try {
      print('Fetching blogs from ${SupabaseConfig.blogPostsTable}...');
      print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      print('Current user: ${SupabaseConfig.currentUser?.id}');
      
      // Test the connection first
      try {
        final testResponse = await SupabaseConfig.client
            .from(SupabaseConfig.blogPostsTable)
            .select('count')
            .limit(1);
        print('Connection test successful: $testResponse');
      } catch (e) {
        print('Connection test failed: $e');
      }
      
      // Test with a simple select to see what's in the table
      try {
        final simpleTest = await SupabaseConfig.client
            .from(SupabaseConfig.blogPostsTable)
            .select('*')
            .limit(5);
        print('Simple test query result: $simpleTest');
        print('Simple test query length: ${simpleTest.length}');
      } catch (e) {
        print('Simple test query failed: $e');
      }
      
      // Test with a direct count query
      try {
        final countTest = await SupabaseConfig.client
            .from(SupabaseConfig.blogPostsTable)
            .select('id');
        print('Count test result length: ${countTest.length}');
      } catch (e) {
        print('Count test failed: $e');
      }
      
      // Test with different table name variations
      try {
        final publicTest = await SupabaseConfig.client
            .from('public.blog_posts')
            .select('*')
            .limit(1);
        print('Public schema test result: $publicTest');
      } catch (e) {
        print('Public schema test failed: $e');
      }
      
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.blogPostsTable)
          .select()
          .order('id', ascending: false);
      
      print('Raw response: $response');
      print('Response length: ${response.length}');
      
      final blogs = (response as List).map((blog) {
        print('Processing blog: ${blog['title']}');
        print('Blog data: $blog');
        
        // Handle content parsing more safely
        List<Map<String, dynamic>> content = [];
        try {
          if (blog['data'] != null) {
            if (blog['data'] is String) {
              // If data is a JSON string, parse it
              final parsed = jsonDecode(blog['data']);
              if (parsed is List) {
                content = parsed.cast<Map<String, dynamic>>();
              }
            } else if (blog['data'] is List) {
              content = blog['data'].cast<Map<String, dynamic>>();
            }
          }
        } catch (e) {
          print('Error parsing blog content: $e');
          content = [];
        }
        
        return BlogDto(
          id: blog['id'],
          title: blog['title'] ?? 'Untitled',
          content: content,
          authorName: blog['author_name'] ?? 'Anonymous',
          dateCreated: blog['date'],
          imageUrl: blog['image_url'],
          url: null, // url column doesn't exist in our schema
          userId: blog['author_id'] ?? '',
          category: blog['category'] ?? 'General',
        );
      }).toList();
      
      print('Processed ${blogs.length} blogs');
      return blogs;
    } catch (e) {
      print('Error fetching blogs: $e');
      throw BaseExceptions('Failed to get blogs: ${e.toString()}');
    }
  }

  @override
  Future<void> updateBlog(BlogDto blog) async {
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.blogPostsTable)
          .update({
            'title': blog.title,
            'content': blog.content,
            'image_url': blog.imageUrl,
            'category': blog.category,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', blog.id!);
    } catch (e) {
      throw BaseExceptions('Failed to update blog: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBlog(String id) async {
    try {
      await SupabaseConfig.client
          .from(SupabaseConfig.blogPostsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw BaseExceptions('Failed to delete blog: ${e.toString()}');
    }
  }

  Future<void> createBlogRequest(BlogRequestDto request) async {
    try {
      await SupabaseConfig.client
          .from('blog_requests')
          .insert({
            'id': request.id,
            'user_id': request.userId,
            'title': request.title,
            'content': request.content,
            'details': request.details,
            'status': request.status.name,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw BaseExceptions('Failed to create blog request: ${e.toString()}');
    }
  }

  Future<List<BlogRequestDto>> getBlogRequests() async {
    try {
      final response = await SupabaseConfig.client
          .from('blog_requests')
          .select()
          .order('created_at', ascending: false);
      
      return response.map((request) => BlogRequestDto(
        id: request['id'],
        userId: request['user_id'],
        title: request['title'] ?? '',
        content: request['content'] ?? '',
        details: request['details'] ?? '',
        status: BlogRequestStatus.values.firstWhere(
          (e) => e.name == request['status'],
          orElse: () => BlogRequestStatus.pending,
        ),
        createdAt: DateTime.parse(request['created_at']),
        updatedAt: DateTime.parse(request['updated_at']),
      )).toList();
    } catch (e) {
      throw BaseExceptions('Failed to get blog requests: ${e.toString()}');
    }
  }

  Future<void> requestBloc(RequestBlogEvent event) async {
    try {
      final request = event.toDto();
      await createBlogRequest(request);
    } catch (e) {
      throw BaseExceptions('Failed to create blog request: ${e.toString()}');
    }
  }

  Future<List<BlogDto>> getResources() async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.blogPostsTable)
          .select()
          .eq('category', 'Resource')
          .order('created_at', ascending: false);
      return (response as List).map((blog) => BlogDto(
        id: blog['id'],
        title: blog['title'],
        content: blog['data'] ?? [],
        authorName: blog['authorName'],
        dateCreated: blog['date'],
        imageUrl: blog['imageUrl'],
        url: blog['url'],
        userId: blog['userId'],
        category: blog['category'],
      )).toList();
    } catch (e) {
      throw BaseExceptions('Failed to get resources: ${e.toString()}');
    }
  }
}

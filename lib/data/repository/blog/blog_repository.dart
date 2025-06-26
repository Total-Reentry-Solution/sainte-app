import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reentry/core/config/supabase_config.dart';
import 'package:reentry/data/model/blog_dto.dart';
import 'package:reentry/data/repository/blog/blog_repository_interface.dart';
import 'package:reentry/ui/modules/blog/bloc/blog_event.dart';
import '../../../exception/app_exceptions.dart';

Future<String> uploadFile(Uint8List file) async {
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final userId = SupabaseConfig.currentUserId ?? 'anonymous';
    
    await SupabaseConfig.storage
        .from('blog_images')
        .uploadBinary('$userId/$fileName', file);
    
    final url = SupabaseConfig.storage
        .from('blog_images')
        .getPublicUrl('$userId/$fileName');
    
    return url;
  } catch (e) {
    throw BaseExceptions('Failed to upload file: ${e.toString()}');
  }
}

class BlogRepository extends BlogRepositoryInterface {
  final _supabase = SupabaseConfig.client;

  @override
  Future<BlogDto> createBlog(CreateBlogEvent body) async {
    try {
      String? url;

      if (body.file != null) {
        url = await uploadFile(body.file!);
      } else {
        url = body.url;
      }

      final blogData = {
        'title': body.title,
        'content': body.content,
        'category': body.category,
        'image_url': url,
        'author_id': SupabaseConfig.currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('blog_posts')
          .insert(blogData)
          .select()
          .single();

      final blogDto = BlogDto.fromJson(response);
      print('Blog created => ${blogDto.toJson()}');
      return blogDto;
    } catch (e) {
      throw BaseExceptions('Failed to create blog: ${e.toString()}');
    }
  }

  Future<void> requestBloc(RequestBlogEvent event) async {
    try {
      final requestData = {
        'title': event.title,
        'content': event.content,
        'category': event.category,
        'requested_by_id': SupabaseConfig.currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('blog_requests')
          .insert(requestData);
    } catch (e) {
      throw BaseExceptions('Failed to create blog request: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBlog(String blogId) async {
    try {
      await _supabase
          .from('blog_posts')
          .delete()
          .eq('id', blogId);
    } catch (e) {
      throw BaseExceptions('Failed to delete blog: ${e.toString()}');
    }
  }

  @override
  Future<List<BlogDto>> getBlogs() async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('*, user_profiles!blog_posts_author_id_fkey(*)')
          .order('created_at', ascending: false);

      return response.map((e) => BlogDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch blogs: ${e.toString()}');
    }
  }

  @override
  Future<void> updateBlog(BlogDto blog) async {
    try {
      final updateData = {
        'title': blog.title,
        'content': blog.content,
        'category': blog.category,
        'image_url': blog.imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('blog_posts')
          .update(updateData)
          .eq('id', blog.id);
    } catch (e) {
      throw BaseExceptions('Failed to update blog: ${e.toString()}');
    }
  }

  // Get blogs by category
  Future<List<BlogDto>> getBlogsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('*, user_profiles!blog_posts_author_id_fkey(*)')
          .eq('category', category)
          .order('created_at', ascending: false);

      return response.map((e) => BlogDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch blogs by category: ${e.toString()}');
    }
  }

  // Get blogs by author
  Future<List<BlogDto>> getBlogsByAuthor(String authorId) async {
    try {
      final response = await _supabase
          .from('blog_posts')
          .select('*, user_profiles!blog_posts_author_id_fkey(*)')
          .eq('author_id', authorId)
          .order('created_at', ascending: false);

      return response.map((e) => BlogDto.fromJson(e)).toList();
    } catch (e) {
      throw BaseExceptions('Failed to fetch blogs by author: ${e.toString()}');
    }
  }

  // Get blog requests
  Future<List<Map<String, dynamic>>> getBlogRequests() async {
    try {
      final response = await _supabase
          .from('blog_requests')
          .select('*, user_profiles!blog_requests_requested_by_id_fkey(*)')
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw BaseExceptions('Failed to fetch blog requests: ${e.toString()}');
    }
  }

  // Delete blog request
  Future<void> deleteBlogRequest(String requestId) async {
    try {
      await _supabase
          .from('blog_requests')
          .delete()
          .eq('id', requestId);
    } catch (e) {
      throw BaseExceptions('Failed to delete blog request: ${e.toString()}');
    }
  }
}

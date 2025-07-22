import 'dart:io';
import 'dart:typed_data';

import 'package:reentry/data/model/blog_request_dto.dart';

class CreateBlogEvent extends BlogEvent {
  final Uint8List? file;
  String? blogId;
  String title;
  final String? url;
  final String category;
  final List<Map<String,dynamic>> content;
  final String authorId;

  CreateBlogEvent(
      {required this.title, this.file,this.url, required this.content,this.blogId,required this.category, required this.authorId});
}

class RequestBlogEvent extends BlogEvent {
  final String title;
  final String userId;
  final String email;
  final String details;

  RequestBlogEvent(
      {required this.userId,
      required this.title,
      required this.email,
      required this.details});
  BlogRequestDto toDto(){
    return BlogRequestDto(
      userId: userId,
      title: title,
      content: details,
      status: BlogRequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      details: '', // Dummy value for required parameter
    );
  }
}

sealed class BlogEvent {}
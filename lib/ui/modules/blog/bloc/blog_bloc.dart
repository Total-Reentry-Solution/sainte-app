import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reentry/data/repository/blog/blog_repository.dart';
import 'package:reentry/ui/modules/blog/bloc/blog_event.dart';
import 'package:reentry/ui/modules/blog/bloc/blog_state.dart';
import 'package:reentry/data/model/blog_dto.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  BlogBloc() : super(BlogInitial()) {
    on<CreateBlogEvent>(_createBlog);
    on<RequestBlogEvent>(_requestBlog);
  }

  final _repo = BlogRepository();

  Future<void> _createBlog(
      CreateBlogEvent event, Emitter<BlogState> emit) async {

    emit(BlogLoading());
    try {
      await _repo.createBlog(event);
      if(event.blogId!=null){
        emit(UpdateBlogSuccess(BlogDto(
          id: event.blogId,
          title: event.title,
          content: event.content,
          imageUrl: event.url,
          category: event.category,
        )));
        return;
      }
      emit(CreateBlogContentSuccess());
    } catch (e) {
      print('error handling -> ${e.toString()}');
      emit(BlogError(e.toString()));
    }
  }

  Future<void> _requestBlog(
      RequestBlogEvent event, Emitter<BlogState> emit) async {
    emit(BlogLoading());
    try {
      await _repo.requestBloc(event);
      emit(RequestBlogSuccess());
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }
}

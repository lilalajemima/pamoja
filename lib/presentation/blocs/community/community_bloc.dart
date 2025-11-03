import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/models/community_post.dart';

// Events
abstract class CommunityEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPosts extends CommunityEvent {}

class CreatePost extends CommunityEvent {
  final String content;

  CreatePost(this.content);

  @override
  List<Object?> get props => [content];
}

class LikePost extends CommunityEvent {
  final String postId;

  LikePost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CommentOnPost extends CommunityEvent {
  final String postId;
  final String comment;

  CommentOnPost(this.postId, this.comment);

  @override
  List<Object?> get props => [postId, comment];
}

// States
abstract class CommunityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<CommunityPost> posts;

  CommunityLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class CommunityError extends CommunityState {
  final String message;

  CommunityError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  List<CommunityPost> _posts = [];

  CommunityBloc() : super(CommunityInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<CreatePost>(_onCreatePost);
    on<LikePost>(_onLikePost);
    on<CommentOnPost>(_onCommentOnPost);
  }

  Future<void> _onLoadPosts(
      LoadPosts event,
      Emitter<CommunityState> emit,
      ) async {
    emit(CommunityLoading());

    try {
      await Future.delayed(const Duration(seconds: 1));

      _posts = _getMockPosts();
      emit(CommunityLoaded(_posts));
    } catch (e) {
      emit(CommunityError('Failed to load posts'));
    }
  }

  Future<void> _onCreatePost(
      CreatePost event,
      Emitter<CommunityState> emit,
      ) async {
    if (state is CommunityLoaded) {
      final newPost = CommunityPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorName: 'Current User',
        authorAvatar: 'https://i.pravatar.cc/150?img=1',
        content: event.content,
        timestamp: DateTime.now(),
        likes: 0,
        comments: 0,
      );

      _posts.insert(0, newPost);
      emit(CommunityLoaded(List.from(_posts)));
    }
  }

  Future<void> _onLikePost(
      LikePost event,
      Emitter<CommunityState> emit,
      ) async {
    if (state is CommunityLoaded) {
      final index = _posts.indexWhere((p) => p.id == event.postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          likes: _posts[index].likes + 1,
        );
        emit(CommunityLoaded(List.from(_posts)));
      }
    }
  }

  Future<void> _onCommentOnPost(
      CommentOnPost event,
      Emitter<CommunityState> emit,
      ) async {
    if (state is CommunityLoaded) {
      final index = _posts.indexWhere((p) => p.id == event.postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          comments: _posts[index].comments + 1,
        );
        emit(CommunityLoaded(List.from(_posts)));
      }
    }
  }

  List<CommunityPost> _getMockPosts() {
    return [
      CommunityPost(
        id: '1',
        authorName: 'Sophia',
        authorAvatar: 'https://i.pravatar.cc/150?img=5',
        content: 'Volunteering at the local animal shelter was such a rewarding experience! I got to help care for the animals and meet some amazing people. Highly recommend it to anyone looking to give back.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        likes: 23,
        comments: 5,
      ),
      CommunityPost(
        id: '2',
        authorName: 'Ethan',
        authorAvatar: 'https://i.pravatar.cc/150?img=12',
        content: 'Spent the day helping out at the community garden. It\'s incredible to see the impact we can have when we come together. Plus, fresh veggies are a bonus!',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        likes: 18,
        comments: 3,
      ),
      CommunityPost(
        id: '3',
        authorName: 'Olivia',
        authorAvatar: 'https://i.pravatar.cc/150?img=9',
        content: 'Had a blast volunteering at the youth center today! Played games with the kids and helped with their homework. Their smiles made it all worthwhile.',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        likes: 31,
        comments: 7,
      ),
    ];
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class DeletePost extends CommunityEvent {
  final String postId;

  DeletePost(this.postId);

  @override
  List<Object?> get props => [postId];
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

class CommunityOperationSuccess extends CommunityState {
  final String message;
  final List<CommunityPost> posts;

  CommunityOperationSuccess(this.message, this.posts);

  @override
  List<Object?> get props => [message, posts];
}

// BLoC
class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommunityBloc({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(CommunityInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<CreatePost>(_onCreatePost);
    on<LikePost>(_onLikePost);
    on<CommentOnPost>(_onCommentOnPost);
    on<DeletePost>(_onDeletePost);
  }

  Future<void> _onLoadPosts(
    LoadPosts event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityLoading());

    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Handle Firestore Timestamp
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.parse(data['timestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return CommunityPost(
          id: doc.id,
          authorName: data['authorName'] ?? 'Anonymous',
          authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
          content: data['content'] ?? '',
          timestamp: timestamp,
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
        );
      }).toList();

      emit(CommunityLoaded(posts));
    } catch (e) {
      emit(CommunityError('Failed to load posts: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(CommunityError('You must be logged in to create a post'));
        return;
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String userName = 'User';
      String userAvatar = 'https://i.pravatar.cc/150?img=1';

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userName = userData['name'] ?? 'User';
        userAvatar = userData['avatarUrl'] ?? 'https://i.pravatar.cc/150?img=1';
      }

      // Create post in Firebase
      await _firestore.collection('posts').add({
        'authorId': user.uid,
        'authorName': userName,
        'authorAvatar': userAvatar,
        'content': event.content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });

      // Reload posts to show the new one
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.parse(data['timestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return CommunityPost(
          id: doc.id,
          authorName: data['authorName'] ?? 'Anonymous',
          authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
          content: data['content'] ?? '',
          timestamp: timestamp,
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
        );
      }).toList();

      emit(CommunityOperationSuccess('Post created successfully!', posts));
    } catch (e) {
      emit(CommunityError('Failed to create post: ${e.toString()}'));
    }
  }

  Future<void> _onLikePost(
    LikePost event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      // Update likes count in Firebase
      await _firestore.collection('posts').doc(event.postId).update({
        'likes': FieldValue.increment(1),
      });

      // Reload posts
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.parse(data['timestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return CommunityPost(
          id: doc.id,
          authorName: data['authorName'] ?? 'Anonymous',
          authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
          content: data['content'] ?? '',
          timestamp: timestamp,
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
        );
      }).toList();

      emit(CommunityLoaded(posts));
    } catch (e) {
      emit(CommunityError('Failed to like post: ${e.toString()}'));
    }
  }

  Future<void> _onCommentOnPost(
    CommentOnPost event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      // Update comments count in Firebase
      await _firestore.collection('posts').doc(event.postId).update({
        'comments': FieldValue.increment(1),
      });

      // Optionally: Store the actual comment in a subcollection
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('posts')
            .doc(event.postId)
            .collection('commentsList')
            .add({
          'userId': user.uid,
          'comment': event.comment,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Reload posts
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.parse(data['timestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return CommunityPost(
          id: doc.id,
          authorName: data['authorName'] ?? 'Anonymous',
          authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
          content: data['content'] ?? '',
          timestamp: timestamp,
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
        );
      }).toList();

      emit(CommunityOperationSuccess('Comment added!', posts));
    } catch (e) {
      emit(CommunityError('Failed to add comment: ${e.toString()}'));
    }
  }

  Future<void> _onDeletePost(
    DeletePost event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(CommunityError('You must be logged in to delete posts'));
        return;
      }

      // Check if user owns the post
      final postDoc = await _firestore.collection('posts').doc(event.postId).get();
      
      if (!postDoc.exists) {
        emit(CommunityError('Post not found'));
        return;
      }

      final postData = postDoc.data()!;
      
      if (postData['authorId'] != user.uid) {
        emit(CommunityError('You can only delete your own posts'));
        return;
      }

      // Delete the post
      await _firestore.collection('posts').doc(event.postId).delete();

      // Reload posts
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      final posts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        DateTime timestamp;
        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          timestamp = DateTime.parse(data['timestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return CommunityPost(
          id: doc.id,
          authorName: data['authorName'] ?? 'Anonymous',
          authorAvatar: data['authorAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
          content: data['content'] ?? '',
          timestamp: timestamp,
          likes: data['likes'] ?? 0,
          comments: data['comments'] ?? 0,
        );
      }).toList();

      emit(CommunityOperationSuccess('Post deleted successfully!', posts));
    } catch (e) {
      emit(CommunityError('Failed to delete post: ${e.toString()}'));
    }
  }
}
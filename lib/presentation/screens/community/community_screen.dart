import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/community/community_bloc.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CommunityBloc>().add(LoadPosts());
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Community'),
      centerTitle: true,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showCreatePostDialog(context),
        ),
      ],
    );
  }

  // ==================== BODY ====================
  Widget _buildBody() {
    return BlocConsumer<CommunityBloc, CommunityState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        if (state is CommunityLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CommunityError) {
          return _buildErrorState(state.message);
        }

        final posts = _getPosts(state);
        return _buildPostsList(posts);
      },
    );
  }

  // ==================== STATE HANDLERS ====================
  void _handleStateChanges(BuildContext context, CommunityState state) {
    if (state is CommunityOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  List<dynamic> _getPosts(CommunityState state) {
    if (state is CommunityLoaded) {
      return state.posts;
    } else if (state is CommunityOperationSuccess) {
      return state.posts;
    }
    return [];
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<CommunityBloc>().add(LoadPosts());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ==================== POSTS LIST ====================
  Widget _buildPostsList(List<dynamic> posts) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CommunityBloc>().add(LoadPosts());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildPostInputSection(),
            const SizedBox(height: 24),
            _buildRecentPostsHeader(),
            const SizedBox(height: 16),
            posts.isEmpty ? _buildEmptyState() : _buildPostsContent(posts),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPostInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showCreatePostDialog(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.lightGreen,
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post an update',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share your volunteering experience',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPostsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Recent posts',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 64, color: AppTheme.mediumGray),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your story!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsContent(List<dynamic> posts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return FutureBuilder<DocumentSnapshot?>(
            future: _getPostAuthorId(post.authorName),
            builder: (context, snapshot) {
              final currentUser = FirebaseAuth.instance.currentUser;
              final authorId = snapshot.data?.id;
              final isOwnPost = currentUser != null &&
                  (authorId == currentUser.uid ||
                      post.authorName == (currentUser.displayName ?? 'User'));

              return _PostCard(
                post: post,
                isOwnPost: isOwnPost,
                onLike: () {
                  context.read<CommunityBloc>().add(LikePost(post.id));
                },
                onComment: () {
                  _showCommentDialog(context, post.id);
                },
                onViewComments: () {
                  _showCommentsSheet(context, post.id);
                },
                onEdit: isOwnPost
                    ? () {
                        _showEditPostDialog(context, post.id, post.content);
                      }
                    : null,
                onDelete: isOwnPost
                    ? () {
                        _showDeleteConfirmation(context, post.id);
                      }
                    : null,
                onProfileTap: () {
                  if (authorId != null) {
                    _showUserProfile(context, post.authorName, authorId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // ==================== FIREBASE QUERIES ====================
  Future<DocumentSnapshot?> _getPostAuthorId(String authorName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: authorName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    } catch (e) {
      print('Error getting author ID: $e');
    }
    return null;
  }

  // ==================== DIALOGS & MODALS ====================
  void _showCreatePostDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Post',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _postController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your volunteering experience...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_postController.text.isNotEmpty) {
                      context.read<CommunityBloc>().add(
                            CreatePost(_postController.text),
                          );
                      _postController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPostDialog(
      BuildContext context, String postId, String currentContent) {
    final editController = TextEditingController(text: currentContent);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Post',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Edit your post...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (editController.text.isNotEmpty) {
                      context.read<CommunityBloc>().add(
                            EditPost(postId, editController.text),
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CommunityBloc>().add(DeletePost(postId));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context, String postId) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Write your comment...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                context.read<CommunityBloc>().add(
                      CommentOnPost(postId, commentController.text),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Comment'),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('commentsList')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.comment_outlined,
                                size: 64, color: AppTheme.mediumGray),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    final comments = snapshot.data!.docs;

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment =
                            comments[index].data() as Map<String, dynamic>;
                        return _CommentItem(comment: comment);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primaryGreen),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          context.read<CommunityBloc>().add(
                                CommentOnPost(postId, commentController.text),
                              );
                          commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserProfile(
      BuildContext context, String authorName, String authorId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final userData = userDoc.data()!;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.lightGreen,
                          backgroundImage: userData['avatarUrl'] != null
                              ? CachedNetworkImageProvider(
                                  userData['avatarUrl'])
                              : null,
                          child: userData['avatarUrl'] == null
                              ? Text(
                                  authorName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['name'] ?? authorName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData['role'] ?? 'Volunteer',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 32),

                        // Skills
                        if (userData['skills'] != null &&
                            (userData['skills'] as List).isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Skills',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                (userData['skills'] as List).map((skill) {
                              return Chip(
                                label: Text(skill.toString()),
                                backgroundColor: AppTheme.lightGreen,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }
}

// ==================== COMMENT ITEM WIDGET ====================
class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.lightGreen,
            child: Icon(Icons.person, size: 16, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['userName'] ?? 'User',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  comment['comment'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== POST CARD WIDGET ====================
class _PostCard extends StatelessWidget {
  final dynamic post;
  final bool isOwnPost;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onViewComments;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onProfileTap;

  const _PostCard({
    required this.post,
    required this.isOwnPost,
    required this.onLike,
    required this.onComment,
    required this.onViewComments,
    required this.onProfileTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(context),
          const SizedBox(height: 12),
          _buildPostContent(context),
          const SizedBox(height: 12),
          _buildPostActions(context),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.lightGreen,
            backgroundImage: post.authorAvatar != null
                ? CachedNetworkImageProvider(post.authorAvatar)
                : null,
            child: post.authorAvatar == null
                ? Icon(Icons.person, color: AppTheme.primaryGreen)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onProfileTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (isOwnPost)
          PopupMenuButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.mediumGray),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Text(
      post.content,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildPostActions(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onLike,
          child: Row(
            children: [
              const Icon(Icons.favorite_border,
                  size: 20, color: AppTheme.mediumGray),
              const SizedBox(width: 6),
              Text(
                post.likes.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: onViewComments,
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 20, color: AppTheme.mediumGray),
              const SizedBox(width: 6),
              Text(
                post.comments.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
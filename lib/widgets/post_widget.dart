import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/profile_screen.dart';
import 'comment_widget.dart';

class PostWidget extends StatefulWidget {
  final PostModel post;
  final String username;
  final String? photoUrl;
  
  PostWidget({
    required this.post,
    required this.username,
    this.photoUrl,
  });
  
  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLiked = false;
  bool _showComments = false;
  
  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }
  
  void _checkIfLiked() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId != null) {
      setState(() {
        _isLiked = widget.post.likes.contains(userId);
      });
    }
  }
  
  void _toggleLike() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) return;
    
    setState(() {
      _isLiked = !_isLiked;
    });
    
    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.id, userId);
      } else {
        await _firestoreService.unlikePost(widget.post.id, userId);
      }
    } catch (e) {
      // If error, revert the UI state
      setState(() {
        _isLiked = !_isLiked;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }
  
  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
  }
  
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.post.userId),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          ListTile(
            leading: GestureDetector(
              onTap: _navigateToProfile,
              child: CircleAvatar(
                backgroundImage: widget.photoUrl != null
                    ? NetworkImage(widget.photoUrl!)
                    : null,
                child: widget.photoUrl == null
                    ? Text(widget.username.substring(0, 1).toUpperCase())
                    : null,
              ),
            ),
            title: GestureDetector(
              onTap: _navigateToProfile,
              child: Text(
                widget.username,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(widget.post.timestamp),
            ),
          ),
          
          // Post Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              widget.post.text,
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          
          // Post Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text('${widget.post.likes.length}'),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: _toggleComments,
                    ),
                    Text('${widget.post.commentCount}'),
                  ],
                ),
              ],
            ),
          ),
          
          // Comments Section
          if (_showComments)
            CommentSection(postId: widget.post.id),
        ],
      ),
    );
  }
}

class CommentSection extends StatefulWidget {
  final String postId;
  
  CommentSection({required this.postId});
  
  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  
  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to comment'))
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final commentId = Uuid().v4();
      
      final comment = CommentModel(
        id: commentId,
        postId: widget.postId,
        userId: userId,
        text: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );
      
      await _firestoreService.addComment(comment);
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(),
        
        // Comments list
        StreamBuilder<List<CommentModel>>(
          stream: _firestoreService.getComments(widget.postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('Error loading comments')),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('No comments yet')),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                CommentModel comment = snapshot.data![index];
                return CommentWidget(comment: comment);
              },
            );
          },
        ),
        
        // Add Comment input
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0, 
                      vertical: 8.0,
                    ),
                    enabled: !_isSubmitting,
                  ),
                  maxLines: 1,
                ),
              ),
              SizedBox(width: 8.0),
              _isSubmitting 
                ? SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _addComment,
                    color: Theme.of(context).primaryColor,
                  ),
            ],
          ),
        ),
      ],
    );
  }
} 
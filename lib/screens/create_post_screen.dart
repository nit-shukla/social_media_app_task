import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  
  void _createPost() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post cannot be empty'))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to create a post'))
        );
        Navigator.pop(context);
        return;
      }
      
      final postId = Uuid().v4();
      final post = PostModel(
        id: postId,
        userId: user.uid,
        text: _textController.text.trim(),
        timestamp: DateTime.now(),
      );
      
      await _firestoreService.createPost(post);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created successfully!'))
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User info bar
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      FutureBuilder<UserModel?>(
                        future: _firestoreService.getUser(
                          Provider.of<AuthService>(context).currentUser?.uid ?? '',
                        ),
                        builder: (context, snapshot) {
                          String username = 'User';
                          String? photoUrl;
                          
                          if (snapshot.hasData) {
                            username = snapshot.data!.username;
                            photoUrl = snapshot.data!.photoUrl;
                          }
                          
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl == null
                                    ? Text(username.substring(0, 1).toUpperCase())
                                    : null,
                              ),
                              SizedBox(width: 10),
                              Text(
                                username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Divider(height: 1),
                
                // Text input area
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        border: InputBorder.none,
                      ),
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                
                // Post button
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 
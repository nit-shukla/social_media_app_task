import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/post_widget.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  
  ProfileScreen({required this.userId});
  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<UserModel?> _userFuture;
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    _userFuture = _firestoreService.getUser(widget.userId);
  }
  
  void _toggleEdit(UserModel user) {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _bioController.text = user.bio ?? '';
      }
    });
  }
  
  void _saveProfile(UserModel user) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestoreService.updateUserProfile(
        user.id,
        bio: _bioController.text.trim(),
      );
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      
      _loadUserData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!'))
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isCurrentUser = authService.currentUser?.uid == widget.userId;
    
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData) {
          return Center(child: Text('User not found'));
        }
        
        final user = snapshot.data!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(user.username),
            actions: isCurrentUser
                ? [
                    IconButton(
                      icon: Icon(_isEditing ? Icons.close : Icons.edit),
                      onPressed: () => _toggleEdit(user),
                    ),
                  ]
                : null,
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.username.substring(0, 1).toUpperCase(),
                                  style: TextStyle(fontSize: 30),
                                )
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              if (_isEditing)
                                TextField(
                                  controller: _bioController,
                                  decoration: InputDecoration(
                                    labelText: 'Bio',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                )
                              else
                                Text(user.bio ?? 'No bio'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isEditing)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () => _saveProfile(user),
                          child: Text('Save Profile'),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: StreamBuilder<List<PostModel>>(
                  stream: _firestoreService.getUserPosts(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No posts yet'));
                    }
                    
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        PostModel post = snapshot.data![index];
                        return PostWidget(
                          post: post,
                          username: user.username,
                          photoUrl: user.photoUrl,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 
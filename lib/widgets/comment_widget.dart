import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../screens/profile_screen.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final FirestoreService _firestoreService = FirestoreService();
  
  CommentWidget({
    required this.comment,
  });
  
  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUser(comment.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        String username = snapshot.hasData 
            ? snapshot.data!.username 
            : 'Unknown user';
        String? photoUrl = snapshot.hasData 
            ? snapshot.data!.photoUrl 
            : null;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(context, comment.userId),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(username.substring(0, 1).toUpperCase())
                      : null,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToProfile(context, comment.userId),
                          child: Text(
                            username,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          DateFormat.jm().format(comment.timestamp),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(comment.text),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 
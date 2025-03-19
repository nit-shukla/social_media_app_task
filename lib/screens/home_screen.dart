import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../widgets/post_widget.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Social App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: _getBody(_currentIndex),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePostScreen()),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return HomeFeed();
      case 1:
        return ProfileScreen(userId: Provider.of<AuthService>(context).currentUser!.uid);
      default:
        return HomeFeed();
    }
  }
}

class HomeFeed extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: _firestoreService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No posts yet. Create the first one!'));
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            PostModel post = snapshot.data![index];
            return FutureBuilder<UserModel?>(
              future: _firestoreService.getUser(post.userId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                String username = userSnapshot.hasData 
                    ? userSnapshot.data!.username 
                    : 'Unknown user';
                String? photoUrl = userSnapshot.hasData 
                    ? userSnapshot.data!.photoUrl 
                    : null;
                
                return PostWidget(
                  post: post,
                  username: username,
                  photoUrl: photoUrl,
                );
              },
            );
          },
        );
      },
    );
  }
} 
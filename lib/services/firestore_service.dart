import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');
  final CollectionReference _commentsCollection = FirebaseFirestore.instance.collection('comments');
  
  // Check if user exists
  Future<bool> userExists(String userId) async {
    DocumentSnapshot doc = await _usersCollection.doc(userId).get();
    return doc.exists;
  }
  
  // Create a new user
  Future<void> createUser(UserModel user) async {
    return await _usersCollection.doc(user.id).set(user.toMap());
  }
  
  // Get user data
  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _usersCollection.doc(userId).get();
    
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    
    return null;
  }
  
  // Update user profile
  Future<void> updateUserProfile(String userId, {String? bio, String? photoUrl}) async {
    Map<String, dynamic> data = {};
    
    if (bio != null) data['bio'] = bio;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    
    return await _usersCollection.doc(userId).update(data);
  }
  
  // Create a new post
  Future<void> createPost(PostModel post) async {
    return await _postsCollection.doc(post.id).set(post.toMap());
  }
  
  // Get all posts for the feed
  Stream<List<PostModel>> getPosts() {
    return _postsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            );
          }).toList();
        });
  }
  
  // Get posts by a specific user
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            );
          }).toList();
        });
  }
  
  // Like a post
  Future<void> likePost(String postId, String userId) async {
    return await _postsCollection.doc(postId).update({
      'likes': FieldValue.arrayUnion([userId])
    });
  }
  
  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    return await _postsCollection.doc(postId).update({
      'likes': FieldValue.arrayRemove([userId])
    });
  }
  
  // Add a comment to a post
  Future<void> addComment(CommentModel comment) async {
    await _commentsCollection.doc(comment.id).set(comment.toMap());
    
    return await _postsCollection.doc(comment.postId).update({
      'commentCount': FieldValue.increment(1)
    });
  }
  
  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _commentsCollection
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CommentModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            );
          }).toList();
        });
  }
} 
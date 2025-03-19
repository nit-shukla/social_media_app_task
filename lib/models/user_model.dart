class UserModel {
  final String id;
  final String email;
  final String username;
  final String? bio;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.bio,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      bio: map['bio'],
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? bio,
    String? photoUrl,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      username: this.username,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
} 
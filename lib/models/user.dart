class AppUser {
  final String username;
  final String email;
  final String password; // NOTE: Store hashes in real apps
  final String image;    // URL to the image

  const AppUser({
    required this.username,
    required this.email,
    required this.password,
    required this.image,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'email': email,
        'password': password,
        'image': image,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      username: (map['username'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
      image: (map['image'] ?? '').toString(),
    );
  }
}



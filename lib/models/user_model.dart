class User {
  final String username;
  final String password;
  final Map<String, String> reviews; // businessId -> reviewText
  final List<String> favorites;      // list of businessIds
  final int businesses;
  final bool isAdmin;
  final int userType;

  User({
    required this.username,
    required this.password,
    this.reviews = const {},
    this.favorites = const [],
    this.businesses = 0,
    this.isAdmin = false,
    this.userType = 0,
  });

  bool get isOwner => userType > 0;

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'reviews': reviews,
      'favorites': favorites,
      'businesses': businesses,
      'isAdmin': isAdmin,
      'userType': userType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      reviews: Map<String, String>.from(map['reviews'] ?? {}),
      favorites: List<String>.from(map['favorites'] ?? []),
      businesses: map['businesses'] ?? 0,
      isAdmin: map['isAdmin'] ?? false,
      userType: map['userType'] ?? 0,
    );
  }

  User copyWith({
    String? username,
    String? password,
    Map<String, String>? reviews,
    List<String>? favorites,
    int? businesses,
    bool? isAdmin,
    int? userType,
  }) {
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      reviews: reviews ?? this.reviews,
      favorites: favorites ?? this.favorites,
      businesses: businesses ?? this.businesses,
      isAdmin: isAdmin ?? this.isAdmin,
      userType: userType ?? this.userType,
    );
  }
}

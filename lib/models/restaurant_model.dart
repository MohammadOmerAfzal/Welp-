class Restaurant {
  String id;
  String name;
  String description;
  String imageUrl;
  double averageRating;
  String location;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.averageRating,
    required this.location,
  });

  factory Restaurant.fromMap(Map<String, dynamic> data, String docId) {
    return Restaurant(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      location: data['location'] ?? '',
    );
  }
}


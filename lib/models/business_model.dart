class Business {
  String id;
  String ownerid;
  String name;
  String description;
  List<String> imageBase64List;
  double averageRating;
  String location;
  String category;
  double latitude;
  double longitude;

  Business({
    required this.id,
    required this.ownerid,
    required this.name,
    required this.description,
    required this.imageBase64List,
    required this.averageRating,
    required this.location,
    required this.category,
    required this.latitude,
    required this.longitude,
  });

  factory Business.fromMap(Map<String, dynamic> data, String docId) {
    return Business(
      id: docId,
      name: data['name'] ?? '',
      ownerid: data['ownerid'] ?? '',
      description: data['description'] ?? '',
      imageBase64List: List<String>.from(data['images'] ?? []),
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      category: data['category'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerid': ownerid,
      'name': name,
      'description': description,
      'images': imageBase64List,
      'averageRating': averageRating,
      'location': location,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
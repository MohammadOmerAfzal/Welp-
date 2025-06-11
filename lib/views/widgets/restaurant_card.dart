import 'package:flutter/material.dart';
import '../../models/restaurant_model.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: Image.network(restaurant.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
        title: Text(restaurant.name),
        subtitle: Text('${restaurant.averageRating.toString()} ★\n${restaurant.description}'),
        isThreeLine: true,
        onTap: () {
          Navigator.pushNamed(context, '/restaurant/${restaurant.id}');
        },
      ),
    );
  }
}

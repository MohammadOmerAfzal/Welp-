import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../controllers/restaurant_controller.dart';
import '../../models/restaurant_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = '';
  final DatabaseReference _restaurantsRef =
  FirebaseDatabase.instance.ref().child('restaurants');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Restaurants'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Restaurants...',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() => _searchText = val.toLowerCase());
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _restaurantsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final restaurantList = data.entries
              .map((entry) => {
            'id': entry.key,
            ...Map<String, dynamic>.from(entry.value),
          })
              .where((restaurant) =>
              (restaurant['name'] ?? '')
                  .toLowerCase()
                  .contains(_searchText))
              .toList();

          return ListView.builder(
            itemCount: restaurantList.length,
            itemBuilder: (context, index) {
              final restaurant = restaurantList[index];
              return ListTile(
                title: Text(restaurant['name']),
                subtitle: Text(restaurant['location'] ?? ''),
                onTap: () => Navigator.pushNamed(
                    context, '/restaurant/${restaurant['id']}'),
              );
            },
          );
        },
      ),
    );
  }
}

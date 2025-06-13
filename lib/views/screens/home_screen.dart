import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../controllers/business_controller.dart'; // optional, if used
import '../../models/business_model.dart'; // optional, if used

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = '';
  final DatabaseReference _businessRef =
  FirebaseDatabase.instance.ref().child('businesses');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Businesses'),
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
                hintText: 'Search businesses...',
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
        stream: _businessRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final businessList = data.entries
              .map((entry) => {
            'id': entry.key,
            ...Map<String, dynamic>.from(entry.value),
          })
              .where((business) =>
              (business['name'] ?? '')
                  .toLowerCase()
                  .contains(_searchText))
              .toList();

          return ListView.builder(
            itemCount: businessList.length,
            itemBuilder: (context, index) {
              final business = businessList[index];
              return ListTile(
                title: Text(business['name'] ?? 'Unnamed'),
                subtitle: Text(business['category'] ?? 'No category'),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/business/${business['id']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

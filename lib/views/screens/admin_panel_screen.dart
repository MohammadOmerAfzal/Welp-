import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';


class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final DatabaseReference _businessesRef = FirebaseDatabase.instance.ref().child('businesses');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _updateUserRole(String uid, {required bool isAdmin, required bool isOwner}) async {
    try {
      await _usersRef.child(uid).update({
        'isAdmin': isAdmin,
        'isOwner': isOwner,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ User role updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update role: $e')),
      );
    }
  }

  Widget _buildBusinessTile(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unnamed';
    final lat = data['latitude'];
    final lng = data['longitude'];
    final imageList = data['images'] as List<dynamic>?;

    Widget imageWidget = Icon(Icons.image_not_supported);
    if (imageList != null && imageList.isNotEmpty) {
      imageWidget = FutureBuilder<Uint8List>(
        future: Future(() => base64Decode(imageList.first)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: 50,
              height: 50,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Icon(Icons.broken_image);
          } else {
            return Image.memory(snapshot.data!, width: 50, height: 50, fit: BoxFit.cover);
          }
        },
      );
    }


    return Card(
      child: ListTile(
        leading: imageWidget,
        title: Text(name),
        subtitle: Text(
          (lat != null && lng != null)
              ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
              : 'Location: Not available',
        ),
      ),
    );
  }

  Widget _buildUserTile(String uid, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';
    final isAdmin = data['isAdmin'] == true;
    final isOwner = data['isOwner'] == true;

    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Make Admin',
              icon: Icon(Icons.admin_panel_settings, color: isAdmin ? Colors.green : Colors.grey),
              onPressed: () => _updateUserRole(uid, isAdmin: true, isOwner: false),
            ),
            IconButton(
              tooltip: 'Make Owner',
              icon: Icon(Icons.store_mall_directory, color: isOwner ? Colors.orange : Colors.grey),
              onPressed: () => _updateUserRole(uid, isAdmin: false, isOwner: true),
            ),
            IconButton(
              tooltip: 'Make Normal User',
              icon: Icon(Icons.person_off),
              onPressed: () => _updateUserRole(uid, isAdmin: false, isOwner: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Businesses List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            StreamBuilder<DatabaseEvent>(
              stream: _businessesRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('No businesses found.'));
                }


                final businesses = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final list = businesses.entries.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final data = Map<String, dynamic>.from(list[index].value);
                    return _buildBusinessTile(data);
                  },
                );
              },
            ),
            Divider(height: 40),
            Text('👥 User Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            StreamBuilder<DatabaseEvent>(
              stream: _usersRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('No users found.'));
                }


                final users = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final entries = users.entries.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final uid = entries[index].key;
                    final data = Map<String, dynamic>.from(entries[index].value);
                    return _buildUserTile(uid, data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
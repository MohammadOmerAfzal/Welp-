import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseReference _restaurantsRef = FirebaseDatabase.instance.ref().child('restaurants');

  LatLng? _selectedLocation;
  File? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _addRestaurant() async {
    if (_selectedLocation == null || _nameController.text.isEmpty || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide name, image, and location')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Save image locally with name.jpg
      final appDir = await getApplicationDocumentsDirectory();  // This is now correct
      final fileName = '${_nameController.text.replaceAll(' ', '_')}.jpg';
      final localImagePath = '${appDir.path}/$fileName';
      final localImage = await _pickedImage!.copy(localImagePath);

      final newRef = _restaurantsRef.push();
      await newRef.set({
        'name': _nameController.text,
        'imagePath': localImage.path, // This is the local image path
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });

      _nameController.clear();
      setState(() {
        _pickedImage = null;
        _selectedLocation = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant added successfully')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add restaurant: $e')),
      );
    }
  }


  Future<void> _deleteRestaurant(String key) async {
    await _restaurantsRef.child(key).remove();
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Restaurant Name'),
              ),
              const SizedBox(height: 10),
              _pickedImage != null
                  ? Image.file(_pickedImage!, height: 100)
                  : Text("No image selected"),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Pick Image'),
              ),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  onMapCreated: (_) {},
                  initialCameraPosition: CameraPosition(
                    target: LatLng(37.4219999, -122.0840575),
                    zoom: 14,
                  ),
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {
                    Marker(
                      markerId: MarkerId('selected'),
                      position: _selectedLocation!,
                    ),
                  }
                      : {},
                ),
              ),
              const SizedBox(height: 10),
              _isUploading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _addRestaurant,
                child: Text('Add Restaurant'),
              ),
              Divider(),
              StreamBuilder<DatabaseEvent>(
                stream: _restaurantsRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final restaurants = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
                  final list = restaurants.entries.toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final key = list[index].key;
                      final data = Map<String, dynamic>.from(list[index].value);

                      final imagePath = data['imagePath'];

                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(
                          'Lat: ${data['latitude']?.toStringAsFixed(4)}, Lng: ${data['longitude']?.toStringAsFixed(4)}',
                        ),
                        leading: imagePath != null && File(imagePath).existsSync()
                            ? Image.file(File(imagePath), width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image_not_supported),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteRestaurant(key),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

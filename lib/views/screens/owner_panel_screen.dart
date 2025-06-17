import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class OwnerPanelScreen extends StatefulWidget {
  @override
  _OwnerPanelScreenState createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseReference _businessRef = FirebaseDatabase.instance.ref().child(
      'businesses');

  List<File> _pickedImages = [];
  LatLng? _selectedLocation;
  String? _selectedCategory;
  bool _isUploading = false;
  GoogleMapController? _mapController;

  final List<String> _categories = [
    'Restaurant',
    'Salon',
    'Gym',
    'Store',
    'Other'
  ];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _pickedImages = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    final newLocation = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _selectedLocation = newLocation;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newLocation, 16),
    );
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _selectedLocation = pos;
    });
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dmf1xmi0v';
    const uploadPreset = 'flutter_unsigned';

    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);
      return data['secure_url'];
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _uploadBusiness() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedLocation == null ||
        _pickedImages.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final imageUrls = await Future.wait(_pickedImages.map((file) async {
        final url = await _uploadImageToCloudinary(file);
        if (url != null) return url;
        throw Exception("Failed to upload image");
      }));

      final newRef = _businessRef.push();
      await newRef.set({
        'id': newRef.key,
        'ownerid': user.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'images': imageUrls,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'location': 'Custom location',
        'averageRating': 0.0,
      });

      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _pickedImages.clear();
        _selectedLocation = null;
        _selectedCategory = null;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Business uploaded successfully')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
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
        title: Text('Owner Panel'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // SCROLLABLE INPUT AREA
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _pickedImages.isNotEmpty
                      ? SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _pickedImages
                          .map(
                            (img) =>
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.file(
                                img,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                      )
                          .toList(),
                    ),
                  )
                      : Text("No images selected"),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.image),
                    label: Text('Pick Images', style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: Icon(Icons.my_location),
                    label: Text('Use Current Location', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FIXED HEIGHT GOOGLE MAP
          Container(
            height: 350,
            width: 380,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.4219999, -122.0840575),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              markers: _selectedLocation != null
                  ? {
                Marker(
                  markerId: MarkerId('selected'),
                  position: _selectedLocation!,
                ),
              }
                  : {},
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),

          // BOTTOM BUTTON
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadBusiness,
              child: Text('Register Business',style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/business_model.dart';

class BusinessCard extends StatelessWidget {
  final Business business;

  const BusinessCard({Key? key, required this.business}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageWidget = business.imageBase64List.isNotEmpty
        ? Image.network(
      business.imageBase64List.first,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image),
      ),
    )
        : Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: imageWidget,
        title: Text(business.name),
        subtitle: Text(
          '${business.category} • ${business.description.length > 40 ? business.description.substring(0, 40) + '...' : business.description}',
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.pushNamed(context, '/business/${business.id}');
        },
      ),
    );
  }
}

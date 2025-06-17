import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  final List<Map<String, String>> team = [
    {
      'name': 'Moiz Islam',
      'email': 'islammoiz11@gmail.com',
      'github': 'https://github.com/Moizslam-1',
      'avatar': 'https://avatars.githubusercontent.com/u/193271295?v=4'
    },
    {
      'name': 'Mohammad Omar',
      'email': 'm.omarafzal12@gmail.com',
      'github': 'https://github.com/MohammadOmerAfzal',
      'avatar': 'https://avatars.githubusercontent.com/u/193082192?v=4'
    },
    {
      'name': 'Arslan Ijaz',
      'email': 'ijazarslan360@gmail.com',
      'github': 'https://github.com/arslan-112',
      'avatar': 'https://avatars.githubusercontent.com/u/76623349?v=4'
    },
    {
      'name': 'Ammar Tahir',
      'email': 'ammartahir444@gmail.com',
      'github': 'https://github.com/ammar-tahir012',
      'avatar': 'https://avatars.githubusercontent.com/u/193145631?v=4'
    },
  ];

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About Us')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: team.length,
              itemBuilder: (context, index) {
                final member = team[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(member['avatar']!),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(member['email']!, style: TextStyle(color: Colors.grey[700])),
                              GestureDetector(
                                onTap: () => _launchUrl(member['github']!),
                                child: Text(
                                  'GitHub Profile',
                                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Go to Home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

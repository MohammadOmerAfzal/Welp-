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
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: team.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final member = team[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFe3f2fd), Color(0xFFbbdefb)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.network(
                            member['avatar']!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name']!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                member['email']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _launchUrl(member['github']!),
                                child: Row(
                                  children: const [
                                    Icon(Icons.link, size: 16, color: Color(0xFF1E88E5)),
                                    SizedBox(width: 4),
                                    Text(
                                      'GitHub Profile',
                                      style: TextStyle(
                                        color: Color(0xFF1E88E5),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
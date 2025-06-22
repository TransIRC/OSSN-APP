import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder profile
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 50),
            ),
            SizedBox(height: 12),
            Text('Your Name', style: TextStyle(fontSize: 22)),
            SizedBox(height: 8),
            Text('Bio goes here...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
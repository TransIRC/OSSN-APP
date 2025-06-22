// lib/models/post.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  /// Factory constructor to create a Post from the JSON structure
  /// found in the /wall_list_home endpoint documentation.
  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      // Safely access the main 'post' and 'user' nested objects
      final postData = (json['post'] is Map) ? json['post'] : {};
      final userData = (json['user'] is Map) ? json['user'] : {};
      final iconData = (userData['icon'] is Map) ? userData['icon'] : {};

      // Safely extract the post content. The documentation shows the actual
      // text is in the top-level 'text' field.
      final postText = json['text']?.toString() ?? '';

      // The 'post.description' field contains JSON-encoded text, which is not ideal for display.
      // We will prefer the top-level 'text' field if it's available.
      String finalContent = postText;
      if (finalContent.isEmpty && postData['description'] != null) {
         // Fallback to the description field if 'text' is empty
         try {
           final decodedDesc = jsonDecode(postData['description']);
           if (decodedDesc is Map && decodedDesc['post'] != null) {
              finalContent = decodedDesc['post'];
           }
         } catch (e) {
            // If decoding fails, use the raw description string
            finalContent = postData['description'];
         }
      }

      // Safely extract user's full name
      final userName = userData['fullname']?.toString() ?? 'Unknown User';

      // Safely extract the user's avatar URL from the nested icon object
      final userAvatarUrl = iconData['small'] as String?;

      // Safely extract the post's image, if any
      final imageUrl = json['image'] as String?;

      // Safely parse the timestamp
      DateTime timestamp;
      final timeCreated = postData['time_created'];
      if (timeCreated is String && int.tryParse(timeCreated) != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(timeCreated) * 1000);
      } else if (timeCreated is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timeCreated * 1000);
      } else {
        timestamp = DateTime.now();
      }

      // Safely get the post ID
      final id = postData['guid']?.toString() ?? DateTime.now().toIso8601String();

      return Post(
        id: id,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        content: finalContent,
        imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error parsing post: $e \nJSON: $json');
      return Post(
        id: 'error-${DateTime.now().toIso8601String()}',
        userName: 'Parsing Error',
        content: 'Could not display this post due to a data error.',
        timestamp: DateTime.now(),
      );
    }
  }
}
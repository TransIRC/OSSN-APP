import 'package:flutter/material.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime timestamp;
  final bool isMine;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    this.userAvatarUrl,
    this.isMine = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // Extract user info if it's a nested map or use fallback values
      final user = json['user'] is Map ? json['user'] : {};
      final userId = user['guid']?.toString() ?? json['user_guid']?.toString() ?? '0';
      final userName = user['fullname']?.toString() ??
          json['user_name']?.toString() ??
          'Unknown User';
      final userAvatarUrl = user['icon'] is Map
          ? (user['icon']['small'] as String?)
          : null;

      // Extract comment content (try 'comment', then 'value', then fallback)
      final content = json['comment']?.toString() ??
          json['value']?.toString() ??
          '';

      // Parse timestamp (prefer int, fallback to string, fallback to now)
      DateTime timestamp;
      if (json['time_created'] != null) {
        if (json['time_created'] is String) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['time_created']) != null
                  ? int.parse(json['time_created']) * 1000
                  : DateTime.now().millisecondsSinceEpoch);
        } else if (json['time_created'] is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(
              json['time_created'] * 1000);
        } else {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }

      // Determine ownership (isMine)
      final isMine = json['is_liked_by_user'] == true ||
          json['is_owner'] == true ||
          json['is_owner'] == '1';

      return Comment(
        id: json['id']?.toString() ??
            json['guid']?.toString() ??
            DateTime.now().toIso8601String(),
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        content: content,
        timestamp: timestamp,
        isMine: isMine,
      );
    } catch (e) {
      debugPrint('Error parsing comment: $e \nJSON: $json');
      return Comment(
        id: 'error-${DateTime.now().toIso8601String()}',
        userId: '0',
        userName: 'Error',
        content: 'Could not load this comment',
        timestamp: DateTime.now(),
      );
    }
  }
}
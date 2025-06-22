// lib/widgets/post_card.dart

import 'package:flutter/material.dart';
// CORRECTED: Use a relative path for the Post model
import '../models/post.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkAvatar = post.userAvatarUrl != null &&
        post.userAvatarUrl!.startsWith('http');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      hasNetworkAvatar ? NetworkImage(post.userAvatarUrl!) : null,
                  child: !hasNetworkAvatar ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0073B1))),
                    Text(
                      DateFormat('MMM d, yyyy • hh:mm a').format(post.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 14)),
            if (post.imageUrl != null && post.imageUrl!.startsWith('http')) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(post.imageUrl!),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                _actionButton(icon: Icons.thumb_up_alt_outlined, label: 'Like'),
                const SizedBox(width: 24),
                _actionButton(icon: Icons.comment_outlined, label: 'Comment'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label}) {
    return TextButton.icon(
      icon: Icon(icon, size: 18, color: Colors.grey.shade700),
      label: Text(label, style: TextStyle(color: Colors.grey.shade700)),
      onPressed: () {},
    );
  }
}
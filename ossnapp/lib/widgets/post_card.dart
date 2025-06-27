import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostCard extends StatefulWidget {
  final Post post;
  final Map<String, dynamic>? authPayload; // Add this to get user info

  const PostCard({super.key, required this.post, this.authPayload});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likeCount;
  late bool isLiked;
  bool likeLoading = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likeCount ?? 0;
    isLiked = widget.post.isLikedByUser ?? false;
  }

  Future<void> _likePost() async {
    if (likeLoading) return;
    final auth = widget.authPayload;
    if (auth == null || auth['guid'] == null || auth['cookie'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in to like posts.")));
      return;
    }

    // Optimistically update UI before network request
    setState(() {
      likeLoading = true;
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      // Use correct endpoint for like and unlike
      final endpoint = isLiked ? 'like_add' : 'unlike_set';
      final url = Uri.parse('${AppConfig.apiUrl}/$endpoint');
      // Build the body based on action
      final body = {
        'subject_guid': widget.post.id,
        'type': 'post',
        'uguid': auth['guid'].toString(),
        'api_key_token': AppConfig.apiKey,
      };
      if (isLiked) {
        body['reaction_type'] = 'like'; // Only send for like_add
      }
      final response = await http.post(
        url,
        headers: {
          'Cookie': auth['cookie'],
        },
        body: body,
      );

      final contentType = response.headers['content-type'];
      if (response.statusCode == 200 &&
          contentType != null &&
          contentType.contains('application/json')) {
        final data = json.decode(response.body);
        if (data['count'] != null) {
          setState(() {
            likeCount = data['count'];
          });
        }
      } else {
        // If failed, revert the optimistic update
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to ${isLiked ? 'like' : 'unlike'} post.")),
        );
      }
    } catch (_) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to ${isLiked ? 'like' : 'unlike'} post.")),
      );
    } finally {
      setState(() {
        likeLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkAvatar = widget.post.userAvatarUrl != null &&
        widget.post.userAvatarUrl!.startsWith('http');

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
                      hasNetworkAvatar ? NetworkImage(widget.post.userAvatarUrl!) : null,
                  child: !hasNetworkAvatar ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0073B1))),
                    Text(
                      DateFormat('MMM d, yyyy • hh:mm a').format(widget.post.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.post.content, style: const TextStyle(fontSize: 14)),
            if (widget.post.imageUrl != null && widget.post.imageUrl!.startsWith('http')) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(widget.post.imageUrl!),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                _actionLikeButton(),
                const SizedBox(width: 24),
                _actionButton(icon: Icons.comment_outlined, label: 'Comment'),
                const Spacer(),
                if (likeCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_alt, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(likeCount.toString(), style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionLikeButton() {
    return TextButton.icon(
      icon: Icon(
        isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
        size: 18,
        color: isLiked ? Colors.blue : Colors.grey.shade700,
      ),
      label: Text(
        'Like',
        style: TextStyle(
          color: isLiked ? Colors.blue : Colors.grey.shade700,
          fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: likeLoading ? null : _likePost,
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return isLiked ? Colors.blue.withOpacity(0.15) : Colors.grey.withOpacity(0.15);
            }
            return null;
          },
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
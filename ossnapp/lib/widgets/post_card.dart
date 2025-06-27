import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/comment_section.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final Map<String, dynamic>? authPayload;

  const PostCard({super.key, required this.post, this.authPayload});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likeCount;
  late bool isLiked;
  bool likeLoading = false;

  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likeCount;
    isLiked = widget.post.isLikedByUser;
  }

  Future<void> _likePost() async {
    if (likeLoading) return;
    final auth = widget.authPayload;
    if (auth == null || auth['guid'] == null || auth['cookie'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in to like posts.")));
      return;
    }

    setState(() {
      likeLoading = true;
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      final endpoint = isLiked ? 'like_add' : 'unlike_set';
      final url = Uri.parse('${AppConfig.apiUrl}/$endpoint');
      final body = {
        'subject_guid': widget.post.id,
        'type': 'post',
        'uguid': auth['guid'].toString(),
        'api_key_token': AppConfig.apiKey,
      };
      if (isLiked) {
        body['reaction_type'] = 'like';
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

  void _refreshComments() {
    setState(() {});
  }

  Widget _actionRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4, top: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: likeLoading ? null : _likePost,
            child: Text(
              'Like',
              style: TextStyle(
                color: isLiked ? Colors.blue : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(_commentFocusNode);
            },
            child: Text(
              'Comment',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const Spacer(),
          if (likeCount > 0)
            Row(
              children: [
                const Icon(Icons.thumb_up_alt, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(likeCount.toString(), style: const TextStyle(color: Colors.blue, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkAvatar = widget.post.userAvatarUrl != null &&
        widget.post.userAvatarUrl!.startsWith('http');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: hasNetworkAvatar ? NetworkImage(widget.post.userAvatarUrl!) : null,
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
            Text(widget.post.content, style: const TextStyle(fontSize: 15)),
            if (widget.post.imageUrl != null && widget.post.imageUrl!.startsWith('http')) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(widget.post.imageUrl!),
              ),
            ],
            const SizedBox(height: 10),
            _actionRow(),
            const Divider(height: 24),
            if (widget.authPayload != null)
              CommentSection(
                postId: widget.post.id,
                authPayload: widget.authPayload!,
                onCommentAdded: _refreshComments,
                focusNode: _commentFocusNode,
              ),
          ],
        ),
      ),
    );
  }
}
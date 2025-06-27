import 'package:flutter/material.dart';
import '../models/comment.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentSection extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> authPayload;
  final VoidCallback onCommentAdded;
  final FocusNode? focusNode;

  const CommentSection({
    super.key,
    required this.postId,
    required this.authPayload,
    required this.onCommentAdded,
    this.focusNode,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Comment> _comments = [];
  bool _loadingComments = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _loadingComments = true;
      _error = null;
    });
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/api/comments');
      final response = await http.post(
        url,
        headers: {
          'Cookie': widget.authPayload['cookie'],
        },
        body: {
          'guid': widget.postId,
          'uguid': widget.authPayload['guid'].toString(),
          'type': 'post', // or 'entity' depending on post type
          'offset': '1',
          'page_limit': '20',
        },
      );
      // Debug: print API response if needed
      // print('Comments API Response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['comments'] is List) {
          setState(() {
            _comments = (data['comments'] as List)
                .map((c) => Comment.fromJson(c))
                .toList();
          });
        } else {
          setState(() {
            _comments = [];
          });
        }
      } else {
        setState(() {
          _error = 'Error loading comments (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading comments: $e';
      });
    }
    setState(() {
      _loadingComments = false;
    });
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('${AppConfig.apiUrl}/comment_add');
      final response = await http.post(
        url,
        headers: {
          'Cookie': widget.authPayload['cookie'],
        },
        body: {
          'api_key_token': AppConfig.apiKey,
          'subject_guid': widget.postId,
          'uguid': widget.authPayload['guid'].toString(),
          'comment': text,
          'type': 'post',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == '100') {
          _commentController.clear();
          widget.onCommentAdded();
          FocusScope.of(context).unfocus();
          _fetchComments();
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to add comment';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/comment_delete');
      final response = await http.post(
        url,
        headers: {
          'Cookie': widget.authPayload['cookie'],
        },
        body: {
          'api_key_token': AppConfig.apiKey,
          'guid': widget.authPayload['guid'].toString(),
          'id': commentId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == true) {
          widget.onCommentAdded();
          _fetchComments();
        } else {
          setState(() {
            _error = 'Failed to delete comment';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    }
  }

  Widget _buildCommentInput() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: widget.focusNode,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, size: 22, color: Colors.grey),
            onPressed: () {},
            splashRadius: 18,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, size: 22, color: Colors.grey),
            onPressed: () {},
            splashRadius: 18,
          ),
          if (_isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.send, size: 20, color: Colors.grey),
              onPressed: _addComment,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _buildCommentInput(),
        const SizedBox(height: 4),
        if (_loadingComments)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: CircularProgressIndicator(),
          )
        else
          ..._comments.map((comment) => _buildCommentItem(comment)),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final hasAvatar = comment.userAvatarUrl != null &&
        comment.userAvatarUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: hasAvatar
                ? NetworkImage(comment.userAvatarUrl!)
                : null,
            child: !hasAvatar
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.content),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: Text(
                    DateFormat('MMM d, yyyy • hh:mm a').format(comment.timestamp),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                if (comment.isMine)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Colors.grey),
                      onPressed: () {
                        _deleteComment(comment.id);
                      },
                      splashRadius: 16,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/post_card.dart';
import '../widgets/post_box.dart';
import '../models/feed_mode.dart';
import '../models/post.dart';
import '../config.dart';

class FeedScreen extends StatefulWidget {
  final Map<String, dynamic> authPayload;
  final FeedMode mode;

  const FeedScreen({
    super.key,
    required this.authPayload,
    this.mode = FeedMode.user,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWallPosts();
  }

  Future<void> _fetchWallPosts() async {
    final userGuid = widget.authPayload['guid'];
    final String? cookie = widget.authPayload['cookie'];

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Uri url;
      Map<String, String> body;

      if (widget.mode == FeedMode.community) {
        url = Uri.parse("${AppConfig.apiUrl}/wall_list_home");
        body = {
          "api_key_token": AppConfig.apiKey,
          "guid": userGuid.toString(),
          "offset": "1",
          "count": "10",
        };
      } else {
        url = Uri.parse("${AppConfig.apiUrl}/wall_list_user");
        body = {
          "api_key_token": AppConfig.apiKey,
          "uguid": userGuid.toString(),
          "guid": userGuid.toString(),
          "offset": "1",
          "count": "10",
        };
      }

      final Map<String, String> headers = {};
      if (cookie != null) {
        headers['Cookie'] = cookie;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains('application/json')) {
         final data = json.decode(response.body);
         final payload = data['payload'];

         if (payload != null && payload['posts'] is List) {
           final List<Post> fetchedPosts = (payload['posts'] as List)
               .map((postJson) => Post.fromJson(postJson))
               .toList();

           setState(() {
             _posts = fetchedPosts;
           });
         } else {
           setState(() {
              _posts = [];
           });
         }
      } else {
        _errorMessage = "A server error occurred. Please try again later.";
        debugPrint("Server Response (not JSON):\n${response.body}");
      }

    } catch (e) {
      _errorMessage = "An error occurred while fetching posts: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFeedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return ListView(
        children: [
          if (widget.mode != FeedMode.community)
            PostBox(
              authPayload: widget.authPayload,
              onPostSuccess: _fetchWallPosts,
            ),
          const SizedBox(height: 50),
          Center(
            child: Text(
              widget.mode == FeedMode.community
                  ? "No public posts found."
                  : "Your news feed is empty.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _posts.length + (widget.mode == FeedMode.community ? 0 : 1),
      itemBuilder: (context, index) {
        if (widget.mode != FeedMode.community && index == 0) {
          return PostBox(
            authPayload: widget.authPayload,
            onPostSuccess: _fetchWallPosts,
          );
        }
        final post = _posts[index - (widget.mode == FeedMode.community ? 0 : 1)];
        return PostCard(post: post, authPayload: widget.authPayload);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F4F4),
      child: _buildFeedContent(),
    );
  }
}
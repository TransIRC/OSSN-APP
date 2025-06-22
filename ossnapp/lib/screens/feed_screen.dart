// lib/screens/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/post_card.dart';
import '../widgets/post_box.dart';
import '../models/post.dart';
import '../config.dart';

class FeedScreen extends StatefulWidget {
  final Map<String, dynamic> authPayload;

  const FeedScreen({super.key, required this.authPayload});

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

    if (userGuid == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not fetch posts: User ID is missing.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse("${AppConfig.apiUrl}/wall_list_user");

      final Map<String, String> headers = {};
      if (cookie != null) {
        headers['Cookie'] = cookie;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: {
          "api_key_token": AppConfig.apiKey,
          "uguid": userGuid.toString(),
          "guid": userGuid.toString(),
          // CORRECTED: The API expects a 1-based offset for pagination.
          // Sending "1" for the first page will prevent the SQL error.
          "offset": "1",
          "count": "10",
        },
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
        children: const [
          PostBox(),
          SizedBox(height: 50),
          Center(child: Text("Your news feed is empty.", style: TextStyle(fontSize: 16, color: Colors.grey))),
        ],
      );
    }

    return ListView.builder(
      itemCount: _posts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const PostBox();
        }
        final post = _posts[index - 1];
        return PostCard(post: post);
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
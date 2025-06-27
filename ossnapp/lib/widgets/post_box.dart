import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostBox extends StatefulWidget {
  final Map<String, dynamic>? authPayload;
  final VoidCallback? onPostSuccess;

  const PostBox({super.key, this.authPayload, this.onPostSuccess});

  @override
  State<PostBox> createState() => _PostBoxState();
}

class _PostBoxState extends State<PostBox> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = "Post content cannot be empty.";
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final payload = widget.authPayload;
    if (payload == null || payload['guid'] == null || payload['cookie'] == null) {
      setState(() {
        _loading = false;
        _error = "User authentication error. Please log in again.";
      });
      return;
    }

    try {
      final url = Uri.parse('${AppConfig.apiUrl}/wall_add');
      final response = await http.post(
        url,
        headers: {
          'Cookie': payload['cookie'],
        },
        body: {
          'api_key_token': AppConfig.apiKey,
          'owner_guid': payload['guid'].toString(),
          'poster_guid': payload['guid'].toString(),
          'post': text,
          'privacy': '2', // friends
          'type': 'user',
        },
      );

      final contentType = response.headers['content-type'];
      if (response.statusCode == 200 &&
          contentType != null &&
          contentType.contains('application/json')) {
        final data = json.decode(response.body);
        if (data['code'] == "100") {
          _controller.clear();
          if (widget.onPostSuccess != null) widget.onPostSuccess!();
          setState(() {
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post submitted!')),
          );
        } else {
          setState(() {
            _error = data['message'] ?? 'Post failed. Try again.';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = "A server error occurred. Please try again later.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration.collapsed(
                hintText: "What's on your mind?",
              ),
              enabled: !_loading,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.image), onPressed: _loading ? null : () {}),
                IconButton(icon: const Icon(Icons.insert_emoticon), onPressed: _loading ? null : () {}),
                IconButton(icon: const Icon(Icons.privacy_tip), onPressed: _loading ? null : () {}),
                const Spacer(),
                ElevatedButton(
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                  onPressed: _loading ? null : _submitPost,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
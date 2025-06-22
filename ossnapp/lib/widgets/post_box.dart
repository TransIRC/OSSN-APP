import 'package:flutter/material.dart';

class PostBox extends StatelessWidget {
  const PostBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration.collapsed(
                hintText: "What's on your mind?",
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.image), onPressed: () {}),
                IconButton(icon: const Icon(Icons.insert_emoticon), onPressed: () {}),
                IconButton(icon: const Icon(Icons.privacy_tip), onPressed: () {}),
                const Spacer(),
                ElevatedButton(
                  child: const Text('Post'),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
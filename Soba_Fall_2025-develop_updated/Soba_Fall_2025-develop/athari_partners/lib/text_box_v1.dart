import 'package:flutter/material.dart';

class TextBoxV1 extends StatelessWidget {
  final String subtitle;
  final String details;

  const TextBoxV1({
    super.key,
    required this.subtitle,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          //TextField is the Widget that allows a user to enter text.
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: details,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

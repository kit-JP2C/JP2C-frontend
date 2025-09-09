import 'dart:typed_data';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> detectedObjects;

  const ResultPage({
    Key? key,
    required this.imageBytes,
    required this.detectedObjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      body: Column(
        children: [
          Image.memory(imageBytes),
          Expanded(
            child: ListView.builder(
              itemCount: detectedObjects.length,
              itemBuilder: (context, index) {
                final obj = detectedObjects[index];
                return ListTile(
                  title: Text(obj['label']),
                  subtitle: Text(
                    'Confidence: ${(obj['confidence'] * 100).toStringAsFixed(2)}%',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

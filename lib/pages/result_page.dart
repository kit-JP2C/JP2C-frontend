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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 크기 제한
            SizedBox(
              width: double.infinity,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            // 인식 결과 리스트
            ListView.builder(
              physics:
                  const NeverScrollableScrollPhysics(), // SingleChildScrollView 안에서 스크롤 충돌 방지
              shrinkWrap: true, // 내용 크기에 맞게 높이 제한
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
          ],
        ),
      ),
    );
  }
}

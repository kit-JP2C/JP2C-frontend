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

  // 한글 패 이름으로 변환
  String convertLabel(String label) {
    final Map<String, String> hanMap = {
      '1m': '1만',
      '2m': '2만',
      '3m': '3만',
      '4m': '4만',
      '5m': '5만',
      '6m': '6만',
      '7m': '7만',
      '8m': '8만',
      '9m': '9만',
      '1p': '1통',
      '2p': '2통',
      '3p': '3통',
      '4p': '4통',
      '5p': '5통',
      '6p': '6통',
      '7p': '7통',
      '8p': '8통',
      '9p': '9통',
      '1s': '1삭',
      '2s': '2삭',
      '3s': '3삭',
      '4s': '4삭',
      '5s': '5삭',
      '6s': '6삭',
      '7s': '7삭',
      '8s': '8삭',
      '9s': '9삭',
      '1z': '동',
      '2z': '남',
      '3z': '서',
      '4z': '북',
      '5z': '백',
      '6z': '발',
      '7z': '중',
      'back': '뒷면',
    };
    return hanMap[label] ?? label;
  }

  @override
  Widget build(BuildContext context) {
    // confidence threshold
    const double threshold = 0.01;

    // threshold 이상만 필터링
    final filteredObjects = detectedObjects
        .map((obj) => {
              'label': convertLabel(obj['label']),
              'confidence': obj['confidence'] as double,
            })
        .where((obj) => (obj['confidence'] as double) > threshold)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('인식 결과')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            SizedBox(
              width: double.infinity,
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            // 결과 리스트
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredObjects.length,
              itemBuilder: (context, index) {
                final obj = filteredObjects[index];
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

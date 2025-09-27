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

  // 라벨 변환 (영문 → 한글)
  String _translateLabel(String label) {
    final mapping = {
      'm': '만',
      'p': '통',
      's': '삭',
      'z': '자',
      'back': '뒷면',
    };

    if (label == 'back') return '뒷면';

    final number = label.substring(0, label.length - 1);
    final suit = label[label.length - 1];
    return "$number${mapping[suit] ?? suit}";
  }

  @override
  Widget build(BuildContext context) {
    // confidence 0.2 이상만 표시
    final filteredResults = detectedObjects
        .where((obj) => (obj['confidence'] as double) >= 0.01)
        .toList();

    // 라벨만 뽑아서 한 줄 문자열 생성
    final detectedLabels =
        filteredResults.map((obj) => _translateLabel(obj['label'])).join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Detection Results')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RotatedBox(
              quarterTurns: 3, // 왼쪽으로 90도 회전
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ 요약 텍스트 추가 위치
            if (detectedLabels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "인식 결과: $detectedLabels",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // ✅ 기존 리스트 (상세 결과)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                final obj = filteredResults[index];
                return ListTile(
                  title: Text(_translateLabel(obj['label'])),
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

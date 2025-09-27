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
    print("detectedObjects: $detectedObjects"); // 디버깅용

    return Scaffold(
      appBar: AppBar(title: const Text("Result")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.memory(imageBytes),
                // 박스 표시
                ...detectedObjects.map((obj) {
                  final rect =
                      obj['rect']; // Map with keys: left, top, width, height
                  final label = obj['label'] ?? 'Unknown';
                  final confidence = obj['confidence'] ?? 0.0;

                  if (rect == null) return Container();

                  return Positioned(
                    left: rect['left']?.toDouble() ?? 0,
                    top: rect['top']?.toDouble() ?? 0,
                    width: rect['width']?.toDouble() ?? 0,
                    height: rect['height']?.toDouble() ?? 0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.red.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            "$label ${(confidence * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),
            // 객체 리스트 텍스트
            detectedObjects.isEmpty
                ? const Text("인식된 객체가 없습니다.")
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detectedObjects.map((obj) {
                      final label = obj['label'] ?? 'Unknown';
                      final confidence = obj['confidence'] ?? 0.0;
                      return Text(
                        "$label - Confidence: ${confidence.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 16),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

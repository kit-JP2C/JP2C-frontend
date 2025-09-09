import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloService {
  static late Interpreter interpreter;

  static Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('model/color_float16.tflite');
  }

  static Future<List<Map<String, dynamic>>> detectObjects(
    Uint8List imageBytes,
  ) async {
    // 여기서 imageBytes 전처리 후 interpreter.run() 사용
    return [];
  }

  static Future<void> dispose() async {
    interpreter.close();
  }
}

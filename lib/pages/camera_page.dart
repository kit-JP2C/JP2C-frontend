import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mahjong_app/pages/result_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraPage({Key? key, required this.camera}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Uint8List? capturedImageBytes;
  List<Map<String, dynamic>> detectedObjects = [];

  Interpreter? _interpreter;

  bool _modelLoaded = false;
  bool _modelError = false;

  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);

    // 카메라 초기화 후 모델 + 라벨 로드
    _initializeControllerFuture = _controller.initialize().then((_) async {
      await _loadModel();
      await _loadLabels();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel({int retries = 0}) async {
    try {
      debugPrint("모델 로드 시도 ${retries + 1}: ${DateTime.now()}");
      _interpreter =
          await Interpreter.fromAsset("assets/model/color_float32.tflite");
      setState(() {
        _modelLoaded = true;
        _modelError = false;
      });
      debugPrint("✅ 모델 로드 완료: ${DateTime.now()}");
    } catch (e) {
      debugPrint("❌ 모델 로드 실패: $e");
      if (retries < 2) {
        await Future.delayed(const Duration(seconds: 1));
        _loadModel(retries: retries + 1);
      } else {
        setState(() {
          _modelError = true;
        });
      }
    }
  }

  Future<void> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString('assets/labels.txt');
      setState(() {
        labels = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();
      });
      debugPrint("✅ 라벨 로드 완료: ${labels.length}개");
    } catch (e) {
      debugPrint("❌ 라벨 로드 실패: $e");
    }
  }

  Future<void> _takePictureAndDetect() async {
    try {
      await _initializeControllerFuture;
      if (_interpreter == null) throw Exception("Interpreter not loaded");

      final XFile image = await _controller.takePicture();
      final bytes = await image.readAsBytes();
      final rawImg = img.decodeImage(bytes);
      if (rawImg == null) throw Exception("Failed to decode image");

      final inputShape = _interpreter!.getInputTensor(0).shape;
      debugPrint("Input Tensor Shape: $inputShape");
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      // 입력 이미지 리사이즈 및 정규화
      final resized =
          img.copyResize(rawImg, width: inputWidth, height: inputHeight);
      final rgba = resized.getBytes();

      final input = List.generate(
        1,
        (_) => List.generate(inputHeight, (y) {
          return List.generate(inputWidth, (x) {
            final idx = (y * inputWidth + x) * 4;
            final safeIdx = min(idx, rgba.length - 3);
            return [
              rgba[safeIdx].toDouble() / 255.0,
              rgba[safeIdx + 1].toDouble() / 255.0,
              rgba[safeIdx + 2].toDouble() / 255.0
            ];
          });
        }),
      );

      // 출력 버퍼 준비
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint("Output Tensor Shape: $outputShape");

      List<List<List<double>>> outputBuffer = List.generate(
        outputShape[0], // 1
        (_) => List.generate(
          outputShape[1], // 39
          (_) => List.filled(outputShape[2], 0.0), // 8400
        ),
      );

      try {
        _interpreter!.run(input, outputBuffer);
        debugPrint("Interpreter run successful");
      } catch (e) {
        debugPrint("Interpreter run failed: $e");
        Fluttertoast.showToast(
          msg: "Interpreter run error: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16,
        );
        return;
      }

      // 결과 처리
      final numDetections = outputShape[1];
      final numClasses = outputShape[2] - 5;

      List<Map<String, dynamic>> results = [];

      for (int i = 0; i < numDetections; i++) {
        final detection = outputBuffer[0][i];
        final conf = detection[4];
        if (conf < 0.01) continue; // threshold 낮춤

        final classScores = detection.sublist(5);
        final maxScore = classScores.reduce(max);
        final maxIdx = classScores.indexOf(maxScore);

        if (maxIdx >= labels.length) continue;

        // YOLO bbox는 보통 cx, cy, w, h 기준임 → 좌표 변환
        final cx = detection[0] * rawImg.width;
        final cy = detection[1] * rawImg.height;
        final w = detection[2] * rawImg.width;
        final h = detection[3] * rawImg.height;

        results.add({
          "rect": Rect.fromLTWH(cx - w / 2, cy - h / 2, w, h),
          "label": labels[maxIdx],
          "confidence": conf,
        });
      }

      results.sort((a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double));
      debugPrint("Detected objects count: ${results.length}");
      debugPrint("detectedObjects: $results");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            imageBytes: bytes,
            detectedObjects: results,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint("General error: $e\n$stack");
      Fluttertoast.showToast(
        msg: "촬영/인식 에러: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),

                /// 하단 버튼
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      onPressed: _modelLoaded ? _takePictureAndDetect : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _modelError
                            ? Colors.red
                            : (_modelLoaded ? Colors.green : Colors.grey),
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _modelError
                            ? const Text(
                                "모델 로드 실패",
                                key: ValueKey("error"),
                                style: TextStyle(fontSize: 18),
                              )
                            : (_modelLoaded
                                ? const Text(
                                    "촬영 & 인식",
                                    key: ValueKey("loaded"),
                                    style: TextStyle(fontSize: 18),
                                  )
                                : Row(
                                    key: const ValueKey("loading"),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "모델 로딩 중...",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  )),
                      ),
                    ),
                  ),
                ),

                /// 찍은 사진 미리보기
                if (capturedImageBytes != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(
                        capturedImageBytes!,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),

                /// 추론 결과
                if (detectedObjects.isNotEmpty)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: detectedObjects
                              .map(
                                (obj) => Text(
                                  "${obj['label']} ${(obj['confidence'] * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

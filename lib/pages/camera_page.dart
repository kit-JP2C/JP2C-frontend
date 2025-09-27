import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← 여기 추가
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mahjong_app/pages/result_page.dart';

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
  List<String> detectedObjects = [];

  Interpreter? _interpreter;

  bool _modelLoaded = false;
  bool _modelError = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);

    // 카메라 초기화 후 모델 로드
    _initializeControllerFuture = _controller.initialize().then((_) {
      _loadModel();
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

  dynamic _createNestedList(List<int> shape) {
    if (shape.length == 1) return List<double>.filled(shape[0], 0.0);
    return List.generate(shape[0], (_) => _createNestedList(shape.sublist(1)));
  }

  Future<void> _takePictureAndDetect() async {
    try {
      await _initializeControllerFuture;
      if (_interpreter == null) return;

      final XFile image = await _controller.takePicture();
      final bytes = await image.readAsBytes();

      // 이미지 디코딩
      final rawImg = img.decodeImage(bytes);
      if (rawImg == null) return;

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      final resized =
          img.copyResize(rawImg, width: inputWidth, height: inputHeight);
      final rgba = resized.getBytes();

      final input = List.generate(
        1,
        (_) => List.generate(inputHeight, (y) {
          return List.generate(inputWidth, (x) {
            final idx = (y * inputWidth + x) * 4;
            if (idx + 2 >= rgba.length) return [0.0, 0.0, 0.0];
            return [
              rgba[idx].toDouble() / 255.0,
              rgba[idx + 1].toDouble() / 255.0,
              rgba[idx + 2].toDouble() / 255.0
            ];
          });
        }),
      );

// ─── outputBuffer 3차원 생성 ─────────────────────────
      final outputShape =
          _interpreter!.getOutputTensor(0).shape; // [1, 39, 8400] 등
      final outputBuffer = List.generate(
        outputShape[0], // 1
        (_) => List.generate(
          outputShape[1], // 39
          (_) => List.generate(outputShape[2], (_) => 0.0), // 8400
        ),
      );
      _interpreter!.run(input, outputBuffer);

// ─── labels.txt 읽기 ─────────────────────────
      final labelsStr = await rootBundle.loadString('assets/model/labels.txt');
      final labels = labelsStr.split('\n');

// ─── top-K 결과 생성 (List<double> 처리) ─────────────
      List<Map<String, dynamic>> results = [];

      for (var i = 0; i < outputBuffer[0].length; i++) {
        final detection = outputBuffer[0][i]; // [x, y, w, h, conf, c1, c2, ...]
        final conf = detection[4] as double;
        if (conf < 0.3) continue; // confidence threshold (30% 이상만)

        final classScores = detection.sublist(5);
        final maxIdx = classScores.indexWhere(
            (s) => s == classScores.reduce((a, b) => a > b ? a : b));
        final label = labels[maxIdx];

        results.add({
          "rect": Rect.fromLTWH(
            detection[0],
            detection[1],
            detection[2],
            detection[3],
          ),
          "label": label,
          "confidence": conf,
        });
      }

// ─── confidence 순으로 정렬 ─────────────────────────
      results.sort((a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double));

      // ResultPage로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            imageBytes: bytes,
            //detectedObjects: results.take(14).toList(), // 상위 5개만
            detectedObjects: results,
          ),
        ),
      );
    } catch (e) {
      debugPrint("촬영/인식 에러: $e");
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
                                  obj,
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

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
      _interpreter = await Interpreter.fromAsset("model/gray_float32.tflite");
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

      setState(() {
        capturedImageBytes = bytes;
      });

      final rawImg = img.decodeImage(bytes);
      if (rawImg == null) return;

      // 모델 입력 크기
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      final resized = img.copyResize(
        rawImg,
        width: inputWidth,
        height: inputHeight,
      );

      // RGBA 바이트 배열
      final rgba = resized.getBytes();

      // 입력 텐서 생성 [1, h, w, 3]
      final input = List.generate(
        1,
        (_) => List.generate(inputHeight, (y) {
          return List.generate(inputWidth, (x) {
            final idx = (y * inputWidth + x) * 4;
            final r = rgba[idx].toDouble() / 255.0;
            final g = rgba[idx + 1].toDouble() / 255.0;
            final b = rgba[idx + 2].toDouble() / 255.0;
            return [r, g, b];
          });
        }),
      );

      // 출력 버퍼 생성
      final outputShape = _interpreter!.getOutputTensor(0).shape.toList();
      final outputBuffer = _createNestedList(outputShape);

      _interpreter!.run(input, outputBuffer);

      // 간단 출력 파싱
      List<String> results = [];
      try {
        if (outputBuffer is List && outputBuffer.isNotEmpty) {
          var first = outputBuffer[0];
          if (first is List) {
            for (int i = 0; i < first.length && i < 5; i++) {
              results.add("out[0][$i] => ${first[i].toString()}");
            }
          } else {
            for (int i = 0; i < (outputBuffer as List).length && i < 10; i++) {
              results.add("out[$i] = ${(outputBuffer as List)[i].toString()}");
            }
          }
        }
      } catch (e) {
        results.add('파싱 실패: $e');
      }

      setState(() {
        detectedObjects = results;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("촬영 및 추론 완료")));
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

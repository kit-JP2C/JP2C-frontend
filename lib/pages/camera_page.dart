import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  const CameraPage({Key? key, required this.camera}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Uint8List? capturedImageBytes; // 메모리에 저장된 이미지

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      // 사진 촬영
      final XFile image = await _controller.takePicture();

      // 메모리에 로드
      final bytes = await image.readAsBytes();

      setState(() {
        capturedImageBytes = bytes;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("사진이 메모리에 로드되었습니다.")));

      // 👉 여기서 bytes를 인식 서비스에 넘길 수 있음
      // MyService.processImage(bytes);
    } catch (e) {
      print("촬영 에러: $e");
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      onPressed: _takePicture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text("촬영"),
                    ),
                  ),
                ),
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

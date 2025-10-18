import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mahjong_app/utils/auth.dart';

class RoomCreatePage extends StatefulWidget {
  const RoomCreatePage({super.key});

  @override
  State<RoomCreatePage> createState() => _RoomCreatePageState();
}

class _RoomCreatePageState extends State<RoomCreatePage> {
  final _roomNameController = TextEditingController();
  late IO.Socket socket;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(
      'https://jp2c.org:443',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'accessToken': Auth.token})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print("✅ [DEBUG] Socket.IO 연결 성공 (방 생성 페이지)");
    });

    // ✅ 이벤트 수신 로깅
    socket.onAny((event, data) {
      print("📨 [DEBUG] 이벤트 수신: $event → $data");
    });

    // ✅ 실제 서버 이벤트
    socket.on('room-joined', (data) {
      print("🏠 [DEBUG] room-joined 수신: $data");
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ 방 참가 성공: ${data['roomName']}')),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/scoreboard', arguments: data);
      });
    });

    socket.onDisconnect((_) => print("🔌 [DEBUG] 소켓 연결 종료됨"));
    socket.connect();
  }

  void _createRoom() {
    final name = _roomNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('방 이름을 입력하세요')));
      return;
    }

    print("📤 [DEBUG] emit(join-room): $name");
    setState(() => _loading = true);

    socket.emit('join-room', {
      'roomName': name,
      'accessToken': Auth.token,
    });

    // ✅ 응답이 3초 안에 안 오면 타임아웃
    Future.delayed(const Duration(seconds: 3), () {
      if (_loading) {
        print("⏰ [DEBUG] join-room 응답 타임아웃");
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 응답이 없습니다.')),
        );
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("방 생성")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                labelText: "방 이름",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _createRoom,
                    child: const Text("방 만들기"),
                  ),
          ],
        ),
      ),
    );
  }
}

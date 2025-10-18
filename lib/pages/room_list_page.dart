import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mahjong_app/utils/auth.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  late IO.Socket socket;
  List<dynamic> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  /// ✅ Socket.IO 연결 및 이벤트 설정
  void _initSocket() {
    print("🔌 [DEBUG] Socket.IO 연결 시도... token=${Auth.token}");

    socket = IO.io(
      'https://jp2c.org',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'accessToken': Auth.token})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print("✅ [DEBUG] Socket.IO 연결 성공");
      //socket.emit('get-all-rooms', {'accessToken': Auth.token});
    });

    socket.onConnectError((err) {
      print("❌ [DEBUG] 연결 에러: $err");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("소켓 연결 실패: $err")));
    });

    socket.on('rooms', (data) {
      print("📨 [DEBUG] rooms 이벤트 수신: $data");
      setState(() {
        _rooms = List.from(data);
        _loading = false;
      });
    });

    socket.onDisconnect((_) => print("🔌 [DEBUG] 소켓 연결 종료됨"));
    socket.connect();
  }

  /// ✅ 서버에 방 목록 요청
  void _fetchRooms() {
    print("📤 [DEBUG] emit(get-all-rooms)");
    socket.emit('get-all-rooms');
  }

  /// ✅ 방 참가
  void _joinRoom(dynamic room) {
    print("📤 [DEBUG] emit(join-room): ${room['id']}");

    socket.emit('join-room', {
      'roomId': room['id'],
      'accessToken': Auth.token,
    });

    // ✅ 참가 성공 시 응답 처리
    socket.on('join-room-success', (data) {
      print("🏠 [DEBUG] join-room-success 수신: $data");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✅ 방 참가 성공: ${room['name']}')));
      Navigator.pushNamed(context, '/scoreboard', arguments: room);
    });
  }

  /// ✅ 방 생성 페이지 이동
  void _goToCreateRoom() {
    Navigator.pushNamed(context, '/create-room');
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("방 목록"),
        actions: [
          IconButton(
            onPressed: _fetchRooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? const Center(child: Text("현재 생성된 방이 없습니다."))
              : RefreshIndicator(
                  onRefresh: () async => _fetchRooms(),
                  child: ListView.builder(
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return ListTile(
                        title: Text(room['name'] ?? '이름 없음'),
                        subtitle: Text('ID: ${room['id']}'),
                        onTap: () => _joinRoom(room),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateRoom,
        label: const Text("방 만들기"),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

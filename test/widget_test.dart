import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MahjongScoreApp());
}

class MahjongScoreApp extends StatelessWidget {
  const MahjongScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: '마작 점수판', home: ScoreBoardPage());
  }
}

class ScoreBoardPage extends StatefulWidget {
  const ScoreBoardPage({super.key});

  @override
  State<ScoreBoardPage> createState() => _ScoreBoardPageState();
}

class _ScoreBoardPageState extends State<ScoreBoardPage> {
  late WebSocketChannel channel;
  List<Map<String, dynamic>> players = [
    {"name": "Player 1", "score": 25000},
    {"name": "Player 2", "score": 25000},
    {"name": "Player 3", "score": 25000},
    {"name": "Player 4", "score": 25000},
  ];

  @override
  void initState() {
    super.initState();

    // 실제 서버 주소/포트/방 ID 로 바꿔야 함
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/room/1234'),
    );

    // 서버에서 오는 메시지 수신
    channel.stream.listen((message) {
      try {
        final data = jsonDecode(message);

        // 서버 메시지 예시: {"player":"Player 1", "score":26000}
        setState(() {
          for (var p in players) {
            if (p["name"] == data["player"]) {
              p["score"] = data["score"];
            }
          }
        });
      } catch (e) {
        debugPrint("메시지 파싱 오류: $e");
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("마작 점수판")),
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final p = players[index];
          return Card(
            child: ListTile(
              title: Text(p["name"]),
              trailing: Text(
                "${p["score"]} 점",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

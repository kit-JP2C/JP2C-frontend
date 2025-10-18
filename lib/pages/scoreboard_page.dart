import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:camera/camera.dart';
import '../main.dart';
import 'package:mahjong_app/utils/auth.dart';

enum Seat { E, S, W, N }

extension on Seat {
  String get key => name;
}

class Player {
  final Seat seat;
  String name;
  int score;
  Player({required this.seat, required this.name, required this.score});
}

class ScoreChange {
  final Seat seat;
  final int before;
  final int after;
  ScoreChange({required this.seat, required this.before, required this.after});
}

class ScoreBoardPage extends StatefulWidget {
  const ScoreBoardPage({super.key});

  @override
  State<ScoreBoardPage> createState() => _ScoreBoardPageState();
}

class _ScoreBoardPageState extends State<ScoreBoardPage> {
  final Map<Seat, Player> players = {
    Seat.E: Player(seat: Seat.E, name: '플레이어1', score: 25000),
    Seat.S: Player(seat: Seat.S, name: '플레이어2', score: 25000),
    Seat.W: Player(seat: Seat.W, name: '플레이어3', score: 25000),
    Seat.N: Player(seat: Seat.N, name: '플레이어4', score: 25000),
  };

  String roundText = "동 1국";
  int honba = 0;
  int riichiSticks = 0;
  final List<ScoreChange> history = [];

  IO.Socket? socket;
  bool _socketInitialized = false; // ✅ 추가

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_socketInitialized) {
      final room = ModalRoute.of(context)!.settings.arguments as Map?;
      _initSocket(room);
      _socketInitialized = true;
    }
  }

  void _initSocket(Map? room) {
    final roomId = room?['id'] ?? 'unknown';
    print("🔌 [DEBUG] Socket.IO 연결 시도... room=$roomId, token=${Auth.token}");

    socket = IO.io(
      'https://jp2c.org',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'accessToken': Auth.token}) // ✅ 로그인 토큰 포함
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print("✅ [DEBUG] Socket.IO 연결 성공");
      // ✅ 서버 규칙에 맞게 join-room 이벤트 전송
      socket!.emit('join-room', {
        'roomId': roomId,
        'accessToken': Auth.token,
      });
    });

    socket!.on('room-joined', (data) {
      print("🏠 [DEBUG] room-joined 수신: $data");
    });

    socket!.on('players', (data) {
      print("📥 [DEBUG] players 이벤트 수신: $data");
      final m = Map<String, dynamic>.from(data);
      setState(() {
        for (final seat in Seat.values) {
          if (m[seat.key] != null) players[seat]!.name = m[seat.key];
        }
      });
    });

    socket!.on('score_update', (data) {
      print("📥 score_update 수신: $data");
      final seatKey = data['seat'];
      final score = data['score'];
      final seat = Seat.values.firstWhere((e) => e.key == seatKey);
      setState(() {
        players[seat]!.score = score;
      });
    });

    socket!.onDisconnect((_) => print("❌ Socket.IO 연결 해제됨"));
    socket!.onError((err) => print("⚠️ Socket.IO 에러: $err"));

    socket!.connect();
  }

  void _changeScore(Seat seat, int delta) {
    final p = players[seat]!;
    final before = p.score;
    final after = before + delta;

    setState(() {
      p.score = after;
      history.add(ScoreChange(seat: seat, before: before, after: after));
    });

    socket?.emit('score_update', {
      'seat': seat.key,
      'score': after,
    });
  }

  void _undo() {
    if (history.isEmpty) return;
    final last = history.removeLast();
    setState(() {
      players[last.seat]!.score = last.before;
    });
  }

  void _resetAll() {
    setState(() {
      for (var p in players.values) {
        p.score = 25000;
      }
      history.clear();
      honba = 0;
      riichiSticks = 0;
      roundText = "동 1국";
    });
  }

  @override
  void dispose() {
    print("📤 [DEBUG] emit(leave-room)");
    socket?.emit('leave-room', {'accessToken': Auth.token});
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ModalRoute.of(context)!.settings.arguments as Map?;
    final roomName = room?['name'] ?? '알 수 없는 방';

    return Scaffold(
      appBar: AppBar(title: Text(roomName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "점수판",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: _SideScoreCard(player: players[Seat.N]!),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _SideScoreCard(player: players[Seat.S]!),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: _SideScoreCard(player: players[Seat.W]!),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: _SideScoreCard(player: players[Seat.E]!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text("리치"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/camera');
                          },
                          child: const Text("쯔모오름"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text("방총"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text("유국"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _undo,
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetAll,
                          child: const Text("초기화"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideScoreCard extends StatelessWidget {
  final Player player;
  const _SideScoreCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            "${player.score} 점",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

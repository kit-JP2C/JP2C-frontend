import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MahjongApp());
}

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

class MahjongApp extends StatelessWidget {
  const MahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '리치 마작 점수판',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const ScoreBoardPage(),
    );
  }
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

  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    // TODO: 실제 서버 주소로 교체
    // channel = WebSocketChannel.connect(Uri.parse("ws://localhost:8080/room/1234"));
    // channel!.stream.listen((msg) => _onServerMessage(msg));
  }

  void _onServerMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'players') {
        final m = Map<String, dynamic>.from(data['players']);
        setState(() {
          for (final seat in Seat.values) {
            if (m[seat.key] != null) players[seat]!.name = m[seat.key];
          }
        });
      }
    } catch (_) {}
  }

  void _changeScore(Seat seat, int delta) {
    final p = players[seat]!;
    final before = p.score;
    final after = before + delta;
    setState(() {
      p.score = after;
      history.add(ScoreChange(seat: seat, before: before, after: after));
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$roundText / 본장 $honba / 리치봉 x$riichiSticks"),
      ),
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

            // 하단 버튼 영역
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {}, // 리치 동작 처리
                          child: const Text("리치"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {}, // 쯔모 동작 처리
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
                          onPressed: () {}, // 방총 처리
                          child: const Text("방총"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {}, // 유국 처리
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

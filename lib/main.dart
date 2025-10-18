import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/scoreboard_page.dart';
import 'pages/room_list_page.dart'; // ✅ 추가
import 'pages/room_create_page.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MahjongApp());
}

class MahjongApp extends StatelessWidget {
  const MahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '리치 마작 점수판',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),

      // ✅ 로그인 페이지부터 시작
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/rooms': (context) => const RoomListPage(),
        '/create-room': (context) => RoomCreatePage(), // ✅ const 제거, import 필수
        '/scoreboard': (context) => const ScoreBoardPage(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mahjong_app/utils/auth.dart'; // ✅ 절대경로 import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  Future<void> _login() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    if (id.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('아이디와 비밀번호를 입력하세요')));
      return;
    }

    try {
      final uri = Uri.parse('https://api.jp2c.org/v1/auth/login');
      print("🔵 [DEBUG] 로그인 요청: $uri");

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': id, 'password': pw}),
      );

      print("🟢 [DEBUG] 응답 코드: ${res.statusCode}");
      print("📨 [DEBUG] 응답 내용: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // ✅ 백엔드 응답 구조에 맞게 수정
        final token = data['accessToken'];

        Auth.token = token;

        print("🔐 [DEBUG] 토큰 저장 완료: ${Auth.token}");

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ 로그인 성공!')));
        Navigator.pushReplacementNamed(context, '/rooms');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 로그인 실패 (${res.statusCode})')),
        );
      }
    } catch (e) {
      print("💥 [DEBUG] 로그인 요청 실패: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('서버 연결 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: "아이디"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _login, child: const Text("로그인")),
          ],
        ),
      ),
    );
  }
}

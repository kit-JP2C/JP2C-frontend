import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwCheckController = TextEditingController();
  final _nicknameController = TextEditingController(); // ✅ 닉네임 필드 추가

  Future<void> _signup() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();
    final pwCheck = _pwCheckController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (id.isEmpty || pw.isEmpty || pwCheck.isEmpty || nickname.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('모든 필드를 입력하세요')));
      return;
    }

    if (pw != pwCheck) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다')));
      return;
    }

    try {
      final uri = Uri.parse('https://api.jp2c.org/v1/auth/register');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': id,
          'password': pw,
          'nickname': nickname, // ✅ 닉네임 전송
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ 회원가입 성공!')));
        Navigator.pop(context);
      } else {
        final errMsg = res.body.isNotEmpty ? res.body : '알 수 없는 오류';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 회원가입 실패 (${res.statusCode})\n$errMsg')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('서버 연결 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: "아이디"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: "닉네임"), // ✅ 추가됨
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwCheckController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호 확인"),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _signup,
                child: const Text("회원가입"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

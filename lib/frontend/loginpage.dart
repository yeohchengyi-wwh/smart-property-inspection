import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpropertyinspection/frontend/inspectionlistpage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();

  // 处理登录逻辑
  void _login() async {
    if (_usernameController.text.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // 1. 保存登录状态
      await prefs.setBool('isLoggedIn', true);
      // 2. 保存用户名 (题目要求 username only)
      await prefs.setString('username', _usernameController.text);

      // 3. 跳转到列表页，并移除当前的登录页路由（禁止返回）
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InspectionListScreen()),
        );
      }
    } else {
      // 简单的空值提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a username")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inspector Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.house_rounded, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Enter Username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // 按钮宽度填满
              ),
              child: const Text("LOGIN"),
            ),
          ],
        ),
      ),
    );
  }
}
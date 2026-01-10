import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpropertyinspection/frontend/loginpage.dart';
import 'package:smartpropertyinspection/frontend/inspectionlistpage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // 1. 获取 SharedPreferences 实例
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // 2. 人为延迟 2-3 秒，让用户能看到 Splash 画面 (模拟加载)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return; // 防止页面销毁后继续执行

    // 3. 根据登录状态跳转
    if (isLoggedIn) {
      // 如果已登录 -> 去主页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InspectionListScreen()),
      );
    } else {
      // 如果未登录 -> 去登录页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 设置背景色，通常白色看起来更干净
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/property-inspection.jpg', 
              width: 150, 
              height: 150,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.blue, // 统一主题色
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart Property Inspection', // App 名字
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Loading resources...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import 'app_routes.dart';

/// Màn hình Đăng nhập tài khoản người dùng.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      await AuthProvider.instance.login(
        userCtrl.text.trim(),
        passCtrl.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Đăng nhập'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.register);
              },
              child: const Text('Chưa có tài khoản? Đăng ký ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

// Alias tương thích
typedef LoginPage = LoginScreen;

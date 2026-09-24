import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

/// Màn hình đăng ký tài khoản mới cho người dùng.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = userCtrl.text.trim();
    final password = passCtrl.text;
    final email = emailCtrl.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên tài khoản!')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải có tối thiểu 8 ký tự!')),
      );
      return;
    }

    if (email.isNotEmpty) {
      final emailValid =
          email.contains('@') && email.endsWith('.com') && email.indexOf('@') > 0;
      if (!emailValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email không đúng định dạng (phải chứa @ và .com)!')),
        );
        return;
      }
    }

    setState(() => loading = true);
    try {
      await AuthProvider.instance.register(
        username,
        password,
        email.isEmpty ? null : email,
      );
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tạo tài khoản mới',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên tài khoản',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email (tùy chọn, phải chứa @ và .com)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu (tối thiểu 8 ký tự)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : _register,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng ký', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// Alias tương thích
typedef RegisterPage = RegisterScreen;

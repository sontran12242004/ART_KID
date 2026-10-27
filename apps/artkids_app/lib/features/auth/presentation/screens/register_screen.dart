import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_interceptor.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            email: email.text.trim(),
            password: password.text,
            displayName: name.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tạo tài khoản thành công. Hãy đăng nhập và thêm hồ sơ bé.',
            ),
          ),
        );
        context.go('/parent/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF9EE),
    appBar: AppBar(title: const Text('Đăng ký phụ huynh')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.palette, color: Colors.teal, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Cùng bé sáng tạo mỗi ngày',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên phụ huynh',
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v != null && v.contains('@')
                      ? null
                      : 'Email không hợp lệ',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu (ít nhất 10 ký tự)',
                  ),
                  validator: (v) => (v?.length ?? 0) < 10
                      ? 'Mật khẩu cần ít nhất 10 ký tự'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : register,
                  child: Text(busy ? 'Đang tạo tài khoản…' : 'Tạo tài khoản'),
                ),
                TextButton(
                  onPressed: () => context.go('/parent/login'),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

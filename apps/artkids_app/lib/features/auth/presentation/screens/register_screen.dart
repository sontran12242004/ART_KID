import '../../../../core/routing/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_interceptor.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';

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
  bool obscurePassword = true;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (busy) return;
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
        showAppSnackBar(
          context,
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
        showAppSnackBar(context, SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2F3F5), Color(0xFFF7FDFD), Colors.white],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 40).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: AppBackButton(),
                          ),
                          Center(
                            child: Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1687A7,
                                    ).withValues(alpha: 0.22),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/app_logo_3d.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Đăng Ký ArtKids',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F3B46),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tạo tài khoản phụ huynh để cùng bé\nkhám phá thế giới sáng tạo mỗi ngày.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4C6E76),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          AuthTextField(
                            controller: name,
                            hintText: 'Họ tên phụ huynh',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập họ tên'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: email,
                            hintText: 'Email',
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value != null && value.contains('@')
                                ? null
                                : 'Email không hợp lệ',
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: password,
                            hintText: 'Mật khẩu',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              tooltip: obscurePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: const Color(0xFF7E9DA3),
                                size: 22,
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 10
                                ? 'Mật khẩu cần ít nhất 10 ký tự'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Sử dụng mật khẩu có ít nhất 10 ký tự.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F828B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: const Color(0xFF1A52A8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: busy ? null : register,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (busy) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  busy
                                      ? 'Đang tạo tài khoản…'
                                      : 'Tạo tài khoản',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => context.go('/parent/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1687A7),
                            ),
                            child: const Text(
                              'Đã có tài khoản? Đăng nhập',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

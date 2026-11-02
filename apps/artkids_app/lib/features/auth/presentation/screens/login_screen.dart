import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/network/api_interceptor.dart';
import '../providers/auth_provider.dart';
import '../providers/intro_provider.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';

enum _IntroPhase { playing, transitioning, revealingForm, completed }

/// Màn hình Đăng Nhập Phụ Huynh kết hợp animation khởi động chuyển đổi logo liền mạch.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  _IntroPhase _phase = _IntroPhase.completed;
  VideoPlayerController? _videoController;
  Timer? _videoTimeoutTimer;
  bool _videoInitialized = false;

  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;
  Rect? _sourceRect;
  Rect? _targetRect;

  late final AnimationController _formController;
  late final Animation<double> _formFadeAnimation;
  late final Animation<double> _formSlideAnimation;

  final GlobalKey _targetLogoKey = GlobalKey();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Thời lượng di chuyển & đổi kích thước logo chính xác 800 ms
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.fastOutSlowIn,
    );

    // Thời lượng hiển thị dần các trường form đăng nhập 500 ms
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _formFadeAnimation = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    );
    _formSlideAnimation = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    final introPlayed = ref.read(introPlayedProvider);
    if (!introPlayed) {
      _phase = _IntroPhase.playing;
      _initVideo();
    } else {
      _phase = _IntroPhase.completed;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoTimeoutTimer?.cancel();
    _cleanUpVideo();
    _moveController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_phase == _IntroPhase.playing && _videoController != null) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _videoController?.pause();
      } else if (state == AppLifecycleState.resumed && _videoInitialized) {
        _videoController?.play();
      }
    }
  }

  Future<void> _initVideo() async {
    // Cover both loading failures and initialized videos blocked by autoplay.
    _videoTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _phase == _IntroPhase.playing) {
        _skipIntroDirectly();
      }
    });

    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/gemini_generated_video_8282401f.mp4',
      );
      _videoController = controller;

      await controller.initialize();
      if (!mounted ||
          _phase != _IntroPhase.playing ||
          _videoController != controller) {
        return;
      }

      _videoInitialized = true;
      setState(() {});

      await controller.setLooping(false);
      await controller.setVolume(0);
      if (!mounted ||
          _phase != _IntroPhase.playing ||
          _videoController != controller) {
        return;
      }
      controller.addListener(_videoListener);
      await controller.play();
    } catch (e) {
      debugPrint('[Intro] Lỗi khởi tạo video: $e');
      if (mounted) {
        _skipIntroDirectly();
      }
    }
  }

  void _videoListener() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.hasError) {
      _skipIntroDirectly();
      return;
    }

    final pos = controller.value.position;
    final dur = controller.value.duration;

    // Khi video đạt frame cuối (hoặc t >= 9.65s)
    if (pos >= dur - const Duration(milliseconds: 350) ||
        (!controller.value.isPlaying && pos >= const Duration(seconds: 9))) {
      controller.removeListener(_videoListener);
      controller.pause();
      _onVideoCompleted();
    } else {
      // Cập nhật màu nền theo tiến độ video (từ #063263 sang #FAF5E7)
      if (pos.inMilliseconds >= 7500 && pos.inMilliseconds <= 8700) {
        setState(() {});
      }
    }
  }

  void _onVideoCompleted() {
    if (!mounted || _phase != _IntroPhase.playing) return;
    _videoTimeoutTimer?.cancel();

    // Nếu người dùng đã có phiên đăng nhập hợp lệ: chuyển thẳng workspace
    final user = ref.read(authProvider).currentUser;
    if (user != null) {
      ref.read(introPlayedProvider.notifier).markPlayed();
      _cleanUpVideo();
      final target = user.role == 'parent' ? RoutePaths.parentHome : '/staff';
      context.go(target);
      return;
    }

    // Nếu hệ điều hành bật tính năng giảm chuyển động
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _skipIntroDirectly();
      return;
    }

    // Tính toạ độ chuyển cảnh chính xác theo video dọc và phần crop thực tế
    _calculateTransitionGeometry();

    setState(() {
      _phase = _IntroPhase.transitioning;
    });

    _moveController.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _phase = _IntroPhase.revealingForm;
      });
      _formController.forward().then((_) {
        if (!mounted) return;
        setState(() {
          _phase = _IntroPhase.completed;
        });
        ref.read(introPlayedProvider.notifier).markPlayed();
        _cleanUpVideo();
      });
    });
  }

  void _calculateTransitionGeometry() {
    final size = MediaQuery.of(context).size;
    final videoWidth = _videoController?.value.size.width ?? 720.0;
    final videoHeight = _videoController?.value.size.height ?? 1280.0;
    final videoAspect = videoWidth > 0 && videoHeight > 0
        ? videoWidth / videoHeight
        : (720.0 / 1280.0);
    final screenAspect = size.width / size.height;

    double scale;
    double displayW;
    double displayH;
    double offsetX;
    double offsetY;

    // Phủ toàn màn hình dọc (BoxFit.cover) giữ nguyên tỷ lệ, không kéo giãn:
    if (screenAspect < videoAspect) {
      // Màn hình dài/thon hơn 9:16 (chuẩn điện thoại hiện đại như 9:19.5, 9:20):
      // Video khớp theo chiều cao màn hình, căn giữa và chỉ crop phần dư tối thiểu 2 cạnh bên
      scale = size.height / videoHeight;
      displayH = size.height;
      displayW = videoWidth * scale;
      offsetY = 0.0;
      offsetX = (size.width - displayW) / 2.0;
    } else {
      // Màn hình rộng hơn 9:16 (máy tính bảng, màn hình gập):
      // Video khớp theo chiều rộng màn hình, căn giữa và crop phần dư trên/dưới
      scale = size.width / videoWidth;
      displayW = size.width;
      displayH = videoHeight * scale;
      offsetX = 0.0;
      offsetY = (size.height - displayH) / 2.0;
    }

    // Kết quả phân tích chính xác trên video dọc mới 720x1280 (Gemini generated):
    // Logo ổn định ở khung cuối với tâm tại (344.0, 642.0), đường kính 412 pixel.
    const logoVideoCenterX = 344.0;
    const logoVideoCenterY = 642.0;
    const logoVideoDiameter = 412.0;

    final sourceCenterX = offsetX + logoVideoCenterX * scale;
    final sourceCenterY = offsetY + logoVideoCenterY * scale;
    final sourceDiameter = logoVideoDiameter * scale;

    _sourceRect = Rect.fromCenter(
      center: Offset(sourceCenterX, sourceCenterY),
      width: sourceDiameter,
      height: sourceDiameter,
    );

    // Đo vị trí RenderBox thực tế của logo đích trên màn login
    final renderBox =
        _targetLogoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final origin = renderBox.localToGlobal(Offset.zero);
      _targetRect = origin & renderBox.size;
    } else {
      final topPadding = MediaQuery.of(context).padding.top;
      _targetRect = Rect.fromLTWH(
        (size.width - 165.0) / 2.0,
        topPadding + 20.0 + 18.0 + 6.0,
        165.0,
        165.0,
      );
    }
  }

  void _skipIntroDirectly() {
    _videoTimeoutTimer?.cancel();
    _cleanUpVideo();
    ref.read(introPlayedProvider.notifier).markPlayed();
    if (mounted) {
      setState(() {
        _phase = _IntroPhase.completed;
      });
    }
  }

  void _cleanUpVideo() {
    _videoController?.removeListener(_videoListener);
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  Color _getLetterboxColor() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Color(0xFF063263);
    }
    final ms = controller.value.position.inMilliseconds;
    if (ms < 7500) {
      return const Color(0xFF063263);
    } else if (ms > 8600) {
      return const Color(0xFFFAF5E7);
    } else {
      final t = (ms - 7500) / 1100.0;
      return Color.lerp(
        const Color(0xFF063263),
        const Color(0xFFFAF5E7),
        t.clamp(0.0, 1.0),
      )!;
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());
      if (mounted) {
        final user = ref.read(authProvider).currentUser;
        final target = user?.role == 'parent'
            ? RoutePaths.parentHome
            : '/staff';
        context.go(target);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          SnackBar(
            content: Text('Đăng nhập thất bại: ${apiError(e)}'),
            backgroundColor: const Color(0xFFE76F51),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Quên Mật Khẩu?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập email của bạn để nhận liên kết đặt lại mật khẩu:',
              style: TextStyle(fontSize: 14, color: Color(0xFF53767F)),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: resetEmailController,
              hintText: 'Email của bạn',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1687A7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                showAppSnackBar(
                  context,
                  const SnackBar(
                    content: Text('Vui lòng nhập email hợp lệ'),
                    backgroundColor: Color(0xFFE76F51),
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              showAppSnackBar(
                context,
                SnackBar(
                  content: Text(
                    'Đã gửi liên kết đặt lại mật khẩu tới $email. Vui lòng kiểm tra hộp thư.',
                  ),
                  backgroundColor: const Color(0xFF2A9D8F),
                ),
              );
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _IntroPhase.completed) {
      return _buildLoginForm(isInteractive: true);
    }

    return Scaffold(
      backgroundColor: _phase == _IntroPhase.playing
          ? _getLetterboxColor()
          : const Color(0xFFFAF5E7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Lớp nền màn login (vẫn đo được RenderBox nhưng tạm ẩn trong khi video phát)
          IgnorePointer(
            ignoring: _phase != _IntroPhase.completed,
            child: Opacity(
              opacity: _phase == _IntroPhase.playing ? 0.0 : 1.0,
              child: _buildLoginForm(isInteractive: false),
            ),
          ),

          // Lớp phát Video Intro dọc phủ toàn màn hình (BoxFit.cover)
          if (_phase == _IntroPhase.playing)
            Positioned.fill(
              child: Container(
                color: _getLetterboxColor(),
                child: _videoController != null && _videoInitialized
                    ? ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController!.value.size.width > 0
                                ? _videoController!.value.size.width
                                : 720.0,
                            height: _videoController!.value.size.height > 0
                                ? _videoController!.value.size.height
                                : 1280.0,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      )
                    : Container(color: const Color(0xFF063263)),
              ),
            ),

          // Lớp chuyển động Logo từ Video sang Login Screen
          if (_phase == _IntroPhase.playing)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: FilledButton.tonalIcon(
                onPressed: _skipIntroDirectly,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Bỏ qua'),
              ),
            ),

          if (_phase == _IntroPhase.transitioning &&
              _sourceRect != null &&
              _targetRect != null)
            AnimatedBuilder(
              animation: _moveAnimation,
              builder: (context, _) {
                final currentRect = Rect.lerp(
                  _sourceRect!,
                  _targetRect!,
                  _moveAnimation.value,
                )!;
                final progress = _moveAnimation.value;

                return Stack(
                  children: [
                    // Nền chuyển mờ từ #FAF5E7 sang nền trong suốt để lộ gradient màn login
                    Positioned.fill(
                      child: Container(
                        color: const Color(
                          0xFFFAF5E7,
                        ).withValues(alpha: (1.0 - progress).clamp(0.0, 1.0)),
                      ),
                    ),

                    // Logo 3D đang lướt và thu phóng về vị trí đích
                    Positioned.fromRect(
                      rect: currentRect,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1687A7,
                              ).withValues(alpha: 0.22 * progress),
                              blurRadius: 24 * progress,
                              offset: Offset(0, 10 * progress),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/app_logo_3d.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm({required bool isInteractive}) {
    final showLogoOnForm =
        _phase == _IntroPhase.revealingForm || _phase == _IntroPhase.completed;
    final showElements =
        _phase == _IntroPhase.revealingForm || _phase == _IntroPhase.completed;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2F3F5), Color(0xFFF7FDFD), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),

                  // Logo ArtKids 3D hình tròn ở trung tâm
                  Center(
                    child: Opacity(
                      opacity: showLogoOnForm ? 1.0 : 0.0,
                      child: Container(
                        key: _targetLogoKey,
                        width: 165,
                        height: 165,
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
                  ),

                  const SizedBox(height: 22),

                  // Toàn bộ phần form đăng nhập xuất hiện với hiệu ứng trượt nhẹ và mờ dần
                  if (_phase == _IntroPhase.revealingForm)
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formSlideAnimation.value),
                          child: Opacity(
                            opacity: _formFadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildFormFieldsAndButtons(),
                    )
                  else if (showElements)
                    _buildFormFieldsAndButtons()
                  else
                    // Giữ kích thước khung hình layout
                    Opacity(opacity: 0.0, child: _buildFormFieldsAndButtons()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFieldsAndButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tiêu đề
        const Text(
          'Đăng Nhập ArtKids',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F3B46),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),

        // Mô tả phụ
        const Text(
          'Khám phá thế giới sáng tạo và đồng hành cùng bé',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4C6E76),
            height: 1.35,
          ),
        ),

        const SizedBox(height: 28),

        // Ô nhập Email
        AuthTextField(
          controller: _emailController,
          hintText: 'Email',
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!val.contains('@')) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Ô nhập Mật khẩu
        AuthTextField(
          controller: _passwordController,
          hintText: 'Mật khẩu',
          prefixIcon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: const Color(0xFF7E9DA3),
              size: 22,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (val.length < 6) {
              return 'Mật khẩu tối thiểu 6 ký tự';
            }
            return null;
          },
        ),

        const SizedBox(height: 10),

        // Quên mật khẩu?
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              foregroundColor: const Color(0xFF5F828B),
            ),
            onPressed: _showForgotPasswordDialog,
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Nút Đăng Nhập
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A52A8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              shadowColor: Colors.transparent,
            ),
            onPressed: _isLoading ? null : _submitLogin,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A52A8).withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đăng Nhập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Hàng dẫn tới Đăng ký tài khoản
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chưa có tài khoản? ',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF556E74),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(RoutePaths.parentRegister),
              child: const Text(
                'Tạo tài khoản ngay',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1687A7),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF1687A7),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

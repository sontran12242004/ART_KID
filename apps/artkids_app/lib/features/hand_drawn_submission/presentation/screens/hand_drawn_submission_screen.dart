import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/kid_button.dart';
import '../../../drawing_canvas/presentation/widgets/parental_consent_dialog.dart';

class HandDrawnSubmissionScreen extends StatefulWidget {
  const HandDrawnSubmissionScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<HandDrawnSubmissionScreen> createState() =>
      _HandDrawnSubmissionScreenState();
}

class _HandDrawnSubmissionScreenState extends State<HandDrawnSubmissionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _capturedImage;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  Future<void> _captureImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() => _capturedImage = image);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở máy ảnh: $error')));
    }
  }

  Future<void> _submitForTeacherReview() async {
    final image = _capturedImage;
    if (image == null || _isSubmitting) return;

    final consentGranted = await ParentalConsentDialog.show(context);
    if (!mounted || consentGranted != true) return;

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSubmittedView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: AppBar(
        title: const Text(
          'Nộp Bài Vẽ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bé hãy vẽ trên giấy thật nhé! ✏️',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F3B46),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi vẽ xong, chụp rõ toàn bộ bức tranh để gửi cho cô giáo xem.',
                style: TextStyle(fontSize: 16, color: Color(0xFF4C6E76)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _capturedImage == null
                    ? _buildCameraPrompt()
                    : _buildPreview(),
              ),
              const SizedBox(height: 16),
              if (_capturedImage == null)
                KidButton(
                  label: 'Chụp bài vẽ 📷',
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFFFF6B6B),
                  onPressed: _captureImage,
                )
              else ...[
                KidButton(
                  label: 'Gửi cô giáo xem bài 🎨',
                  icon: Icons.send_rounded,
                  color: const Color(0xFF1687A7),
                  onPressed: _isSubmitting ? () {} : _submitForTeacherReview,
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _capturedImage = null),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Chụp lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPrompt() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6D6), width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_back_rounded,
              size: 72,
              color: Color(0xFFFF6B6B),
            ),
            SizedBox(height: 16),
            Text(
              'Đặt tranh ngay ngắn trong khung hình',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F3B46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Colors.black,
        child: Image.file(
          File(_capturedImage!.path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text(
              'Không thể xem ảnh vừa chụp.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 96,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đã gửi bài vẽ rồi! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F3B46),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bài vẽ đang chờ cô giáo xem. Bé làm tốt lắm!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Color(0xFF4C6E76)),
                ),
                const SizedBox(height: 32),
                KidButton(
                  label: 'Quay lại',
                  icon: Icons.arrow_back_rounded,
                  color: const Color(0xFF1687A7),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

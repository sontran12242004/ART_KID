import 'package:flutter/material.dart';

/// Hộp thoại xác nhận của phụ huynh (COPPA / GDPR-K Gate)
/// Đảm bảo phụ huynh đồng ý trước khi ảnh vẽ được tải lên pipeline AI.
class ParentalConsentDialog extends StatefulWidget {
  const ParentalConsentDialog({
    super.key,
    required this.onConsentGranted,
  });

  final VoidCallback onConsentGranted;

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ParentalConsentDialog(
        onConsentGranted: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  State<ParentalConsentDialog> createState() => _ParentalConsentDialogState();
}

class _ParentalConsentDialogState extends State<ParentalConsentDialog> {
  // Simple math challenge to ensure it's a parent / adult
  late int _num1;
  late int _num2;
  final _answerController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _num1 = 7 + (DateTime.now().millisecond % 5);
    _num2 = 6 + (DateTime.now().second % 4);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _verify() {
    final expected = _num1 * _num2;
    final entered = int.tryParse(_answerController.text.trim());

    if (entered == expected) {
      widget.onConsentGranted();
    } else {
      setState(() {
        _error = 'Kết quả chưa đúng. Vui lòng thử lại!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.family_restroom, color: Color(0xFFFF6B6B), size: 28),
          SizedBox(width: 8),
          Text('Xác nhận của Phụ huynh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để bảo vệ quyền riêng tư của trẻ (tuân thủ COPPA/GDPR-K), '
              'vui lòng giải phép tính dưới đây để xác nhận gửi bài vẽ lên hệ thống AI tạo hình con vật:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Center(
                child: Text(
                  '$_num1 × $_num2 = ?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nhập kết quả',
                errorText: _error,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _verify(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Đồng ý & Gửi AI'),
        ),
      ],
    );
  }
}

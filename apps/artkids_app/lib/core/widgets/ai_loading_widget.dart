import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Loading vui mắt trong lúc chờ AI xử lý con vật
class AiLoadingWidget extends StatelessWidget {
  const AiLoadingWidget({super.key, this.message = 'Đang tạo con vật...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: thay bằng Lottie asset thật tại assets/animations/ai_loading.json
          SizedBox(
            width: 160,
            height: 160,
            child: Lottie.asset(
              'assets/animations/ai_loading.json',
              errorBuilder: (_, __, ___) => const CircularProgressIndicator(strokeWidth: 6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

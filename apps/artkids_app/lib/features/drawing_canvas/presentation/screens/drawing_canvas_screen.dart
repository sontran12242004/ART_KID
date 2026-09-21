import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ai_loading_widget.dart';
import '../../../../core/widgets/kid_button.dart';
import '../../../ai_creature/presentation/providers/creature_generation_provider.dart';
import '../widgets/canvas_board.dart';
import '../widgets/color_picker_toolbar.dart';
import '../widgets/parental_consent_dialog.dart';

class DrawingCanvasScreen extends ConsumerStatefulWidget {
  const DrawingCanvasScreen({
    super.key,
    required this.lessonId,
  });

  final String lessonId;

  @override
  ConsumerState<DrawingCanvasScreen> createState() => _DrawingCanvasScreenState();
}

class _DrawingCanvasScreenState extends ConsumerState<DrawingCanvasScreen> {
  Color _selectedColor = const Color(0xFFFF6B6B);
  double _strokeWidth = 6.0;
  final GlobalKey<CanvasBoardState> _canvasKey = GlobalKey<CanvasBoardState>();

  void _handleSubmit() {
    // Kiểm tra canvas có nét vẽ không
    final canvasState = _canvasKey.currentState;
    if (canvasState == null || !canvasState.hasStrokes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bé ơi, vẽ con vật vào khung tranh trước nhé! 🎨'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Hiển thị Parental Consent Gate tuân thủ COPPA trước khi cho phép gửi tranh lên AI
    showDialog(
      context: context,
      builder: (dialogContext) => ParentalConsentDialog(
        onConsentGranted: () async {
          Navigator.of(dialogContext).pop(); // Đóng dialog trước khi submit
          await _submitToAi();
        },
      ),
    );
  }

  Future<void> _submitToAi() async {
    final canvasState = _canvasKey.currentState;
    if (canvasState == null) return;

    // Export canvas sang PNG bytes
    final pngBytes = await canvasState.exportToPng();
    if (pngBytes == null || pngBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chụp bức tranh. Bé thử lại nhé!'),
          ),
        );
      }
      return;
    }

    // Gọi Gemini AI phân tích ảnh vẽ
    final notifier = ref.read(creatureGenProvider.notifier);
    final result = await notifier.analyzeAndGenerate(pngBytes);

    if (!mounted) return;

    if (result != null) {
      // AI nhận diện thành công → navigate tới màn hình xem con vật 3D
      // Truyền GeminiAnalysisResult qua GoRouter extra
      context.push('/kid/creature/ai-generated', extra: result);
    } else {
      // Lỗi → hiển thị thông báo
      final errorState = ref.read(creatureGenProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorState.errorMessage ?? 'AI chưa nhận ra con vật. Thử lại nhé!',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleUndo() {
    _canvasKey.currentState?.undo();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã hoàn tác nét vẽ vừa rồi'),
        duration: Duration(milliseconds: 600),
      ),
    );
  }

  void _handleClear() {
    _canvasKey.currentState?.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã làm sạch khung tranh'),
        duration: Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genState = ref.watch(creatureGenProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: AppBar(
        title: const Text(
          'Bảng Vẽ Sáng Tạo 🎨',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 30),
            tooltip: 'Hoàn tác nét vẽ',
            onPressed: _handleUndo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 30),
            tooltip: 'Xóa toàn bộ tranh',
            onPressed: _handleClear,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Bảng vẽ canvas
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CanvasBoard(
                    key: _canvasKey,
                    lessonId: widget.lessonId,
                    strokeColor: _selectedColor,
                    strokeWidth: _strokeWidth,
                  ),
                ),
              ),

              // Thanh chọn màu vẽ thân thiện với trẻ em (nút tròn to > 48dp)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ColorPickerToolbar(
                  selectedColor: _selectedColor,
                  selectedStrokeWidth: _strokeWidth,
                  onColorChanged: (color) => setState(() => _selectedColor = color),
                  onStrokeWidthChanged: (width) => setState(() => _strokeWidth = width),
                ),
              ),

              // Nút gửi tranh cho AI
              Padding(
                padding: const EdgeInsets.all(16),
                child: KidButton(
                  label: 'Gửi AI Hô Biến Con Vật! 🪄',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFFFF6B6B),
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),

          // Loading overlay khi AI đang phân loại nét vẽ & khớp animation
          if (genState.isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: AiLoadingWidget(
                  message: genState.status == CreatureGenStatus.analyzing
                      ? 'AI đang ngắm nét vẽ của bé để nhận diện con vật...'
                      : 'Đang hô biến con vật 3D nhé... ✨',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

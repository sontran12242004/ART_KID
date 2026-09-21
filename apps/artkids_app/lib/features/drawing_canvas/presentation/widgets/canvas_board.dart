import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Canvas vẽ tay — tích hợp flutter_painter (placeholder CustomPainter)
///
/// Hỗ trợ export canvas sang PNG bytes qua GlobalKey + RenderRepaintBoundary.
class CanvasBoard extends StatefulWidget {
  const CanvasBoard({
    super.key,
    required this.lessonId,
    this.strokeColor = Colors.black,
    this.strokeWidth = 4.0,
  });

  final String lessonId;
  final Color strokeColor;
  final double strokeWidth;

  @override
  State<CanvasBoard> createState() => CanvasBoardState();
}

class CanvasBoardState extends State<CanvasBoard> {
  final List<_StrokePoint> _points = [];
  final GlobalKey _repaintKey = GlobalKey();

  /// Export nội dung canvas thành PNG bytes (Uint8List).
  ///
  /// Trả về null nếu canvas rỗng hoặc không thể export.
  Future<Uint8List?> exportToPng({double pixelRatio = 3.0}) async {
    if (_points.isEmpty) return null;

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('CanvasBoard.exportToPng error: $e');
      return null;
    }
  }

  /// Xóa toàn bộ nét vẽ trên canvas
  void clear() {
    setState(() => _points.clear());
  }

  /// Hoàn tác nét vẽ cuối cùng (undo)
  void undo() {
    if (_points.isEmpty) return;
    setState(() {
      // Xóa ngược từ cuối cho đến khi gặp separator hoặc hết danh sách
      while (_points.isNotEmpty && !_points.last.isSeparator) {
        _points.removeLast();
      }
      // Xóa separator
      if (_points.isNotEmpty && _points.last.isSeparator) {
        _points.removeLast();
      }
    });
  }

  /// Kiểm tra canvas có nét vẽ không
  bool get hasStrokes => _points.any((p) => !p.isSeparator);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: RepaintBoundary(
          key: _repaintKey,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() => _points.add(_StrokePoint(
                    offset: details.localPosition,
                    color: widget.strokeColor,
                    width: widget.strokeWidth,
                  )));
            },
            onPanEnd: (_) => _points.add(_StrokePoint.separator()),
            child: CustomPaint(
              painter: _DrawingPainter(_points),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mỗi điểm lưu lại color + width tại thời điểm vẽ
class _StrokePoint {
  const _StrokePoint({this.offset, required this.color, required this.width});

  /// Separator (ngắt nét) khi offset == null
  const _StrokePoint.separator()
      : offset = null,
        color = Colors.black,
        width = 0;

  final Offset? offset;
  final Color color;
  final double width;

  bool get isSeparator => offset == null;
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.points);
  final List<_StrokePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ nền trắng để export PNG có background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (!current.isSeparator && !next.isSeparator) {
        final paint = Paint()
          ..color = current.color
          ..strokeWidth = current.width
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(current.offset!, next.offset!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

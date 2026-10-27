import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

/// Một nét vẽ gồm danh sách tọa độ điểm, màu sắc và độ dày nét
class DrawnStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const DrawnStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

/// Bảng vẽ ngón tay tự do cho trẻ nhỏ với CustomPainter + GestureDetector
class DrawingCanvas extends StatefulWidget {
  /// Callback khi bé bấm nút "Xong"
  final VoidCallback onFinish;
  final VoidCallback? onChanged;
  final bool showActions;

  const DrawingCanvas({
    super.key,
    required this.onFinish,
    this.onChanged,
    this.showActions = true,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final _captureKey = GlobalKey();
  Future<Uint8List> exportPng() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  final List<DrawnStroke> _strokes = [];
  List<Offset> _currentStrokePoints = [];
  Size? _drawingSize;

  // Keep a stable coordinate space when the window or orientation changes.
  Offset _drawingPoint(Offset position) {
    final box = _captureKey.currentContext!.findRenderObject() as RenderBox;
    _drawingSize ??= box.size;
    return Offset(
      position.dx * _drawingSize!.width / box.size.width,
      position.dy * _drawingSize!.height / box.size.height,
    );
  }

  // Bảng màu thân thiện, rực rỡ dành cho trẻ em
  static const List<Color> _palette = [
    Color(0xFF264653), // Xanh đen đậm
    Color(0xFFE76F51), // Cam san hô
    Color(0xFFF4A261), // Vàng mật ong
    Color(0xFF2A9D8F), // Xanh ngọc
    Color(0xFFE63946), // Đỏ rực
    Color(0xFF9D4EDD), // Tím mộng mơ
  ];

  Color _selectedColor = const Color(0xFFE76F51);
  final double _selectedStrokeWidth = 7.0;

  /// Kiểm tra xem bé đã vẽ nét nào chưa
  bool get hasDrawn => _strokes.isNotEmpty || _currentStrokePoints.isNotEmpty;

  /// Xóa toàn bộ nét vẽ hiện tại
  void clear() {
    setState(() {
      _strokes.clear();
      _currentStrokePoints = [];
    });
    widget.onChanged?.call();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onChanged?.call();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStrokePoints = [_drawingPoint(details.localPosition)];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStrokePoints = List.from(_currentStrokePoints)
        ..add(_drawingPoint(details.localPosition));
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStrokePoints.isNotEmpty) {
      setState(() {
        _strokes.add(
          DrawnStroke(
            points: List.from(_currentStrokePoints),
            color: _selectedColor,
            strokeWidth: _selectedStrokeWidth,
          ),
        );
        _currentStrokePoints = [];
      });
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Vùng giấy vẽ cảm ứng
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFD166), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: GestureDetector(
                onTapUp: (details) {
                  setState(
                    () => _strokes.add(
                      DrawnStroke(
                        points: [_drawingPoint(details.localPosition)],
                        color: _selectedColor,
                        strokeWidth: _selectedStrokeWidth,
                      ),
                    ),
                  );
                  widget.onChanged?.call();
                },
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: () => _onPanEnd(DragEndDetails()),
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Semantics(
                    label: 'Giấy vẽ',
                    image: true,
                    child: ColoredBox(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _FreehandPainter(
                          strokes: _strokes,
                          currentPoints: _currentStrokePoints,
                          currentColor: _selectedColor,
                          currentStrokeWidth: _selectedStrokeWidth,
                          drawingSize: _drawingSize,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Thanh chọn màu sắc và bút vẽ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _palette.map((color) {
              final isSelected = _selectedColor == color;
              return Semantics(
                button: true,
                selected: isSelected,
                label: [
                  'Màu xanh đậm',
                  'Màu cam',
                  'Màu vàng',
                  'Màu xanh ngọc',
                  'Màu đỏ',
                  'Màu tím',
                ][_palette.indexOf(color)],
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 42 : 34,
                    height: isSelected ? 42 : 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Hàng nút hành động: "Xóa vẽ lại" và "Xong"
        if (widget.showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                // Nút Xóa vẽ lại
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE76F51),
                        side: const BorderSide(
                          color: Color(0xFFE76F51),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      label: const Text(
                        'Xóa vẽ lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed:
                          _strokes.isEmpty && _currentStrokePoints.isEmpty
                          ? null
                          : clear,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Nút Xong to bản, nổi bật kích thích bé bấm
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06D6A0),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF06D6A0,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 26),
                      label: const Text(
                        'Xong Rồi Nè! ⭐',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onPressed: widget.onFinish,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// CustomPainter vẽ các nét vẽ bằng ngón tay
class _FreehandPainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final Size? drawingSize;

  const _FreehandPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.drawingSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (drawingSize != null) {
      canvas.scale(
        size.width / drawingSize!.width,
        size.height / drawingSize!.height,
      );
    }
    // Vẽ các nét đã hoàn thành
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }

    // Vẽ nét đang tương tác
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentStrokeWidth);
    }
    canvas.restore();
  }

  void _drawStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double strokeWidth,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FreehandPainter oldDelegate) => true;
}

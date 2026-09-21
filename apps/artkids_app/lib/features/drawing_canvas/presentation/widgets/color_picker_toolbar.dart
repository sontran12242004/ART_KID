import 'package:flutter/material.dart';

/// Widget color picker cho canvas — Kid Mode
class ColorPickerToolbar extends StatelessWidget {
  const ColorPickerToolbar({
    super.key,
    required this.selectedColor,
    this.strokeWidth = 6.0,
    double? selectedStrokeWidth,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    this.onClear,
    this.onUndo,
  }) : actualStrokeWidth = selectedStrokeWidth ?? strokeWidth;

  final Color selectedColor;
  final double strokeWidth;
  final double actualStrokeWidth;
  final void Function(Color) onColorChanged;
  final void Function(double) onStrokeWidthChanged;
  final VoidCallback? onClear;
  final VoidCallback? onUndo;

  static const List<Color> kidColors = [
    Colors.black,
    Color(0xFFFF6B6B),   // Đỏ san hô
    Color(0xFFFF8E53),   // Cam
    Color(0xFFFECE00),   // Vàng tươi
    Color(0xFF4ECDC4),   // Xanh ngọc
    Color(0xFF6C5CE7),   // Tím
    Color(0xFF00B894),   // Xanh lá
    Color(0xFF0984E3),   // Xanh dương
    Color(0xFFE17055),   // Nâu đỏ
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color palette
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kidColors.map((color) {
                final isSelected = color == selectedColor;
                return GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 44 : 36,
                    height: isSelected ? 44 : 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                          : [],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Stroke width & tools
          Row(
            children: [
              const Icon(Icons.line_weight, size: 20),
              Expanded(
                child: Slider(
                  value: actualStrokeWidth,
                  min: 2,
                  max: 20,
                  onChanged: onStrokeWidthChanged,
                ),
              ),
              if (onUndo != null)
                IconButton(
                  icon: const Icon(Icons.undo, size: 28),
                  tooltip: 'Hoàn tác',
                  onPressed: onUndo,
                ),
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 28, color: Colors.red),
                  tooltip: 'Xóa hết',
                  onPressed: onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

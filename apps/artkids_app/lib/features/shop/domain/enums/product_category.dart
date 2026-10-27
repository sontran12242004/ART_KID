import 'package:flutter/material.dart';

/// Enum phân loại danh mục sản phẩm học cụ trong Shop
enum ProductCategory {
  all(value: 'all', label: 'Tất cả', icon: Icons.apps_rounded),
  courseKit(
    value: 'course_kit',
    label: 'Kit theo khóa học',
    icon: Icons.palette_rounded,
  ),
  individualTool(
    value: 'individual_tool',
    label: 'Dụng cụ lẻ',
    icon: Icons.brush_rounded,
  ),
  comboSaver(
    value: 'combo_saver',
    label: 'Combo tiết kiệm',
    icon: Icons.local_offer_rounded,
  );

  const ProductCategory({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  static ProductCategory fromString(String? val) {
    if (val == null) return ProductCategory.all;
    final normalized = val.toLowerCase().replaceAll('-', '_').trim();
    switch (normalized) {
      case 'course_kit':
      case 'coursekit':
      case 'kit':
        return ProductCategory.courseKit;
      case 'individual_tool':
      case 'individualtool':
      case 'tool':
      case 'retail':
        return ProductCategory.individualTool;
      case 'combo_saver':
      case 'combosaver':
      case 'combo':
        return ProductCategory.comboSaver;
      case 'all':
      default:
        return ProductCategory.all;
    }
  }
}

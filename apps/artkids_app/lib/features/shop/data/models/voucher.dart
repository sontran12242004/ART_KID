import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../domain/enums/discount_type.dart';

/// Mã lỗi khi xác thực voucher
enum VoucherErrorCode {
  none,
  notFound,
  expired,
  minOrderNotMet,
  outOfUsage,
  notApplicable,
}

/// Model đại diện cho một Voucher / Mã giảm giá trong hệ thống ArtKids
class Voucher extends Equatable {
  const Voucher({
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscountAmount,
    required this.expiryDate,
    this.isUsable = true,
    this.usageLimit = 100,
    this.description,
  });

  /// Mã voucher viết hoa (VD: "ARTKIDS10", "KID30K")
  final String code;

  /// Tên hiển thị (VD: "Giảm 10% đơn từ 200k")
  final String title;

  /// Loại giảm giá (percentage hoặc fixedAmount)
  final DiscountType discountType;

  /// Giá trị giảm:
  /// - Nếu percentage: số % (VD: 10 nghĩa là 10%)
  /// - Nếu fixedAmount: số tiền VNĐ (VD: 30000 nghĩa là 30.000 đ)
  final int discountValue;

  /// Giá trị đơn hàng tối thiểu (VNĐ) để được áp dụng
  final int minOrderAmount;

  /// Mức giảm tối đa (VNĐ) khi dùng giảm theo phần trăm (nếu có)
  final int? maxDiscountAmount;

  /// Ngày giờ hết hạn sử dụng
  final DateTime expiryDate;

  /// Cờ trạng thái khả dụng chung từ hệ thống
  final bool isUsable;

  /// Số lượt sử dụng còn lại (0 nghĩa là đã hết lượt)
  final int usageLimit;

  /// Mô tả chi tiết điều kiện áp dụng
  final String? description;

  /// Kiểm tra xem voucher đã quá hạn hay chưa
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Tính số tiền giảm giá thực tế (VNĐ) dựa trên giá trị tạm tính của đơn hàng
  int calculateDiscount(int subtotalVnd) {
    if (subtotalVnd <= 0 || subtotalVnd < minOrderAmount) {
      return 0;
    }

    if (discountType == DiscountType.percentage) {
      // Giảm theo %: làm tròn số tiền giảm
      final rawDiscount = (subtotalVnd * discountValue / 100).round();
      // Nếu có trần giảm giá tối đa thì không vượt quá trần
      if (maxDiscountAmount != null && rawDiscount > maxDiscountAmount!) {
        return maxDiscountAmount!;
      }
      return rawDiscount;
    } else {
      // Giảm theo số tiền cố định: không được giảm vượt quá tổng giá trị hàng
      return min(discountValue, subtotalVnd);
    }
  }

  Voucher copyWith({
    String? code,
    String? title,
    DiscountType? discountType,
    int? discountValue,
    int? minOrderAmount,
    int? maxDiscountAmount,
    DateTime? expiryDate,
    bool? isUsable,
    int? usageLimit,
    String? description,
  }) {
    return Voucher(
      code: code ?? this.code,
      title: title ?? this.title,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      isUsable: isUsable ?? this.isUsable,
      usageLimit: usageLimit ?? this.usageLimit,
      description: description ?? this.description,
    );
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: (json['code'] as String? ?? '').toUpperCase().trim(),
      title: json['title'] as String? ?? '',
      discountType: DiscountType.fromString(json['discount_type'] as String?),
      discountValue: (json['discount_value'] as num?)?.toInt() ?? 0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toInt() ?? 0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toInt(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 30)),
      isUsable: json['is_usable'] as bool? ?? true,
      usageLimit: (json['usage_limit'] as num?)?.toInt() ?? 100,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      if (maxDiscountAmount != null) 'max_discount_amount': maxDiscountAmount,
      'expiry_date': expiryDate.toIso8601String(),
      'is_usable': isUsable,
      'usage_limit': usageLimit,
      if (description != null) 'description': description,
    };
  }

  @override
  List<Object?> get props => [
    code,
    title,
    discountType,
    discountValue,
    minOrderAmount,
    maxDiscountAmount,
    expiryDate,
    isUsable,
    usageLimit,
    description,
  ];
}

/// Kết quả kiểm tra xác thực mã voucher cho một đơn hàng cụ thể
class VoucherValidationResult extends Equatable {
  const VoucherValidationResult({
    required this.isValid,
    this.voucher,
    this.discountAmountVnd = 0,
    this.errorMessage,
    this.errorCode = VoucherErrorCode.none,
  });

  /// Mã có hợp lệ và áp dụng được hay không
  final bool isValid;

  /// Đối tượng voucher nếu tìm thấy
  final Voucher? voucher;

  /// Số tiền giảm giá cụ thể (VNĐ)
  final int discountAmountVnd;

  /// Thông báo lỗi chi tiết thân thiện với người dùng
  final String? errorMessage;

  /// Mã định danh lỗi kỹ thuật
  final VoucherErrorCode errorCode;

  factory VoucherValidationResult.success({
    required Voucher voucher,
    required int discountAmountVnd,
  }) {
    return VoucherValidationResult(
      isValid: true,
      voucher: voucher,
      discountAmountVnd: discountAmountVnd,
      errorCode: VoucherErrorCode.none,
    );
  }

  factory VoucherValidationResult.failure({
    required String errorMessage,
    required VoucherErrorCode errorCode,
    Voucher? voucher,
  }) {
    return VoucherValidationResult(
      isValid: false,
      voucher: voucher,
      discountAmountVnd: 0,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [
    isValid,
    voucher,
    discountAmountVnd,
    errorMessage,
    errorCode,
  ];
}

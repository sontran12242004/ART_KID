import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/enums/discount_type.dart';
import '../models/voucher.dart';

/// Provider cung cấp VoucherRepository
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VoucherRepositoryImpl(dio);
});

/// Interface giao tiếp với nguồn dữ liệu Voucher
abstract class VoucherRepository {
  /// Lấy danh sách các voucher khả dụng của phụ huynh hiện tại (GET /vouchers/available)
  Future<List<Voucher>> getAvailableVouchers();

  /// Kiểm tra 1 mã nhập tay có hợp lệ với đơn hàng hiện tại không (POST /vouchers/validate)
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required int orderSubtotalVnd,
  });
}

/// Triển khai VoucherRepository hỗ trợ cả API thật và Mock Data
class VoucherRepositoryImpl implements VoucherRepository {
  VoucherRepositoryImpl(this._dio);

  final Dio _dio;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Future<List<Voucher>> getAvailableVouchers() async {
    if (EnvConfig.enableMockShop) {
      debugPrint('[VoucherRepository] Sử dụng Mock Data Vouchers (ENABLE_MOCK_SHOP=true)');
      await Future.delayed(const Duration(milliseconds: 250));
      return _getMockVouchers();
    }

    try {
      final response = await _dio.get(ApiConstants.vouchersAvailable);
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((e) => Voucher.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[VoucherRepository] Lỗi gọi API vouchers: $e. Fallback về Mock.');
      return _getMockVouchers();
    }
  }

  @override
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required int orderSubtotalVnd,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    if (cleanCode.isEmpty) {
      return VoucherValidationResult.failure(
        errorMessage: 'Vui lòng nhập mã giảm giá.',
        errorCode: VoucherErrorCode.notFound,
      );
    }

    if (EnvConfig.enableMockShop) {
      debugPrint(
          '[VoucherRepository] Validate voucher "$cleanCode" với đơn $orderSubtotalVnd đ');
      await Future.delayed(const Duration(milliseconds: 200));
      return _validateMockVoucher(cleanCode, orderSubtotalVnd);
    }

    try {
      final response = await _dio.post(
        ApiConstants.vouchersValidate,
        data: {
          'code': cleanCode,
          'order_subtotal_vnd': orderSubtotalVnd,
        },
      );

      final data = response.data;
      if (data['is_valid'] == true && data['voucher'] != null) {
        final voucher = Voucher.fromJson(data['voucher'] as Map<String, dynamic>);
        final discount = (data['discount_amount_vnd'] as num?)?.toInt() ??
            voucher.calculateDiscount(orderSubtotalVnd);
        return VoucherValidationResult.success(
          voucher: voucher,
          discountAmountVnd: discount,
        );
      } else {
        return VoucherValidationResult.failure(
          errorMessage: data['message'] as String? ?? 'Mã giảm giá không hợp lệ.',
          errorCode: VoucherErrorCode.notApplicable,
        );
      }
    } catch (e) {
      debugPrint('[VoucherRepository] Lỗi validate API: $e. Fallback sang mock.');
      return _validateMockVoucher(cleanCode, orderSubtotalVnd);
    }
  }

  // ==================== MOCK DATA & VALIDATION LOGIC ====================

  VoucherValidationResult _validateMockVoucher(
      String cleanCode, int orderSubtotalVnd) {
    final vouchers = _getMockVouchers();
    final voucherIndex =
        vouchers.indexWhere((v) => v.code.toUpperCase() == cleanCode);

    // 1. Trường hợp mã không tồn tại
    if (voucherIndex == -1) {
      return VoucherValidationResult.failure(
        errorMessage:
            'Mã giảm giá "$cleanCode" không tồn tại hoặc đã bị gỡ bỏ.',
        errorCode: VoucherErrorCode.notFound,
      );
    }

    final voucher = vouchers[voucherIndex];

    // 2. Trường hợp mã đã hết hạn sử dụng
    if (voucher.isExpired) {
      return VoucherValidationResult.failure(
        errorMessage:
            'Mã giảm giá "$cleanCode" đã hết hạn sử dụng vào ngày ${_dateFormat.format(voucher.expiryDate)}.',
        errorCode: VoucherErrorCode.expired,
        voucher: voucher,
      );
    }

    // 3. Trường hợp mã đã hết lượt sử dụng
    if (voucher.usageLimit <= 0) {
      return VoucherValidationResult.failure(
        errorMessage: 'Mã giảm giá "$cleanCode" đã hết số lượt sử dụng.',
        errorCode: VoucherErrorCode.outOfUsage,
        voucher: voucher,
      );
    }

    // 4. Trường hợp voucher bị vô hiệu hóa từ hệ thống
    if (!voucher.isUsable) {
      return VoucherValidationResult.failure(
        errorMessage:
            'Mã giảm giá "$cleanCode" hiện không khả dụng cho tài khoản này.',
        errorCode: VoucherErrorCode.notApplicable,
        voucher: voucher,
      );
    }

    // 5. Trường hợp đơn hàng chưa đạt giá trị tối thiểu
    if (orderSubtotalVnd < voucher.minOrderAmount) {
      final diff = voucher.minOrderAmount - orderSubtotalVnd;
      return VoucherValidationResult.failure(
        errorMessage:
            'Đơn hàng chưa đạt giá trị tối thiểu ${_currencyFormat.format(voucher.minOrderAmount)}. Vui lòng mua thêm ${_currencyFormat.format(diff)} để áp dụng mã này.',
        errorCode: VoucherErrorCode.minOrderNotMet,
        voucher: voucher,
      );
    }

    // 6. Áp dụng thành công: tính số tiền giảm cụ thể
    // - Nếu percentage: tính % theo subtotalVnd và áp mức trần (nếu có)
    // - Nếu fixedAmount: giảm trực tiếp số tiền quy định
    final discount = voucher.calculateDiscount(orderSubtotalVnd);

    return VoucherValidationResult.success(
      voucher: voucher,
      discountAmountVnd: discount,
    );
  }

  static List<Voucher> _getMockVouchers() {
    final now = DateTime.now();
    return [
      // 1. Voucher giảm theo % (Hợp lệ cho đơn từ 200k)
      Voucher(
        code: 'ARTKIDS10',
        title: 'Giảm 10% đơn từ 200k',
        discountType: DiscountType.percentage,
        discountValue: 10,
        minOrderAmount: 200000,
        maxDiscountAmount: 50000,
        expiryDate: now.add(const Duration(days: 30)),
        isUsable: true,
        usageLimit: 100,
        description:
            'Áp dụng cho mọi bộ kit và dụng cụ vẽ khi đơn hàng từ 200.000 đ. Giảm tối đa 50.000 đ.',
      ),

      // 2. Voucher giảm số tiền cố định (Hợp lệ cho đơn từ 150k)
      Voucher(
        code: 'KID30K',
        title: 'Giảm 30.000 đ cho đơn từ 150k',
        discountType: DiscountType.fixedAmount,
        discountValue: 30000,
        minOrderAmount: 150000,
        expiryDate: now.add(const Duration(days: 15)),
        isUsable: true,
        usageLimit: 50,
        description:
            'Ưu đãi dành tặng bé mua họa cụ đầu năm học. Áp dụng cho đơn từ 150.000 đ.',
      ),

      // 3. Voucher đơn tối thiểu cao (Dùng để test lỗi chưa đủ điều kiện)
      Voucher(
        code: 'VIP500K',
        title: 'Giảm 50.000 đ cho đơn từ 500k',
        discountType: DiscountType.fixedAmount,
        discountValue: 50000,
        minOrderAmount: 500000,
        expiryDate: now.add(const Duration(days: 20)),
        isUsable: true,
        usageLimit: 25,
        description:
            'Dành cho đơn hàng combo học cụ hoặc đặt nhiều bộ kit từ 500.000 đ.',
      ),

      // 4. Voucher đã hết hạn (Dùng để test lỗi hết hạn)
      Voucher(
        code: 'EXPIRED20',
        title: 'Giảm 20% tri ân phụ huynh (Hết hạn)',
        discountType: DiscountType.percentage,
        discountValue: 20,
        minOrderAmount: 100000,
        expiryDate: now.subtract(const Duration(days: 2)),
        isUsable: false,
        usageLimit: 50,
        description:
            'Chương trình khuyến mãi tuần lễ nghệ thuật thiếu nhi (Đã kết thúc).',
      ),

      // 5. Voucher đã hết lượt dùng (Dùng để test lỗi hết số lượng)
      Voucher(
        code: 'SOLDOUT',
        title: 'Giảm 40.000 đ chào bạn mới (Hết lượt)',
        discountType: DiscountType.fixedAmount,
        discountValue: 40000,
        minOrderAmount: 100000,
        expiryDate: now.add(const Duration(days: 10)),
        isUsable: false,
        usageLimit: 0,
        description:
            'Mã ưu đãi số lượng giới hạn dành cho khách hàng mới (Đã hết lượt sử dụng).',
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/enums/payment_status.dart';

/// Section tổng kết chi phí thanh toán và phương thức giao dịch
class OrderPaymentSummary extends StatelessWidget {
  const OrderPaymentSummary({
    super.key,
    required this.subtotalVnd,
    required this.shippingFeeVnd,
    required this.discountVnd,
    this.voucherCode,
    required this.totalAmountVnd,
    required this.paymentMethodName,
    required this.paymentStatus,
  });

  final int subtotalVnd;
  final int shippingFeeVnd;
  final int discountVnd;
  final String? voucherCode;
  final int totalAmountVnd;
  final String paymentMethodName;
  final PaymentStatus paymentStatus;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECEF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  size: 20,
                  color: Color(0xFF00B894),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Chi Tiết Thanh Toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tạm tính
          _buildSummaryRow(
            label: 'Tạm tính học cụ',
            value: _currencyFormat.format(subtotalVnd),
          ),
          const SizedBox(height: 10),

          // Phí vận chuyển
          _buildSummaryRow(
            label: 'Phí vận chuyển tận nơi',
            value: shippingFeeVnd == 0
                ? 'Miễn phí'
                : _currencyFormat.format(shippingFeeVnd),
            valueColor: shippingFeeVnd == 0 ? const Color(0xFF27AE60) : null,
          ),

          // Giảm giá (nếu có)
          if (discountVnd > 0) ...[
            const SizedBox(height: 10),
            _buildSummaryRow(
              label: voucherCode != null && voucherCode!.isNotEmpty
                  ? 'Giảm giá voucher ($voucherCode)'
                  : 'Ưu đãi / Giảm giá',
              value: '-${_currencyFormat.format(discountVnd)}',
              valueColor: const Color(0xFF27AE60),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F2F6)),
          const SizedBox(height: 14),

          // Tổng cộng (In đậm, cỡ lớn)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
              Text(
                _currencyFormat.format(totalAmountVnd),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F2F6)),
          const SizedBox(height: 14),

          // Phương thức thanh toán + Payment Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phương thức thanh toán:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      paymentMethodName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Payment status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: paymentStatus.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: paymentStatus.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      paymentStatus.icon,
                      size: 14,
                      color: paymentStatus.color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      paymentStatus.label,
                      style: TextStyle(
                        color: paymentStatus.color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF57606F),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
}

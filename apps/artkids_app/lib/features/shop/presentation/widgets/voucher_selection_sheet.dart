import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/voucher.dart';
import '../../data/repositories/voucher_repository.dart';

/// Bottom Sheet hiển thị danh sách các voucher khả dụng để phụ huynh lựa chọn
class VoucherSelectionSheet extends ConsumerWidget {
  const VoucherSelectionSheet({
    super.key,
    required this.orderSubtotalVnd,
    this.selectedVoucher,
    required this.onVoucherSelected,
  });

  final int orderSubtotalVnd;
  final Voucher? selectedVoucher;
  final ValueChanged<Voucher> onVoucherSelected;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Hàm tiện ích mở Bottom Sheet
  static Future<Voucher?> show({
    required BuildContext context,
    required int orderSubtotalVnd,
    Voucher? selectedVoucher,
    required ValueChanged<Voucher> onVoucherSelected,
  }) {
    return showModalBottomSheet<Voucher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoucherSelectionSheet(
        orderSubtotalVnd: orderSubtotalVnd,
        selectedVoucher: selectedVoucher,
        onVoucherSelected: onVoucherSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(_availableVouchersProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh kéo (Drag handle)
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDCDDE1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.local_offer_rounded,
                      color: Color(0xFF1687A7),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kho Voucher ArtKids',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF7F8C8D),
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8ECEF)),

          // Danh sách voucher
          Expanded(
            child: vouchersAsync.when(
              data: (vouchers) {
                if (vouchers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Hiện chưa có mã giảm giá nào.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vouchers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    return _buildVoucherCard(context, voucher);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(child: Text('Lỗi tải danh sách: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, Voucher voucher) {
    final isSelected = selectedVoucher?.code == voucher.code;
    final isExpired = voucher.isExpired;
    final isOutOfUsage = voucher.usageLimit <= 0;
    final isMinOrderMet = orderSubtotalVnd >= voucher.minOrderAmount;
    final isEligible =
        !isExpired && !isOutOfUsage && voucher.isUsable && isMinOrderMet;

    // Tính số tiền còn thiếu nếu chưa đạt đơn tối thiểu
    final missingAmount = voucher.minOrderAmount - orderSubtotalVnd;

    return Container(
      decoration: BoxDecoration(
        color: isEligible ? Colors.white : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF27AE60)
              : (isEligible
                    ? const Color(0xFFE8ECEF)
                    : const Color(0xFFDCDDE1)),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: isEligible
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag mã
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isEligible
                        ? const Color(0xFFE8F4F8)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEligible
                          ? const Color(0xFF1687A7).withValues(alpha: 0.3)
                          : const Color(0xFFBDC3C7),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 20,
                        color: isEligible
                            ? const Color(0xFF1687A7)
                            : const Color(0xFF7F8C8D),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isEligible
                              ? const Color(0xFF0F3B46)
                              : const Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Nội dung voucher
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isEligible
                              ? const Color(0xFF2C3E50)
                              : const Color(0xFF7F8C8D),
                        ),
                      ),
                      if (voucher.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          voucher.description!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isEligible
                                ? const Color(0xFF5A6B7C)
                                : const Color(0xFF95A5A6),
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'HSD: ${_dateFormat.format(voucher.expiryDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider dạng nét đứt hoặc mờ
          const Divider(height: 1, color: Color(0xFFF1F2F6)),

          // Footer của card: thông tin điều kiện & nút Áp dụng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ghi chú trạng thái
                Expanded(
                  child: isExpired
                      ? const Text(
                          'Mã đã hết hạn sử dụng',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFE74C3C),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : (isOutOfUsage
                            ? const Text(
                                'Mã đã hết lượt sử dụng',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFE74C3C),
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : (!isMinOrderMet
                                  ? Text(
                                      'Mua thêm ${_currencyFormat.format(missingAmount)} để dùng',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFE67E22),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : Text(
                                      'Tiết kiệm ${_currencyFormat.format(voucher.calculateDiscount(orderSubtotalVnd))}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF27AE60),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ))),
                ),

                // Nút chọn
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF27AE60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Color(0xFF27AE60),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đang dùng',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: isEligible
                        ? () {
                            onVoucherSelected(voucher);
                            Navigator.of(context).pop(voucher);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3B46),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: const Color(0xFF9E9E9E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider nội bộ lấy danh sách voucher khả dụng
final _availableVouchersProvider = FutureProvider.autoDispose<List<Voucher>>((
  ref,
) {
  final repository = ref.watch(voucherRepositoryProvider);
  return repository.getAvailableVouchers();
});

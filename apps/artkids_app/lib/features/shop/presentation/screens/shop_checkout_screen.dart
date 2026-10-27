import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/domain/entities/order_item_entity.dart';
import '../../../orders/domain/entities/order_tracking_event_entity.dart';
import '../../../orders/domain/entities/shipping_info_entity.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../orders/domain/enums/order_type.dart';
import '../../../orders/domain/enums/payment_status.dart';
import '../../../orders/presentation/providers/orders_list_provider.dart';
import '../../data/models/voucher.dart';
import '../../data/repositories/voucher_repository.dart';
import '../providers/cart_provider.dart';
import '../widgets/voucher_selection_sheet.dart';

enum PaymentMethodOption {
  vietQr(
    title: 'Chuyển khoản VietQR',
    subtitle: 'Quét mã QR tự động xác nhận qua App Ngân hàng',
    icon: Icons.qr_code_2_rounded,
    badgeText: 'Khuyên dùng',
  ),
  vnpay(
    title: 'Cổng thanh toán VNPAY',
    subtitle: 'Thẻ ATM nội địa, ví VNPAY, Internet Banking',
    icon: Icons.account_balance_wallet_outlined,
  ),
  card(
    title: 'Thẻ Quốc Tế (Visa / Mastercard / JCB)',
    subtitle: 'Thanh toán trực tuyến bảo mật tiêu chuẩn quốc tế',
    icon: Icons.credit_card_rounded,
  ),
  cod(
    title: 'Thanh toán khi nhận hàng (COD)',
    subtitle: 'Thanh toán tiền mặt cho shipper khi nhận được kiện hàng',
    icon: Icons.local_atm_rounded,
  );

  const PaymentMethodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText;
}

/// Màn hình thanh toán đơn hàng mua lẻ trong Cửa hàng học cụ
class ShopCheckoutScreen extends ConsumerStatefulWidget {
  const ShopCheckoutScreen({super.key});

  @override
  ConsumerState<ShopCheckoutScreen> createState() => _ShopCheckoutScreenState();
}

class _ShopCheckoutScreenState extends ConsumerState<ShopCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  late final TextEditingController _voucherCodeController;

  PaymentMethodOption _selectedPayment = PaymentMethodOption.vietQr;
  bool _isSubmitting = false;
  bool _isValidatingVoucher = false;
  String? _voucherError;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Nguyễn Văn Minh');
    _phoneController = TextEditingController(text: '0912 345 678');
    _addressController = TextEditingController(
      text:
          'Phòng 402, Chung cư Sunrise Riverside, Nguyễn Hữu Thọ, Phước Kiển, Nhà Bè, TP. Hồ Chí Minh',
    );
    _noteController = TextEditingController(
      text: 'Giao giờ hành chính, gọi trước khi đến.',
    );
    _voucherCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _voucherCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalVndProvider);
    final appliedVoucher = ref.watch(appliedVoucherProvider);
    final discountVnd = ref.watch(cartDiscountVndProvider);
    final shippingFee = ref.watch(cartShippingFeeVndProvider);
    final totalAmount = ref.watch(cartFinalTotalVndProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2C3E50),
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Xác nhận đặt hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCartPlaceholder()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  // Thông tin người nhận
                  _buildShippingInfoCard(),
                  const SizedBox(height: 16),

                  // Phương thức vận chuyển
                  _buildShippingMethodCard(shippingFee),
                  const SizedBox(height: 16),

                  // Phương thức thanh toán
                  _buildPaymentMethodsCard(),
                  const SizedBox(height: 16),

                  // Danh sách sản phẩm
                  _buildOrderItemsCard(cartItems),
                  const SizedBox(height: 16),

                  // Mã ưu đãi / Voucher
                  _buildVoucherSection(subtotal, appliedVoucher, discountVnd),
                  const SizedBox(height: 16),

                  // Chi tiết thanh toán & Mã giảm giá
                  _buildPriceBreakdownCard(
                    subtotal: subtotal,
                    shippingFee: shippingFee,
                    discountVnd: discountVnd,
                    totalAmount: totalAmount,
                    appliedVoucher: appliedVoucher,
                  ),
                  const SizedBox(height: 16),

                  // Cam kết an toàn
                  _buildSafetyGuaranteeCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _buildStickyBottomBar(totalAmount),
    );
  }

  Widget _buildEmptyCartPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Color(0xFF7F8C8D),
          ),
          const SizedBox(height: 16),
          const Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.parentShop),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3B46),
              foregroundColor: Colors.white,
            ),
            child: const Text('Quay lại Cửa hàng'),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Color(0xFF1687A7),
              ),
              SizedBox(width: 8),
              Text(
                'Địa chỉ nhận hàng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              label: 'Họ và tên người nhận',
              icon: Icons.person_outline,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
            ),
            validator: (v) => (v == null || v.trim().length < 9)
                ? 'Số điện thoại không hợp lệ'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: _inputDecoration(
              label: 'Địa chỉ nhận hàng chi tiết',
              icon: Icons.home_outlined,
            ),
            validator: (v) => (v == null || v.trim().length < 5)
                ? 'Vui lòng nhập địa chỉ cụ thể'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: _inputDecoration(
              label: 'Ghi chú cho shipper (tùy chọn)',
              icon: Icons.note_alt_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingMethodCard(int shippingFee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: Color(0xFF1687A7),
              ),
              SizedBox(width: 8),
              Text(
                'Hình thức giao hàng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1687A7)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.radio_button_checked,
                  size: 18,
                  color: Color(0xFF1687A7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Giao Hàng Nhanh (GHN) — Tiêu chuẩn',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dự kiến nhận sau 2 - 3 ngày làm việc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  shippingFee == 0
                      ? 'Miễn phí'
                      : _currencyFormat.format(shippingFee),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: shippingFee == 0
                        ? const Color(0xFF27AE60)
                        : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.payment_rounded, size: 20, color: Color(0xFF1687A7)),
              SizedBox(width: 8),
              Text(
                'Phương thức thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...PaymentMethodOption.values.map((option) {
            final isSelected = _selectedPayment == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedPayment = option),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0F8FA)
                        : const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1687A7)
                          : const Color(0xFFE8ECEF),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF1687A7)
                            : const Color(0xFFBDC3C7),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        option.icon,
                        size: 20,
                        color: const Color(0xFF2C3E50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    option.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: const Color(0xFF2C3E50),
                                    ),
                                  ),
                                ),
                                if (option.badgeText != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      option.badgeText!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.subtitle,
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
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(List cartItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Color(0xFF1687A7),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kiện hàng học cụ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              Text(
                '${cartItems.length} sản phẩm',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8ECEF)),
          const SizedBox(height: 10),
          ...cartItems.map((item) {
            final product = item.product;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: const Color(0xFFF1F2F6),
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: const Color(0xFFECEFF1)),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: Color(0xFF1687A7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_currencyFormat.format(product.priceVnd)} x ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(item.totalPriceVnd),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVoucherSection(
    int subtotal,
    Voucher? appliedVoucher,
    int discountVnd,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                    color: Color(0xFF1687A7),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Mã ưu đãi / Voucher',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              if (appliedVoucher == null)
                TextButton.icon(
                  onPressed: () => _openVoucherSheet(subtotal),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(
                    Icons.loyalty_outlined,
                    size: 16,
                    color: Color(0xFF1687A7),
                  ),
                  label: const Text(
                    'Chọn voucher',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1687A7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Khi ĐÃ áp dụng voucher thành công
          if (appliedVoucher != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                appliedVoucher.code,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                appliedVoucher.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF14532D),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đã giảm: -${_currencyFormat.format(discountVnd)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _removeVoucher,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Bỏ chọn',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Khi CHƯA áp dụng voucher: Ô nhập mã + nút Áp dụng
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã voucher (VD: ARTKIDS10)',
                      hintStyle: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF95A5A6),
                      ),
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                        color: Color(0xFF1687A7),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFB),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF1687A7),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_voucherError != null) {
                        setState(() => _voucherError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isValidatingVoucher
                        ? null
                        : () => _handleApplyVoucherInput(subtotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3B46),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isValidatingVoucher
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Áp dụng',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            // Hiển thị thông báo lỗi cụ thể từng trường hợp
            if (_voucherError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFADBD8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: Color(0xFFE74C3C),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _voucherError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC0392B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _openVoucherSheet(int subtotal) {
    final currentVoucher = ref.read(appliedVoucherProvider);
    VoucherSelectionSheet.show(
      context: context,
      orderSubtotalVnd: subtotal,
      selectedVoucher: currentVoucher,
      onVoucherSelected: (voucher) {
        ref.read(appliedVoucherProvider.notifier).state = voucher;
        _voucherCodeController.text = voucher.code;
        setState(() => _voucherError = null);
        final discount = voucher.calculateDiscount(subtotal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã áp dụng mã "${voucher.code}": Giảm ${_currencyFormat.format(discount)}',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _removeVoucher() {
    ref.read(appliedVoucherProvider.notifier).state = null;
    _voucherCodeController.clear();
    setState(() => _voucherError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gỡ mã giảm giá.'),
        backgroundColor: Color(0xFF5A6B7C),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleApplyVoucherInput(int subtotal) async {
    final code = _voucherCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _voucherError = 'Vui lòng nhập mã giảm giá.');
      return;
    }

    setState(() {
      _isValidatingVoucher = true;
      _voucherError = null;
    });

    try {
      final repo = ref.read(voucherRepositoryProvider);
      final result = await repo.validateVoucher(
        code: code,
        orderSubtotalVnd: subtotal,
      );

      if (!mounted) return;

      if (result.isValid && result.voucher != null) {
        ref.read(appliedVoucherProvider.notifier).state = result.voucher;
        setState(() {
          _voucherError = null;
          _isValidatingVoucher = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã áp dụng mã "${result.voucher!.code}": Giảm ${_currencyFormat.format(result.discountAmountVnd)}',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _voucherError = result.errorMessage ?? 'Mã giảm giá không hợp lệ.';
          _isValidatingVoucher = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voucherError = 'Không thể kiểm tra mã lúc này: $e';
        _isValidatingVoucher = false;
      });
    }
  }

  Widget _buildPriceBreakdownCard({
    required int subtotal,
    required int shippingFee,
    required int discountVnd,
    required int totalAmount,
    Voucher? appliedVoucher,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Tạm tính tiền hàng',
            _currencyFormat.format(subtotal),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Phí vận chuyển (GHN)',
            shippingFee == 0 ? 'Miễn phí' : _currencyFormat.format(shippingFee),
            valueColor: shippingFee == 0
                ? const Color(0xFF27AE60)
                : const Color(0xFF2C3E50),
          ),
          if (discountVnd > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              appliedVoucher != null
                  ? 'Giảm giá voucher (${appliedVoucher.code})'
                  : 'Ưu đãi / Giảm giá',
              '-${_currencyFormat.format(discountVnd)}',
              valueColor: const Color(0xFF27AE60),
            ),
          ] else ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Ưu đãi / Giảm giá',
              '0 đ',
              valueColor: const Color(0xFF7F8C8D),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8ECEF)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                _currencyFormat.format(totalAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5A6B7C)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: Color(0xFF2E7D32),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tất cả học cụ ArtKids đều tuân thủ tiêu chuẩn an toàn ASTM D-4236 và EN 71, hoàn toàn không độc hại cho trẻ nhỏ. Hỗ trợ đổi mới trong 7 ngày nếu sản phẩm lỗi.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF2E7D32),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(int totalAmount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8ECEF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                ),
                Text(
                  _currencyFormat.format(totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F3B46),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3B46),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Xác nhận Đặt hàng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF7F8C8D)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1687A7)),
      filled: true,
      fillColor: const Color(0xFFF8FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1687A7), width: 1.5),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final subtotal = ref.read(cartSubtotalVndProvider);
      final appliedVoucher = ref.read(appliedVoucherProvider);
      final discountVnd = ref.read(cartDiscountVndProvider);
      final shippingFee = ref.read(cartShippingFeeVndProvider);
      final totalAmount = ref.read(cartFinalTotalVndProvider);

      // Sinh mã đơn hàng ngẫu nhiên
      final randomNum = 1000 + Random().nextInt(9000);
      final orderCode = 'ORD-2026-$randomNum';
      final orderId = 'ord_shop_${DateTime.now().millisecondsSinceEpoch}';

      // Chuyển CartItem sang OrderItemEntity
      final orderItems = cartItems.map((item) {
        return OrderItemEntity(
          id: item.product.id,
          kitName: item.product.name,
          thumbnailUrl: item.product.thumbnailUrl,
          quantity: item.quantity,
          unitPriceVnd: item.product.priceVnd,
          courseId: item.product.courseId,
          courseTitle: item.product.courseTitle,
          kitItems: item.product.kitItems,
        );
      }).toList();

      final shippingInfo = ShippingInfoEntity(
        recipientName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        fullAddress: _addressController.text.trim(),
        carrierName: 'Giao Hàng Nhanh (GHN)',
        estimatedDeliveryDate: DateTime.now().add(const Duration(days: 3)),
      );

      final trackingEvents = [
        OrderTrackingEventEntity(
          id: 'evt_1',
          title: 'Đặt hàng thành công',
          description:
              'Đơn hàng mua lẻ từ Shop đã được ghi nhận. Phương thức: ${_selectedPayment.title}.',
          timestamp: DateTime.now(),
          isPassed: true,
          isCurrent: true,
        ),
        const OrderTrackingEventEntity(
          id: 'evt_2',
          title: 'Xác nhận đơn & Chuẩn bị kho',
          description: 'Hệ thống kho đang soạn các dụng cụ học vẽ',
          isPassed: false,
          isCurrent: false,
        ),
        const OrderTrackingEventEntity(
          id: 'evt_3',
          title: 'Bàn giao vận chuyển GHN',
          description:
              'Kiện hàng được dán nhãn niêm phong và gửi đến trung tâm trung chuyển',
          isPassed: false,
          isCurrent: false,
        ),
        const OrderTrackingEventEntity(
          id: 'evt_4',
          title: 'Đang phát hàng',
          description: 'Shipper liên hệ giao hàng tận nhà',
          isPassed: false,
          isCurrent: false,
        ),
        const OrderTrackingEventEntity(
          id: 'evt_5',
          title: 'Giao thành công',
          description:
              'Phụ huynh đã nhận đủ bộ dụng cụ và xác nhận kiện hàng nguyên vẹn',
          isPassed: false,
          isCurrent: false,
        ),
      ];

      final newOrder = OrderEntity(
        id: orderId,
        orderCode: orderCode,
        createdAt: DateTime.now(),
        status: OrderStatus.pendingConfirmation,
        orderType: OrderType.oneTimePurchase, // Đơn mua lẻ từ Shop!
        paymentStatus: _selectedPayment == PaymentMethodOption.cod
            ? PaymentStatus.pending
            : PaymentStatus.paid,
        paymentMethodName: _selectedPayment.title,
        items: orderItems,
        shippingInfo: shippingInfo,
        subtotalVnd: subtotal,
        shippingFeeVnd: shippingFee,
        discountVnd: discountVnd,
        voucherCode: appliedVoucher?.code,
        totalAmountVnd: totalAmount,
        trackingEvents: trackingEvents,
      );

      // Lưu đơn hàng qua OrderRepository
      final createdOrder = await ref
          .read(orderRepositoryProvider)
          .createOrder(newOrder);

      // Xóa giỏ hàng và voucher đã áp dụng
      ref.read(cartProvider.notifier).clearCart();
      ref.read(appliedVoucherProvider.notifier).state = null;

      // Invalidate danh sách đơn hàng để khi quay lại tab Orders sẽ tự động refresh
      ref.invalidate(ordersListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đặt hàng thành công! Mã đơn: #${createdOrder.orderCode}',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Điều hướng trực tiếp sang màn hình chi tiết đơn hàng
      context.pushReplacement('${RoutePaths.parentOrders}/${createdOrder.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đặt đơn hàng: $e'),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

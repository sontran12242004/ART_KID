import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_type.dart';
import '../providers/order_detail_provider.dart';
import '../widgets/order_action_buttons.dart';
import '../widgets/order_items_section.dart';
import '../widgets/order_payment_summary.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_tracking_timeline.dart';

/// Màn hình Chi tiết Đơn hàng — Phục vụ phụ huynh quản lý & theo dõi học cụ
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  static final _dateFormat = DateFormat('dd/MM/yyyy • HH:mm');
  static final _estimatedDateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F3B46),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Chi Tiết Đơn Hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F3B46),
          ),
        ),
      ),
      body: orderAsync.when(
        data: (order) => _buildBody(context, ref, order),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1687A7)),
        ),
        error: (error, _) => _buildErrorView(context, ref, error),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, OrderEntity order) {
    return Column(
      children: [
        // Nội dung cuộn được chứa tất cả các section từ trên xuống
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // a. Header trạng thái (Badge lớn, Mã đơn, Ngày đặt, Dự kiến giao)
                _buildStatusHeader(context, order),
                if (order.awaitingMarketplacePayment)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Đơn marketplace đang chờ xác minh tiền chuyển khoản. Bên nhận tiền và quy trình xác minh chưa được thống nhất; chưa thể giao hàng.',
                    ),
                  ),
                const SizedBox(height: 16),

                // b. Timeline theo dõi tiến trình
                OrderTrackingTimeline(
                  events: order.trackingEvents,
                  orderStatus: order.status,
                  cancelReason: order.cancelReason,
                ),
                const SizedBox(height: 16),

                // c. Danh sách sản phẩm & Chi tiết bên trong kit
                OrderItemsSection(items: order.items),
                const SizedBox(height: 16),

                // d. Thông tin giao hàng & Mã vận đơn (Copy clipboard)
                _buildShippingInfoCard(context, order),
                const SizedBox(height: 16),

                // e. Tổng kết thanh toán
                OrderPaymentSummary(
                  subtotalVnd: order.subtotalVnd,
                  shippingFeeVnd: order.shippingFeeVnd,
                  discountVnd: order.discountVnd,
                  voucherCode: order.voucherCode,
                  totalAmountVnd: order.totalAmountVnd,
                  paymentMethodName: order.paymentMethodName,
                  paymentStatus: order.paymentStatus,
                ),
              ],
            ),
          ),
        ),

        // f. Nút hành động cố định ở footer
        OrderActionButtons(
          order: order,
          onCancelOrder: (reason) async {
            final success = await ref
                .read(orderActionControllerProvider.notifier)
                .cancelOrder(order.id, reason: reason);

            if (context.mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy đơn hàng thành công.'),
                    backgroundColor: Color(0xFF27AE60),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Không thể hủy đơn hàng lúc này. Vui lòng thử lại.',
                    ),
                    backgroundColor: Color(0xFFE74C3C),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  // ==================== SECTION A: HEADER TRẠNG THÁI ====================

  Widget _buildStatusHeader(BuildContext context, OrderEntity order) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge cỡ lớn nổi bật nhất + Badge loại đơn
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OrderStatusBadge(status: order.status, size: BadgeSize.large),
                  _buildOrderTypeBadge(order.orderType),
                ],
              ),
              // Mã đơn
              Text(
                '#${order.orderCode}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ngày đặt hàng
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Color(0xFF7F8C8D),
              ),
              const SizedBox(width: 6),
              Text(
                'Đặt ngày: ${_dateFormat.format(order.createdAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF57606F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Nếu đang giao: hiển thị dự kiến ngày giao
          if (order.status == OrderStatus.shipping &&
              order.shippingInfo.estimatedDeliveryDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F3F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1687A7).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Color(0xFF1687A7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dự kiến giao: ${_estimatedDateFormat.format(order.shippingInfo.estimatedDeliveryDate!)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F3B46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== SECTION D: THÔNG TIN GIAO HÀNG ====================

  Widget _buildShippingInfoCard(BuildContext context, OrderEntity order) {
    final shipping = order.shippingInfo;

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
                  color: const Color(0xFF0984E3).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: Color(0xFF0984E3),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Địa Chỉ Nhận Học Cụ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tên người nhận & SĐT
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: Color(0xFF7F8C8D),
              ),
              const SizedBox(width: 8),
              Text(
                shipping.recipientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 3, height: 12, color: const Color(0xFFBDC3C7)),
              const SizedBox(width: 10),
              Text(
                shipping.phoneNumber,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF57606F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Địa chỉ đầy đủ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.home_outlined,
                  size: 16,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shipping.fullAddress,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF57606F),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          // Đơn vị vận chuyển & Mã vận đơn (nếu có)
          if (shipping.trackingNumber != null &&
              shipping.trackingNumber!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F2F6)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: Color(0xFF1687A7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipping.carrierName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shipping.trackingNumber!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F3B46),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nút sao chép mã vận đơn
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: shipping.trackingNumber!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Đã sao chép mã vận đơn vào bộ nhớ tạm'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Color(0xFF1687A7),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sao chép',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1687A7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ERROR VIEW ====================

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải thông tin đơn hàng',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F3B46),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1687A7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeBadge(OrderType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: type.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: type.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: type.color),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: type.color,
            ),
          ),
        ],
      ),
    );
  }
}

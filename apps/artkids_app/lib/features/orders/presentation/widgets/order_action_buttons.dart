import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/route_paths.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';

/// Các nút hành động hiển thị linh hoạt theo trạng thái của đơn hàng
class OrderActionButtons extends StatelessWidget {
  const OrderActionButtons({
    super.key,
    required this.order,
    required this.onCancelOrder,
  });

  final OrderEntity order;
  final Future<void> Function(String reason) onCancelOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE8ECEF), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Nút phụ: Liên hệ hỗ trợ (luôn xuất hiện cho mọi trạng thái)
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C3E50),
                      side: const BorderSide(color: Color(0xFFBDC3C7)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showSupportDialog(context),
                    icon: const Icon(Icons.headset_mic_outlined, size: 18),
                    label: const Text(
                      'Hỗ trợ',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Nút chính thay đổi theo trạng thái
                Expanded(flex: 3, child: _buildPrimaryAction(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    if (order.canCancel) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDEDEC),
          foregroundColor: const Color(0xFFE74C3C),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFE74C3C), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _showCancelDialog(context),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text(
          'Hủy đơn',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      );
    }
    switch (order.status) {
      case OrderStatus.pendingConfirmation:
        return Text(
          order.awaitingMarketplacePayment
              ? 'Chờ xác minh thanh toán'
              : 'Đơn đang được xử lý',
        );
      case OrderStatus.preparing:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1687A7),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Học cụ đang được đóng gói cẩn thận tại kho ArtKids.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text(
            'Đang đóng gói',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        );

      case OrderStatus.shipping:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1687A7),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _launchTrackingUrl(context),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text(
            'Theo dõi vận đơn',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
        );

      case OrderStatus.delivered:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE67E22),
                  side: const BorderSide(color: Color(0xFFE67E22)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showReviewDialog(context),
                icon: const Icon(Icons.star_rate_rounded, size: 18),
                label: const Text(
                  'Đánh giá',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1687A7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.push(RoutePaths.parentShop),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text(
                  'Mua lại',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.cancelled:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1687A7),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => context.push(RoutePaths.parentShop),
          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
          label: const Text(
            'Mua lại kit',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        );
    }
  }

  // ==================== DIALOGS & ACTIONS ====================

  /// Mở link tra cứu của đơn vị vận chuyển qua url_launcher
  Future<void> _launchTrackingUrl(BuildContext context) async {
    final trackingUrl = order.shippingInfo.trackingUrl;
    if (trackingUrl != null && trackingUrl.isNotEmpty) {
      final uri = Uri.tryParse(trackingUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback nếu không có url hoặc không mở được
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mã vận đơn ${order.shippingInfo.trackingNumber ?? order.orderCode} từ ${order.shippingInfo.carrierName}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Dialog xác nhận hủy đơn
  void _showCancelDialog(BuildContext context) {
    String selectedReason = 'Đổi ý, không còn nhu cầu';
    final customReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C)),
              SizedBox(width: 8),
              Text(
                'Xác Nhận Hủy Đơn',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn có chắc chắn muốn hủy đơn hàng này không? Sau khi hủy, học cụ sẽ không được vận chuyển tới bé.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF57606F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lý do hủy đơn:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Đổi ý, không còn nhu cầu',
                      child: Text('Đổi ý, không còn nhu cầu'),
                    ),
                    DropdownMenuItem(
                      value: 'Bé đã có sẵn bộ học cụ tương tự',
                      child: Text('Bé đã có sẵn bộ học cụ tương tự'),
                    ),
                    DropdownMenuItem(
                      value: 'Muốn thay đổi địa chỉ nhận hàng',
                      child: Text('Muốn thay đổi địa chỉ nhận hàng'),
                    ),
                    DropdownMenuItem(
                      value: 'Đặt nhầm sản phẩm',
                      child: Text('Đặt nhầm sản phẩm'),
                    ),
                    DropdownMenuItem(
                      value: 'Lý do khác',
                      child: Text('Lý do khác'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedReason = val);
                    }
                  },
                ),
                if (selectedReason == 'Lý do khác') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customReasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do chi tiết...',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Quay lại'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final finalReason =
                    selectedReason == 'Lý do khác' &&
                        customReasonController.text.trim().isNotEmpty
                    ? customReasonController.text.trim()
                    : selectedReason;

                await onCancelOrder(finalReason);
              },
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog đánh giá kit học cụ
  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.rate_review_outlined, color: Color(0xFF1687A7)),
              SizedBox(width: 8),
              Text(
                'Đánh Giá Học Cụ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F3B46),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bé nhà mình cảm thấy thế nào về bộ học cụ này?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF57606F)),
              ),
              const SizedBox(height: 14),
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF39C12),
                      size: 32,
                    ),
                    onPressed: () => setModalState(() => rating = star),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Nhập cảm nhận của bạn và bé về chất lượng màu, giấy vẽ, cọ...',
                  hintStyle: const TextStyle(fontSize: 12.5),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1687A7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Cảm ơn phụ huynh đã gửi đánh giá quý báu!'),
                      ],
                    ),
                    backgroundColor: Color(0xFF27AE60),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog liên hệ hỗ trợ
  void _showSupportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1687A7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF1687A7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Trung Tâm Hỗ Trợ Đơn Hàng',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F3B46),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F8F5),
                  child: Icon(Icons.phone_rounded, color: Color(0xFF27AE60)),
                ),
                title: const Text('Hotline Chăm Sóc Khách Hàng'),
                subtitle: const Text('1900 8899 (8:00 - 21:00 hàng ngày)'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  launchUrl(Uri.parse('tel:19008899'));
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEBF5FB),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF2980B9),
                  ),
                ),
                title: const Text('Hỗ Trợ Qua Zalo Official'),
                subtitle: const Text(
                  'ArtKids Việt Nam — Phản hồi trong 5 phút',
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  launchUrl(
                    Uri.parse('https://zalo.me'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFDF2E9),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFFE67E22),
                  ),
                ),
                title: const Text('Email Hỗ Trợ'),
                subtitle: const Text('hotro@artkids.vn'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  launchUrl(Uri.parse('mailto:hotro@artkids.vn'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

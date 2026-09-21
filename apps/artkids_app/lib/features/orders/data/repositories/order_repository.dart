import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_type.dart';
import '../../domain/enums/payment_status.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_tracking_event.dart';
import '../models/shipping_info.dart';

/// Provider cung cấp DataSource cho Orders
final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRemoteDataSourceImpl(dio);
});

/// Provider cung cấp Repository cho Orders
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource);
});

/// Interface OrderRepository
abstract class OrderRepository {
  Future<List<OrderEntity>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  });

  Future<OrderEntity> getOrderById(String orderId);

  Future<void> cancelOrder(String orderId, {String? reason});

  /// Tạo đơn hàng mới (dùng chung cho luồng mua lẻ trong Shop và luồng Subscription)
  Future<OrderEntity> createOrder(OrderEntity order);
}

/// Triển khai OrderRepositoryImpl hỗ trợ cả API thật và Mock Data
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remoteDataSource);

  final OrderRemoteDataSource _remoteDataSource;

  // In-memory cache cho mock data để test tương tác (ví dụ hủy đơn)
  static final List<OrderModel> _inMemoryMockOrders = _buildInitialMockOrders();

  @override
  Future<List<OrderEntity>> getOrders({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    if (EnvConfig.enableMockOrders) {
      debugPrint('[OrderRepository] Sử dụng Mock Data (ENABLE_MOCK_ORDERS=true)');
      return _filterAndPaginateMockOrders(status: status, page: page, limit: limit);
    }

    try {
      final orders = await _remoteDataSource.getOrders(
        status: status,
        page: page,
        limit: limit,
      );
      return orders;
    } catch (e) {
      debugPrint('[OrderRepository] Lỗi gọi API getOrders ($e). Fallback sang Mock Data.');
      return _filterAndPaginateMockOrders(status: status, page: page, limit: limit);
    }
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    if (EnvConfig.enableMockOrders) {
      return _findMockOrder(orderId);
    }

    try {
      final order = await _remoteDataSource.getOrderById(orderId);
      return order;
    } catch (e) {
      debugPrint('[OrderRepository] Lỗi gọi API getOrderById ($e). Fallback sang Mock Data.');
      return _findMockOrder(orderId);
    }
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    if (EnvConfig.enableMockOrders) {
      debugPrint('[OrderRepository] Mock Hủy đơn $orderId với lý do: $reason');
      _cancelMockOrder(orderId, reason: reason);
      return;
    }

    try {
      await _remoteDataSource.cancelOrder(orderId, reason: reason);
    } catch (e) {
      debugPrint('[OrderRepository] Lỗi gọi API cancelOrder ($e). Hủy trực tiếp trên Mock Data.');
      _cancelMockOrder(orderId, reason: reason);
    }
  }

  @override
  Future<OrderEntity> createOrder(OrderEntity order) async {
    // Chuyển sang OrderModel và lưu vào đầu danh sách mock orders
    final orderModel = order is OrderModel
        ? order
        : OrderModel(
            id: order.id,
            orderCode: order.orderCode,
            createdAt: order.createdAt,
            status: order.status,
            orderType: order.orderType,
            paymentStatus: order.paymentStatus,
            paymentMethodName: order.paymentMethodName,
            items: order.items,
            shippingInfo: order.shippingInfo,
            subtotalVnd: order.subtotalVnd,
            shippingFeeVnd: order.shippingFeeVnd,
            discountVnd: order.discountVnd,
            voucherCode: order.voucherCode,
            totalAmountVnd: order.totalAmountVnd,
            trackingEvents: order.trackingEvents,
            cancelReason: order.cancelReason,
          );

    _inMemoryMockOrders.insert(0, orderModel);
    debugPrint(
        '[OrderRepository] Đã tạo đơn hàng mới #${order.orderCode} (${order.orderType.label})');
    return orderModel;
  }

  // ==================== MOCK DATA HELPERS ====================

  static List<OrderEntity> _filterAndPaginateMockOrders({
    String? status,
    int page = 1,
    int limit = 10,
  }) {
    List<OrderModel> filtered = List.of(_inMemoryMockOrders);

    if (status != null && status.isNotEmpty && status != 'all') {
      if (status == 'processing') {
        filtered = filtered.where((o) => o.status.isProcessing).toList();
      } else {
        filtered = filtered.where((o) => o.status.value == status).toList();
      }
    }

    // Sắp xếp mới nhất lên đầu
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final startIndex = (page - 1) * limit;
    if (startIndex >= filtered.length) {
      return [];
    }
    final endIndex = (startIndex + limit) > filtered.length
        ? filtered.length
        : (startIndex + limit);

    return filtered.sublist(startIndex, endIndex);
  }

  static OrderEntity _findMockOrder(String orderId) {
    try {
      return _inMemoryMockOrders.firstWhere(
        (o) => o.id == orderId || o.orderCode == orderId,
      );
    } catch (_) {
      // Nếu không tìm thấy, trả về đơn hàng đầu tiên làm fallback để tránh crash
      return _inMemoryMockOrders.first;
    }
  }

  static void _cancelMockOrder(String orderId, {String? reason}) {
    final index = _inMemoryMockOrders.indexWhere(
      (o) => o.id == orderId || o.orderCode == orderId,
    );
    if (index != -1) {
      final current = _inMemoryMockOrders[index];
      final updatedEvents = List<OrderTrackingEventModel>.from(
        current.trackingEvents.map((e) => e is OrderTrackingEventModel ? e : OrderTrackingEventModel(
          id: e.id,
          title: e.title,
          description: e.description,
          timestamp: e.timestamp,
          isPassed: e.isPassed,
          isCurrent: false,
          cancelReason: e.cancelReason,
        )),
      );

      // Thêm mốc Đã hủy vào cuối timeline
      updatedEvents.add(OrderTrackingEventModel(
        id: 'evt_cancel',
        title: 'Đã hủy đơn',
        description: reason != null && reason.isNotEmpty
            ? 'Đơn hàng đã được hủy thành công. Lý do: $reason'
            : 'Đơn hàng đã được hủy bởi phụ huynh.',
        timestamp: DateTime.now(),
        isPassed: true,
        isCurrent: true,
        cancelReason: reason ?? 'Hủy theo yêu cầu của phụ huynh',
      ));

      _inMemoryMockOrders[index] = OrderModel(
        id: current.id,
        orderCode: current.orderCode,
        createdAt: current.createdAt,
        status: OrderStatus.cancelled,
        paymentStatus: current.paymentStatus,
        paymentMethodName: current.paymentMethodName,
        items: current.items,
        shippingInfo: current.shippingInfo,
        subtotalVnd: current.subtotalVnd,
        shippingFeeVnd: current.shippingFeeVnd,
        discountVnd: current.discountVnd,
        totalAmountVnd: current.totalAmountVnd,
        trackingEvents: updatedEvents,
        cancelReason: reason ?? 'Hủy theo yêu cầu của phụ huynh',
      );
    }
  }

  /// Khởi tạo 6 đơn hàng mẫu phủ sóng tất cả các trạng thái
  static List<OrderModel> _buildInitialMockOrders() {
    final now = DateTime.now();

    return [
      // 1. Chờ xác nhận (pendingConfirmation) - Cho phép hủy
      OrderModel(
        id: 'ord_mock_1',
        orderCode: 'ORD-2026-9042',
        createdAt: now.subtract(const Duration(minutes: 45)),
        status: OrderStatus.pendingConfirmation,
        paymentStatus: PaymentStatus.pending,
        paymentMethodName: 'Chuyển khoản VietQR',
        items: const [
          OrderItemModel(
            id: 'item_1',
            kitName: 'Bộ Họa Cụ Nhí: Chinh Phục Thế Giới Màu Acrylic',
            thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 389000,
            courseId: 'course_acrylic_kids',
            courseTitle: 'Vẽ Acrylic cho bé 6–10 tuổi',
            kitItems: [
              'Hộp 12 tuýp màu Acrylic Pebeo Studio 20ml không độc hại',
              'Bộ 5 cọ đầu dẹt & cọ tỉa nét sợi mảnh cán gỗ',
              'Khay pha màu hoa cúc chống dính cao cấp',
              '3 khung tranh canvas vải bố cỡ 20x20cm có khung sườn',
              'Tạp dề chống bám bẩn in logo họa sĩ nhí ArtKids',
            ],
          ),
        ],
        shippingInfo: const ShippingInfoModel(
          recipientName: 'Nguyễn Văn Minh (Phụ huynh bé Bo)',
          phoneNumber: '0912 345 678',
          fullAddress: 'Số 48, Ngõ 12 Đặng Thai Mai, Phường Quảng An, Quận Tây Hồ, Hà Nội',
          carrierName: 'Giao Hàng Nhanh (GHN)',
        ),
        subtotalVnd: 389000,
        shippingFeeVnd: 25000,
        discountVnd: 25000, // Miễn phí ship đơn đầu
        totalAmountVnd: 389000,
        trackingEvents: [
          OrderTrackingEventModel(
            id: 'evt_1_1',
            title: 'Đặt hàng thành công',
            description: 'Đơn hàng được tiếp nhận vào hệ thống thương mại ArtKids.',
            timestamp: now.subtract(const Duration(minutes: 45)),
            isPassed: true,
            isCurrent: false,
          ),
          const OrderTrackingEventModel(
            id: 'evt_1_2',
            title: 'Chờ trung tâm xác nhận',
            description: 'Hệ thống đang tiến hành kiểm tra tình trạng hàng hóa và đối soát thanh toán.',
            isPassed: false,
            isCurrent: true,
          ),
          const OrderTrackingEventModel(
            id: 'evt_1_3',
            title: 'Xuất kho & đóng gói',
            description: 'Học cụ sẽ được bọc xốp chống sốc và đóng hộp niêm phong.',
            isPassed: false,
            isCurrent: false,
          ),
          const OrderTrackingEventModel(
            id: 'evt_1_4',
            title: 'Đang giao hàng',
            description: 'Bàn giao cho đơn vị vận chuyển giao tới phụ huynh.',
            isPassed: false,
            isCurrent: false,
          ),
          const OrderTrackingEventModel(
            id: 'evt_1_5',
            title: 'Giao thành công',
            description: 'Bé nhận hộp học cụ và bắt đầu trải nghiệm buổi học.',
            isPassed: false,
            isCurrent: false,
          ),
        ],
      ),

      // 2. Đang chuẩn bị (preparing)
      OrderModel(
        id: 'ord_mock_2',
        orderCode: 'ORD-2026-8875',
        createdAt: now.subtract(const Duration(hours: 14)),
        status: OrderStatus.preparing,
        paymentStatus: PaymentStatus.paid,
        paymentMethodName: 'Thanh toán trực tuyến VNPAY',
        items: const [
          OrderItemModel(
            id: 'item_2',
            kitName: 'Hộp Học Cụ Sáng Tạo: Khám Phá Rừng Xanh & Động Vật Hoang Dã',
            thumbnailUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 450000,
            courseId: 'course_wild_animals',
            courseTitle: 'Vẽ động vật bằng màu nước',
            kitItems: [
              'Hộp màu nước khô 24 màu Kuretake Nhật Bản',
              'Bút lông ngậm nước Waterbrush tiện lợi cho bé',
              'Tập giấy vẽ Fabriano 300gsm định lượng chuẩn 15 tờ',
              'Khay pha màu nhựa ABS an toàn thân thiện môi trường',
              'Băng dính giấy washi tape cố định viền tranh không rách giấy',
            ],
          ),
        ],
        shippingInfo: const ShippingInfoModel(
          recipientName: 'Trần Thị Thúy Hằng (Mẹ bé Sóc)',
          phoneNumber: '0988 776 655',
          fullAddress: 'Căn hộ 1508 Tòa S2.05 VinHomes Grand Park, TP. Thủ Đức, TP. Hồ Chí Minh',
          carrierName: 'Giao Hàng Tiết Kiệm (GHTK)',
        ),
        subtotalVnd: 450000,
        shippingFeeVnd: 30000,
        discountVnd: 50000,
        totalAmountVnd: 430000,
        trackingEvents: [
          OrderTrackingEventModel(
            id: 'evt_2_1',
            title: 'Đặt hàng thành công',
            description: 'Đã nhận thông tin đơn hàng và thanh toán VNPAY thành công.',
            timestamp: now.subtract(const Duration(hours: 14)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_2_2',
            title: 'Xác nhận đơn hàng',
            description: 'Tư vấn viên đã đối soát học viên và tiến hành gửi lệnh xuất kho.',
            timestamp: now.subtract(const Duration(hours: 10)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_2_3',
            title: 'Đang đóng gói tại kho',
            description: 'Nhân viên kho ArtKids đang kiểm kê chất lượng màu vẽ và đóng gói hộp bảo vệ.',
            timestamp: now.subtract(const Duration(hours: 2)),
            isPassed: false,
            isCurrent: true,
          ),
          const OrderTrackingEventModel(
            id: 'evt_2_4',
            title: 'Đang giao hàng',
            description: 'Chờ đơn vị vận chuyển tới kho lấy hàng.',
            isPassed: false,
            isCurrent: false,
          ),
          const OrderTrackingEventModel(
            id: 'evt_2_5',
            title: 'Giao thành công',
            description: 'Bé nhận trọn bộ học cụ tại nhà.',
            isPassed: false,
            isCurrent: false,
          ),
        ],
      ),

      // 3. Đang giao (shipping) - Có mã vận đơn, link tra cứu, nhiều sản phẩm
      OrderModel(
        id: 'ord_mock_3',
        orderCode: 'ORD-2026-8710',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        status: OrderStatus.shipping,
        paymentStatus: PaymentStatus.paid,
        paymentMethodName: 'Thẻ Quốc Tế Visa / Mastercard',
        items: const [
          OrderItemModel(
            id: 'item_3_1',
            kitName: 'Hộp Học Cụ: Hội Họa Cổ Tích & Lâu Đài Mộng Mơ',
            thumbnailUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 320000,
            courseId: 'course_fairy_tales',
            courseTitle: 'Hội họa cổ tích và thế giới kỳ diệu',
            kitItems: [
              'Bộ sáp dầu mỹ thuật Mungyo Gallery 36 màu sắc nét',
              'Tập giấy sáp đen & trắng A4 (20 tờ dày dặn)',
              'Cây tán chì và que gạt sáp dầu tạo hiệu ứng 3D',
              'Gọt bút chì 2 nấc chuyên nghiệp',
            ],
          ),
          OrderItemModel(
            id: 'item_3_2',
            kitName: 'Tập Giấy Vẽ Chuyên Dụng A3 Định Lượng 300gsm (50 tờ)',
            thumbnailUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 120000,
            kitItems: [
              '50 tờ giấy vân Cold Pressed 300gsm khổ A3',
              'Độ ngậm nước cao, không mục nát khi vẽ nhiều lớp',
            ],
          ),
        ],
        shippingInfo: ShippingInfoModel(
          recipientName: 'Lê Hoàng Nam (Phụ huynh bé Nhím)',
          phoneNumber: '0903 999 888',
          fullAddress: 'Số 120 Đường Nguyễn Hữu Thọ, Phường Phước Kiển, Huyện Nhà Bè, TP. Hồ Chí Minh',
          carrierName: 'Giao Hàng Nhanh (GHN)',
          trackingNumber: 'GHN-VN-8849204',
          trackingUrl: 'https://donhang.ghn.vn/?order_code=GHN-VN-8849204',
          estimatedDeliveryDate: now.add(const Duration(days: 1)),
        ),
        subtotalVnd: 440000,
        shippingFeeVnd: 28000,
        discountVnd: 0,
        totalAmountVnd: 468000,
        trackingEvents: [
          OrderTrackingEventModel(
            id: 'evt_3_1',
            title: 'Đặt hàng thành công',
            description: 'Đã thanh toán qua thẻ quốc tế.',
            timestamp: now.subtract(const Duration(days: 2, hours: 3)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_3_2',
            title: 'Xác nhận & Hoàn tất đóng gói',
            description: 'Đơn hàng được chuyển qua bộ phận vận chuyển.',
            timestamp: now.subtract(const Duration(days: 1, hours: 18)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_3_3',
            title: 'Xuất kho GHN Tân Bình',
            description: 'Bưu tá GHN đã lấy hàng và xuất khỏi trung tâm phân loại.',
            timestamp: now.subtract(const Duration(days: 1, hours: 6)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_3_4',
            title: 'Đang giao tới địa chỉ',
            description: 'Bưu tá Nguyễn Quốc Bảo (0902.xxx.xxx) đang trên đường giao.',
            timestamp: now.subtract(const Duration(hours: 3)),
            isPassed: false,
            isCurrent: true,
          ),
          const OrderTrackingEventModel(
            id: 'evt_3_5',
            title: 'Giao thành công',
            description: 'Dự kiến giao trong ngày mai.',
            isPassed: false,
            isCurrent: false,
          ),
        ],
      ),

      // 4. Đã giao (delivered) - Đơn 1: Kit VIP theo quý
      OrderModel(
        id: 'ord_mock_4',
        orderCode: 'ORD-2026-8432',
        createdAt: now.subtract(const Duration(days: 10)),
        status: OrderStatus.delivered,
        orderType: OrderType.subscription,
        paymentStatus: PaymentStatus.paid,
        paymentMethodName: 'Chuyển khoản VietQR',
        items: const [
          OrderItemModel(
            id: 'item_4',
            kitName: 'Hộp Học Cụ VIP: Họa Sĩ Nhí Toàn Năng (Định Kỳ Quý 1)',
            thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 599000,
            courseId: 'course_pro_artist',
            courseTitle: 'Học vẽ cơ bản đa chất liệu cho bé 5–8 tuổi',
            kitItems: [
              'Hộp màu sáp dầu 48 màu sắc tố cao cấp',
              'Bút chì phác thảo 2B, 4B chuyên dụng',
              'Gôm đất sét tẩy mềm không để lại vụn chì',
              'Bảng vẽ gỗ kẹp giấy kích thước A3 tiện dụng',
              'Sách bài tập thực hành vẽ tranh từng bước có video hướng dẫn',
            ],
          ),
        ],
        shippingInfo: ShippingInfoModel(
          recipientName: 'Đặng Minh Khôi',
          phoneNumber: '0977 123 456',
          fullAddress: 'Số 18 Lý Thường Kiệt, Phường Hàng Bài, Quận Hoàn Kiếm, Hà Nội',
          carrierName: 'Viettel Post',
          trackingNumber: 'VTPOST-993812044',
          trackingUrl: 'https://viettelpost.com.vn/tra-cuu-hanh-trinh-don/?billcode=VTPOST-993812044',
          estimatedDeliveryDate: now.subtract(const Duration(days: 6)),
        ),
        subtotalVnd: 599000,
        shippingFeeVnd: 35000,
        discountVnd: 35000,
        totalAmountVnd: 599000,
        trackingEvents: [
          OrderTrackingEventModel(
            id: 'evt_4_1',
            title: 'Đặt hàng thành công',
            description: 'Đã hoàn tất thanh toán VietQR.',
            timestamp: now.subtract(const Duration(days: 10)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_4_2',
            title: 'Xác nhận đơn hàng',
            description: 'Bộ phận chăm sóc khách hàng đã duyệt đơn.',
            timestamp: now.subtract(const Duration(days: 9)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_4_3',
            title: 'Xuất kho tổng Viettel Post',
            description: 'Đơn hàng rời kho ArtKids.',
            timestamp: now.subtract(const Duration(days: 8)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_4_4',
            title: 'Đang giao hàng',
            description: 'Bưu tá Viettel Post liên hệ phát hàng.',
            timestamp: now.subtract(const Duration(days: 6, hours: 4)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_4_5',
            title: 'Giao hàng thành công',
            description: 'Khách hàng Đặng Minh Khôi đã ký nhận hộp học cụ.',
            timestamp: now.subtract(const Duration(days: 6)),
            isPassed: true,
            isCurrent: true,
          ),
        ],
      ),

      // 5. Đã giao (delivered) - Đơn 2: COD
      OrderModel(
        id: 'ord_mock_5',
        orderCode: 'ORD-2026-8109',
        createdAt: now.subtract(const Duration(days: 22)),
        status: OrderStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paymentMethodName: 'Thanh toán khi nhận hàng (COD)',
        items: const [
          OrderItemModel(
            id: 'item_5',
            kitName: 'Bộ Đất Nặn Điêu Khắc Mô Hình 3D Đa Sắc Siêu Nhẹ',
            thumbnailUrl: 'https://images.unsplash.com/photo-1560421683-6856ea585c78?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 280000,
            courseId: 'course_clay_modeling',
            courseTitle: 'Nặn tượng 3D & Sáng tạo sinh vật kỳ thú',
            kitItems: [
              'Hộp 18 màu đất sét tự khô siêu nhẹ chuẩn Nhật Bản',
              'Bộ 4 dao tạo hình chi tiết bằng gỗ mài mịn',
              'Khung kẽm định hình bộ xương chuyển động',
              'Lọ sơn bóng bảo vệ bề mặt thành phẩm bền màu',
            ],
          ),
        ],
        shippingInfo: ShippingInfoModel(
          recipientName: 'Vũ Hải Yến',
          phoneNumber: '0933 222 111',
          fullAddress: 'Số 85 Đường 30/4, Phường Hòa Cường Bắc, Quận Hải Châu, Đà Nẵng',
          carrierName: 'Giao Hàng Nhanh (GHN)',
          trackingNumber: 'GHN-VN-7711200',
          trackingUrl: 'https://donhang.ghn.vn/?order_code=GHN-VN-7711200',
          estimatedDeliveryDate: now.subtract(const Duration(days: 18)),
        ),
        subtotalVnd: 280000,
        shippingFeeVnd: 25000,
        discountVnd: 0,
        totalAmountVnd: 305000,
        trackingEvents: [
          OrderTrackingEventModel(
            id: 'evt_5_1',
            title: 'Đặt hàng thành công',
            description: 'Đăng ký hình thức thanh toán COD.',
            timestamp: now.subtract(const Duration(days: 22)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_5_2',
            title: 'Xác nhận đơn hàng',
            description: 'Điện thoại xác nhận địa chỉ và số tiền thu hộ.',
            timestamp: now.subtract(const Duration(days: 21)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_5_3',
            title: 'Xuất kho GHN Đà Nẵng',
            description: 'Hàng đã cập bến bưu cục phân phát.',
            timestamp: now.subtract(const Duration(days: 19)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_5_4',
            title: 'Đang giao hàng',
            description: 'Phát hàng thu tiền COD.',
            timestamp: now.subtract(const Duration(days: 18, hours: 3)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_5_5',
            title: 'Giao hàng & Thu tiền thành công',
            description: 'Người nhận đã nhận hàng và thanh toán đủ 305.000 đ.',
            timestamp: now.subtract(const Duration(days: 18)),
            isPassed: true,
            isCurrent: true,
          ),
        ],
      ),

      // 6. Đã hủy (cancelled) - Hiển thị lý do hủy
      OrderModel(
        id: 'ord_mock_6',
        orderCode: 'ORD-2026-7915',
        createdAt: now.subtract(const Duration(days: 30)),
        status: OrderStatus.cancelled,
        paymentStatus: PaymentStatus.pending,
        paymentMethodName: 'Chuyển khoản VietQR',
        items: const [
          OrderItemModel(
            id: 'item_6',
            kitName: 'Bộ Cọ Vẽ Nghệ Thuật 12 Cây Cao Cấp Cho Trẻ Em',
            thumbnailUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=500&auto=format&fit=crop&q=60',
            quantity: 1,
            unitPriceVnd: 210000,
            courseId: 'course_brush_skills',
            courseTitle: 'Kỹ thuật cọ vẽ và loang màu nâng cao',
            kitItems: [
              'Bộ 12 cọ lông tự nhiên mềm mại không rụng lông',
              'Bao cuộn cọ vải canvas phong cách Nhật Bản',
              'Xà phòng thảo mộc chuyên dụng dưỡng lông cọ',
            ],
          ),
        ],
        shippingInfo: const ShippingInfoModel(
          recipientName: 'Ngô Thanh Sơn',
          phoneNumber: '0918 555 444',
          fullAddress: 'Số 54 Lê Duẩn, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
          carrierName: 'Giao Hàng Nhanh (GHN)',
        ),
        subtotalVnd: 210000,
        shippingFeeVnd: 20000,
        discountVnd: 0,
        totalAmountVnd: 230000,
        cancelReason: 'Phụ huynh hủy đơn do bé đã có sẵn bộ cọ tương tự tại nhà.',
        trackingEvents: [
          OrderTrackingEventModel(
            id: 'evt_6_1',
            title: 'Đặt hàng thành công',
            description: 'Đơn hàng được tạo thành công.',
            timestamp: now.subtract(const Duration(days: 30)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_6_2',
            title: 'Chờ xác nhận',
            description: 'Hệ thống chuẩn bị phân bổ đơn đến kho.',
            timestamp: now.subtract(const Duration(days: 29, hours: 22)),
            isPassed: true,
            isCurrent: false,
          ),
          OrderTrackingEventModel(
            id: 'evt_6_3',
            title: 'Đã hủy đơn',
            description: 'Lý do: Phụ huynh hủy đơn do bé đã có sẵn bộ cọ tương tự tại nhà.',
            timestamp: now.subtract(const Duration(days: 29, hours: 20)),
            isPassed: true,
            isCurrent: true,
            cancelReason: 'Phụ huynh hủy đơn do bé đã có sẵn bộ cọ tương tự tại nhà.',
          ),
        ],
      ),
    ];
  }
}

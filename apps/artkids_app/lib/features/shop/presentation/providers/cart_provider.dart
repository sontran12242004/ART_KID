import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/models/voucher.dart';

/// StateNotifier quản lý danh sách sản phẩm trong giỏ hàng phiên làm việc
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  /// Thêm sản phẩm vào giỏ hàng (nếu đã có thì tăng số lượng)
  void addToCart(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;

    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      // Đã có trong giỏ -> tăng số lượng
      final current = state[index];
      final updatedList = List<CartItem>.from(state);
      updatedList[index] = current.copyWith(
        quantity: current.quantity + quantity,
      );
      state = updatedList;
    } else {
      // Chưa có trong giỏ -> thêm mới vào đầu danh sách
      state = [
        CartItem(product: product, quantity: quantity),
        ...state,
      ];
    }
  }

  /// Cập nhật số lượng của một sản phẩm trong giỏ
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
  }

  /// Tăng số lượng sản phẩm lên 1
  void incrementQuantity(String productId) {
    final item = state.firstWhere(
      (e) => e.product.id == productId,
      orElse: () => throw Exception('Không tìm thấy sản phẩm trong giỏ'),
    );
    updateQuantity(productId, item.quantity + 1);
  }

  /// Giảm số lượng sản phẩm đi 1 (nếu về 0 sẽ tự động xóa)
  void decrementQuantity(String productId) {
    final item = state.firstWhere(
      (e) => e.product.id == productId,
      orElse: () => throw Exception('Không tìm thấy sản phẩm trong giỏ'),
    );
    updateQuantity(productId, item.quantity - 1);
  }

  /// Xóa hẳn 1 sản phẩm ra khỏi giỏ hàng
  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Xóa toàn bộ giỏ hàng (thường gọi sau khi đặt hàng thành công)
  void clearCart() {
    state = const [];
  }
}

/// Provider cung cấp StateNotifier giỏ hàng
final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// Provider tính tổng số lượng món hàng trong giỏ (dùng cho badge icon trên AppBar)
final cartTotalCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, item) => sum + item.quantity);
});

/// Provider tính tổng tiền tạm tính của giỏ hàng (VNĐ)
final cartSubtotalVndProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, item) => sum + item.totalPriceVnd);
});

/// Provider lưu trữ voucher đang được áp dụng trong phiên thanh toán hiện tại
final appliedVoucherProvider = StateProvider<Voucher?>((ref) => null);

/// Provider tính số tiền giảm giá từ voucher (VNĐ)
/// Tự động cập nhật lại mỗi khi giỏ hàng hoặc voucher thay đổi.
/// Nếu giá trị giỏ hàng giảm xuống dưới minOrderAmount của voucher, số tiền giảm sẽ tự động về 0.
final cartDiscountVndProvider = Provider<int>((ref) {
  final voucher = ref.watch(appliedVoucherProvider);
  final subtotal = ref.watch(cartSubtotalVndProvider);

  if (voucher == null || subtotal <= 0) {
    return 0;
  }

  // Đơn hàng chưa đạt mức tối thiểu của voucher -> Không giảm
  if (subtotal < voucher.minOrderAmount) {
    return 0;
  }

  // Tính số tiền giảm theo loại voucher (percentage hoặc fixedAmount)
  return voucher.calculateDiscount(subtotal);
});

/// Provider tính phí vận chuyển GHN tiêu chuẩn (miễn phí nếu tạm tính >= 300.000 đ hoặc giỏ hàng trống)
final cartShippingFeeVndProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalVndProvider);
  const freeShippingThreshold = 300000;
  const standardFee = 25000;
  if (subtotal == 0 || subtotal >= freeShippingThreshold) {
    return 0;
  }
  return standardFee;
});

/// Provider tính tổng số tiền thanh toán cuối cùng (VNĐ)
/// = Tạm tính + Phí vận chuyển - Giảm giá voucher (không thể âm)
final cartFinalTotalVndProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalVndProvider);
  final shippingFee = ref.watch(cartShippingFeeVndProvider);
  final discount = ref.watch(cartDiscountVndProvider);

  final total = subtotal + shippingFee - discount;
  return total < 0 ? 0 : total;
});

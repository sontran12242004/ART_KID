import 'package:equatable/equatable.dart';

import 'product.dart';

/// Model 1 dòng sản phẩm trong giỏ hàng (sản phẩm + số lượng mua)
class CartItem extends Equatable {
  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Thông tin sản phẩm
  final Product product;

  /// Số lượng đặt mua
  final int quantity;

  /// Tổng tiền của dòng này
  int get totalPriceVnd => product.priceVnd * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

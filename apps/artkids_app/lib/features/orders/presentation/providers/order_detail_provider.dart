import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';
import 'orders_list_provider.dart';

/// Provider lấy chi tiết 1 đơn hàng theo ID
final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderEntity, String>((ref, orderId) async {
      final repository = ref.watch(orderRepositoryProvider);
      return repository.getOrderById(orderId);
    });

/// Controller xử lý các tác vụ trên đơn hàng (Hủy đơn, Đánh giá, v.v.)
final orderActionControllerProvider =
    StateNotifierProvider<OrderActionController, AsyncValue<void>>((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      return OrderActionController(repository, ref);
    });

class OrderActionController extends StateNotifier<AsyncValue<void>> {
  OrderActionController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  final OrderRepository _repository;
  final Ref _ref;

  /// Hủy đơn hàng và làm mới state
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelOrder(orderId, reason: reason);
      // Invalidate detail để load lại trạng thái đã hủy
      _ref.invalidate(orderDetailProvider(orderId));
      // Invalidate list để cập nhật badge ở danh sách
      _ref.invalidate(ordersListProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

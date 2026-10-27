import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';

/// Các tab lọc trạng thái của màn hình danh sách đơn hàng
enum OrderListFilter {
  all(label: 'Tất cả', apiStatus: 'all'),
  processing(label: 'Đang xử lý', apiStatus: 'processing'),
  delivered(label: 'Đã giao', apiStatus: 'delivered'),
  cancelled(label: 'Đã hủy', apiStatus: 'cancelled');

  const OrderListFilter({required this.label, required this.apiStatus});
  final String label;
  final String apiStatus;
}

/// Provider lưu giữ bộ lọc tab hiện tại
final selectedOrderFilterProvider = StateProvider<OrderListFilter>((ref) {
  return OrderListFilter.all;
});

/// State của danh sách đơn hàng (hỗ trợ phân trang)
class OrdersListState extends Equatable {
  const OrdersListState({
    this.orders = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<OrderEntity> orders;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  OrdersListState copyWith({
    List<OrderEntity>? orders,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return OrdersListState(
      orders: orders ?? this.orders,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [orders, page, hasMore, isLoadingMore];
}

/// Notifier quản lý danh sách đơn hàng, phân trang và tải thêm
class OrdersListNotifier extends StateNotifier<AsyncValue<OrdersListState>> {
  OrdersListNotifier(this._repository, this._filter)
    : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final OrderRepository _repository;
  final OrderListFilter _filter;
  static const int _pageSize = 10;

  /// Tải dữ liệu trang đầu tiên
  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _repository.getOrders(
        status: _filter.apiStatus,
        page: 1,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        OrdersListState(
          orders: orders,
          page: 1,
          hasMore: orders.length >= _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Làm mới danh sách (Pull to refresh)
  Future<void> refresh() async {
    try {
      final orders = await _repository.getOrders(
        status: _filter.apiStatus,
        page: 1,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        OrdersListState(
          orders: orders,
          page: 1,
          hasMore: orders.length >= _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Tải trang tiếp theo (Infinite Scroll)
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.page + 1;
      final newOrders = await _repository.getOrders(
        status: _filter.apiStatus,
        page: nextPage,
        limit: _pageSize,
      );

      final mergedOrders = List<OrderEntity>.from(currentState.orders)
        ..addAll(newOrders);

      state = AsyncValue.data(
        OrdersListState(
          orders: mergedOrders,
          page: nextPage,
          hasMore: newOrders.length >= _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // Nếu lỗi tải trang tiếp, chỉ tắt loadingMore
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }
}

/// Provider danh sách đơn hàng phụ thuộc vào filter đang chọn
final ordersListProvider =
    StateNotifierProvider.autoDispose<
      OrdersListNotifier,
      AsyncValue<OrdersListState>
    >((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      final filter = ref.watch(selectedOrderFilterProvider);
      return OrdersListNotifier(repository, filter);
    });

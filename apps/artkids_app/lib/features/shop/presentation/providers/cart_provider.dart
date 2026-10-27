import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/session_store.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/models/voucher.dart';

final cartSyncErrorProvider = StateProvider<String?>((ref) => null);

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier([this.dio, this.report]) : super(const []);
  final Dio? dio;
  final void Function(String?)? report;
  Future<void> _pending = Future.value();
  void _accept(dynamic json) {
    if (mounted) {
      state = apiList((json as Map)['items'])
          .map(
            (v) => CartItem(
              product: Product.fromJson(
                apiProduct(v['product'], baseUrl: dio?.options.baseUrl),
              ),
              quantity: (v['quantity'] as num).toInt(),
            ),
          )
          .toList();
    }
  }

  Future<bool> _run(Future<void> Function() work) async {
    var success = false;
    final operation = _pending.then((_) async {
      if (!mounted) return;
      try {
        report?.call(null);
        await work();
        success = true;
      } catch (e) {
        report?.call(apiError(e));
      }
    });
    _pending = operation;
    await operation;
    return success;
  }

  Future<bool> load() => _run(() async {
    if (dio != null) _accept((await dio!.get('/commerce/cart')).data);
  });
  Future<bool> addToCart(Product product, {int quantity = 1}) => _run(() async {
    final current = state.where((x) => x.product.id == product.id).firstOrNull;
    final value = (current?.quantity ?? 0) + quantity;
    if (dio != null) {
      _accept(
        (await dio!.put(
          '/commerce/cart/items',
          data: {'productId': product.id, 'quantity': value},
        )).data,
      );
    } else if (mounted) {
      state = [
        CartItem(product: product, quantity: value),
        ...state.where((x) => x.product.id != product.id),
      ];
    }
  });
  Future<bool> updateQuantity(String productId, int quantity) => _run(() async {
    if (dio != null) {
      _accept(
        (await dio!.put(
          '/commerce/cart/items',
          data: {'productId': productId, 'quantity': quantity.clamp(0, 99)},
        )).data,
      );
    } else if (mounted) {
      state = state
          .where((i) => i.product.id != productId || quantity > 0)
          .map(
            (i) =>
                i.product.id == productId ? i.copyWith(quantity: quantity) : i,
          )
          .toList();
    }
  });
  Future<bool> _changeQuantity(String id, int delta) => _run(() async {
    final current = state.where((i) => i.product.id == id).firstOrNull;
    if (current == null) return;
    final quantity = (current.quantity + delta).clamp(0, 99);
    if (dio != null) {
      _accept(
        (await dio!.put(
          '/commerce/cart/items',
          data: {'productId': id, 'quantity': quantity},
        )).data,
      );
    } else if (mounted) {
      state = state
          .where((i) => i.product.id != id || quantity > 0)
          .map((i) => i.product.id == id ? i.copyWith(quantity: quantity) : i)
          .toList();
    }
  });
  Future<bool> incrementQuantity(String id) => _changeQuantity(id, 1);
  Future<bool> decrementQuantity(String id) => _changeQuantity(id, -1);
  Future<bool> removeFromCart(String id) => updateQuantity(id, 0);
  void clearCart() {
    state = const [];
  }

  Future<bool> clearRemote() async {
    final ids = state.map((item) => item.product.id).toList();
    for (final id in ids) {
      if (!await removeFromCart(id)) return false;
    }
    return true;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final id = ref.watch(sessionStoreProvider.select((s) => s.userId));
  final notifier = CartNotifier(
    ref.watch(dioProvider),
    (error) => ref.read(cartSyncErrorProvider.notifier).state = error,
  );
  if (id != null) Future.microtask(notifier.load);
  return notifier;
});
final cartTotalCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity),
);
final cartSubtotalVndProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (s, i) => s + i.totalPriceVnd),
);
final appliedVoucherProvider = StateProvider<Voucher?>((ref) {
  ref.watch(sessionStoreProvider.select((s) => s.userId));
  return null;
});
final cartDiscountVndProvider = Provider<int>((ref) {
  final v = ref.watch(appliedVoucherProvider);
  return v?.calculateDiscount(ref.watch(cartSubtotalVndProvider)) ?? 0;
});
final cartShippingFeeVndProvider = Provider<int>((ref) {
  final s = ref.watch(cartSubtotalVndProvider);
  return s == 0 || s >= 300000 ? 0 : 30000;
});
final cartFinalTotalVndProvider = Provider<int>(
  (ref) =>
      (ref.watch(cartSubtotalVndProvider) +
              ref.watch(cartShippingFeeVndProvider) -
              ref.watch(cartDiscountVndProvider))
          .clamp(0, 1 << 60)
          .toInt(),
);

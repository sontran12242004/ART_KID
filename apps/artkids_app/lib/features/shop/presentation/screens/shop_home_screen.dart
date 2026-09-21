import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../providers/shop_catalog_provider.dart';
import '../widgets/cart_badge_icon.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/product_grid_card.dart';

/// Màn hình chính Cửa Hàng Học Cụ (Shop) — Parent Mode
class ShopHomeScreen extends ConsumerStatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  ConsumerState<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends ConsumerState<ShopHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(shopCatalogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F3B46), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Cửa Hàng Học Cụ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F3B46),
          ),
        ),
        actions: const [
          CartBadgeIcon(),
          SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm + Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              children: [
                // Ô tìm kiếm sản phẩm
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm kit học cụ, màu vẽ, cọ, giấy...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF95A5A6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7F8C8D),
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(productSearchQueryProvider.notifier)
                                    .state = '';
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(productSearchQueryProvider.notifier).state = val;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),

          // Chips danh mục ngang
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: const CategoryFilterChips(),
          ),

          const Divider(height: 1, color: Color(0xFFE8ECEF)),

          // Gridview danh sách sản phẩm
          Expanded(
            child: catalogAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: const Color(0xFF1687A7),
                  onRefresh: () async {
                    ref.invalidate(shopCatalogProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductGridCard(
                        product: product,
                        onTap: () {
                          context.push(
                            RoutePaths.parentShopProductDetail
                                .replaceFirst(':productId', product.id),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => _buildSkeletonLoading(),
              error: (error, _) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE2F3F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Color(0xFF1687A7),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không tìm thấy sản phẩm phù hợp',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F3B46),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vui lòng thử tìm kiếm bằng từ khóa khác hoặc chọn danh mục "Tất cả".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1687A7),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Đặt lại bộ lọc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _searchController.clear();
                ref.read(productSearchQueryProvider.notifier).state = '';
                ref.invalidate(shopCatalogProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEFF1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFECEFF1),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFE53935)),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải danh mục sản phẩm',
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
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1687A7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => ref.invalidate(shopCatalogProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

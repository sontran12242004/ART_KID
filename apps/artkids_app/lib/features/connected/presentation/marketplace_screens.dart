import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import 'course_product_screens.dart';
import 'widgets.dart';

class MarketplaceListingsScreen extends ConsumerStatefulWidget {
  const MarketplaceListingsScreen({super.key, this.review = false});
  final bool review;
  @override
  ConsumerState<MarketplaceListingsScreen> createState() => _ListingsState();
}

class _ListingsState extends ConsumerState<MarketplaceListingsScreen> {
  int _page = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.review ? 'Duyệt học cụ' : 'Học cụ của tôi'),
    ),
    floatingActionButton: widget.review
        ? null
        : FloatingActionButton.extended(
            onPressed: () => context.push('/staff/marketplace/new'),
            icon: const Icon(Icons.add),
            label: const Text('Đăng học cụ'),
          ),
    body: ApiView(
      path:
          '/marketplace/${widget.review ? 'reviews' : 'listings'}?page=$_page&pageSize=20',
      builder: (data) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if ((data['items'] as List).isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.review
                    ? 'Không có học cụ chờ duyệt.'
                    : 'Bạn chưa đăng học cụ. Chọn Đăng học cụ để bắt đầu.',
              ),
            ),
          for (final p in data['items'])
            Card(
              child: ListTile(
                title: Text(p['name']),
                subtitle: Text(
                  '${money(p['priceVnd'])} · ${listingStatus(p['approvalStatus'])}\n${p['isAvailable'] == true ? 'Còn hàng' : 'Hết hàng'}${p['rejectionReason'] == null ? '' : '\nLý do từ chối: ${p['rejectionReason']}'}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  widget.review
                      ? '/staff/marketplace/reviews/${p['id']}'
                      : '/staff/marketplace/listings/${p['id']}',
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Trang trước',
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Trang $_page'),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: _page * 20 < (data['total'] as int)
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class MarketplaceListingDetail extends ConsumerWidget {
  const MarketplaceListingDetail({
    super.key,
    required this.id,
    this.review = false,
  });
  final String id;
  final bool review;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(review ? 'Chi tiết duyệt học cụ' : 'Chi tiết học cụ'),
    ),
    body: ApiView(
      path: '/marketplace/${review ? 'reviews' : 'listings'}/$id',
      builder: (raw) {
        final p = Map<String, dynamic>.from(raw);
        if (!review) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  children: [
                    ActionButton(
                      label: 'Đổi còn / hết hàng và gửi duyệt',
                      action: (r) => r
                          .read(dioProvider)
                          .put(
                            '/marketplace/listings/$id/availability',
                            data: {
                              'isAvailable': p['isAvailable'] != true,
                              'expectedRevision': p['revision'],
                            },
                          ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final ok = await confirm(
                          context,
                          'Gỡ học cụ',
                          'Gỡ học cụ khỏi cửa hàng? Lịch sử đơn hàng vẫn được giữ lại.',
                        );
                        if (!ok || !context.mounted) return;
                        final saved = await mutate(
                          context,
                          ref,
                          '/marketplace/listings/$id',
                          {},
                          method: 'DELETE',
                        );
                        if (saved && context.mounted) context.pop();
                      },
                      child: const Text('Gỡ học cụ'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CourseProductPublishScreen(
                  product: p,
                  courseId: p['courseId'] as String?,
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PrivateImage(
              assetId: Uri.parse(p['thumbnailUrl'] as String).pathSegments.last,
            ),
            const SizedBox(height: 16),
            Text(p['name'], style: Theme.of(context).textTheme.headlineSmall),
            Text(money(p['priceVnd'])),
            Text(p['description']),
            Text('Người bán: ${p['createdBy']}'),
            Text(
              p['courseId'] == null
                  ? 'Dụng cụ bán độc lập'
                  : 'Khóa học: ${p['courseId']}',
            ),
            Text(p['isAvailable'] == true ? 'Còn hàng' : 'Hết hàng'),
            Text('Trạng thái: ${listingStatus(p['approvalStatus'])}'),
            if (p['rejectionReason'] != null)
              Text('Lý do từ chối: ${p['rejectionReason']}'),
            const SizedBox(height: 16),
            if (p['approvalStatus'] == 'pending') ...[
              ActionButton(
                label: 'Phê duyệt',
                action: (r) => r
                    .read(dioProvider)
                    .post(
                      '/marketplace/reviews/$id',
                      data: {
                        'status': 'approved',
                        'expectedRevision': p['revision'],
                      },
                    ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final values = await askFields(context, 'Từ chối học cụ', [
                    const EntryField('reason', 'Lý do từ chối'),
                  ]);
                  if (values == null || !context.mounted) return;
                  await mutate(context, ref, '/marketplace/reviews/$id', {
                    ...values,
                    'status': 'rejected',
                    'expectedRevision': p['revision'],
                  }, success: 'Đã từ chối và gửi lý do cho giảng viên.');
                },
                child: const Text('Từ chối và gửi lý do'),
              ),
            ],
          ],
        );
      },
    ),
  );
}

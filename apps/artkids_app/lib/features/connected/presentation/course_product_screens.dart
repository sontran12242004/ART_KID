import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../../shop/presentation/providers/shop_catalog_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/connected_api.dart';
import 'widgets.dart';

class CourseProductPublishScreen extends ConsumerStatefulWidget {
  const CourseProductPublishScreen({
    super.key,
    this.courseId,
    this.product,
    this.onSaved,
  });
  final String? courseId;
  final Map<String, dynamic>? product;
  final VoidCallback? onSaved;

  @override
  ConsumerState<CourseProductPublishScreen> createState() =>
      _CourseProductPublishState();
}

class _CourseProductPublishState
    extends ConsumerState<CourseProductPublishScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  bool _available = true;
  String? _courseId;
  Uint8List? _image;
  String _filename = 'product.png';
  String? _assetId;
  bool _busy = false;
  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseId;
    final product = widget.product;
    if (product != null) {
      _title.text = product['name'] as String;
      _price.text = '${product['priceVnd']}';
      _description.text = product['description'] as String;
      _available = product['isAvailable'] as bool? ?? true;
      _courseId = product['courseId'] as String?;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        throw Exception('Vui lòng chọn ảnh nhỏ hơn 20 MB.');
      }
      if (!mounted) return;
      setState(() {
        _image = bytes;
        _filename = file.name;
        _assetId = null;
      });
    } catch (error) {
      if (mounted) toast(context, apiError(error), error: true);
    }
  }

  Future<void> _publish() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_image == null && !_editing) {
      toast(context, 'Vui lòng chọn hình ảnh học cụ.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final dio = ref.read(dioProvider);
      if (_assetId == null && _image != null) {
        final media = await dio.post(
          '/media/upload',
          data: FormData.fromMap({
            'kind': 'product_image',
            'file': MultipartFile.fromBytes(_image!, filename: _filename),
          }),
        );
        _assetId = media.data['id'] as String;
      }
      await dio.request(
        '/marketplace/listings${_editing ? '/${widget.product!['id']}' : ''}',
        options: Options(method: _editing ? 'PUT' : 'POST'),
        data: {
          'name': _title.text.trim(),
          'priceVnd': int.parse(_price.text.trim()),
          'description': _description.text.trim(),
          if (_assetId != null) 'imageAssetId': _assetId,
          'courseId': _courseId,
          'isAvailable': _available,
          if (_editing) 'expectedRevision': widget.product!['revision'],
        },
      );
      if (!mounted) return;
      ref.invalidate(apiDataProvider);
      ref.invalidate(shopCatalogProvider);
      ref.invalidate(productDetailProvider);
      toast(context, 'Đã gửi học cụ để quản trị viên duyệt.');
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/staff');
      }
    } catch (error) {
      if (mounted) toast(context, apiError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? 'Chỉnh sửa học cụ' : 'Đăng bán học cụ'),
      leading: widget.onSaved == null
          ? null
          : IconButton(
              tooltip: 'Đóng chỉnh sửa',
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Mọi thay đổi đều cần quản trị viên duyệt trước khi hiển thị. Bạn tự chuẩn bị hàng và sắp xếp vận chuyển.',
              ),
              if (_editing) ...[
                Text(
                  'Trạng thái: ${listingStatus(widget.product!['approvalStatus'])}',
                ),
                if (widget.product!['rejectionReason'] != null)
                  Text('Lý do từ chối: ${widget.product!['rejectionReason']}'),
              ],
              ApiView(
                path: '/courses?pageSize=100',
                builder: (data) {
                  final courses = (data['items'] as List)
                      .where(
                        (c) =>
                            c['instructorId'] ==
                            ref.watch(authProvider).currentUser?.id,
                      )
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: courses.any((c) => c['id'] == _courseId)
                        ? _courseId
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Loại học cụ / khóa học',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Dụng cụ bán độc lập'),
                      ),
                      for (final c in courses)
                        DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text(
                            c['title'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(
                            () => _courseId = value == '' ? null : value,
                          ),
                    hint: const Text('Dụng cụ bán độc lập'),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _image!,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Ảnh không hợp lệ. Hãy chọn PNG hoặc JPEG.',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_image == null &&
                  _editing &&
                  (widget.product!['thumbnailUrl'] as String? ?? '')
                      .isNotEmpty) ...[
                PrivateImage(
                  assetId: Uri.parse(
                    widget.product!['thumbnailUrl'] as String,
                  ).pathSegments.last,
                  height: 200,
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _image == null ? 'Chọn hình ảnh học cụ' : 'Thay hình ảnh',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                enabled: !_busy,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề học cụ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tiêu đề.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá bán (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final price = int.tryParse(value?.trim() ?? '');
                  return price == null || price < 1 || price > 100000000
                      ? 'Nhập giá nguyên từ 1 đến 100.000.000 VNĐ.'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                minLines: 4,
                maxLines: 8,
                maxLength: 10000,
                decoration: const InputDecoration(
                  labelText: 'Mô tả công dụng',
                  hintText:
                      'Học cụ gồm những gì, dùng để làm gì và hỗ trợ bài học nào?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng mô tả công dụng học cụ.'
                    : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Còn hàng'),
                subtitle: Text(
                  _available
                      ? 'Có thể nhận đơn sau khi được duyệt'
                      : 'Hết hàng',
                ),
                value: _available,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _available = value),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _busy ? null : _publish,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.storefront),
                label: Text(
                  _busy
                      ? 'Đang lưu…'
                      : _editing
                      ? 'Gửi duyệt lại'
                      : 'Gửi duyệt',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showCourseProductsDialog(
  BuildContext context,
  String courseId,
  String courseTitle,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 760,
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: CourseProductsManager(
          courseId: courseId,
          courseTitle: courseTitle,
        ),
      ),
    ),
  );
}

class CourseProductsManager extends ConsumerStatefulWidget {
  const CourseProductsManager({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });
  final String courseId;
  final String courseTitle;

  @override
  ConsumerState<CourseProductsManager> createState() =>
      _CourseProductsManagerState();
}

class _CourseProductsManagerState extends ConsumerState<CourseProductsManager> {
  String? _deletingId;

  Future<void> _delete(Map<String, dynamic> product) async {
    if (_deletingId != null) return;
    final approved = await confirm(
      context,
      'Xóa học cụ',
      'Xóa "${product['name']}" khỏi cửa hàng? Các đơn hàng đã đặt vẫn được giữ lại.',
    );
    if (!approved || !mounted) return;
    setState(() => _deletingId = product['id'] as String);
    try {
      await ref
          .read(dioProvider)
          .delete('/marketplace/listings/${product['id']}');
      if (!mounted) return;
      ref.invalidate(apiDataProvider);
      ref.invalidate(shopCatalogProvider);
      ref.invalidate(productDetailProvider);
      toast(context, 'Đã xóa học cụ.');
    } catch (error) {
      if (mounted) toast(context, apiError(error), error: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _edit(Map<String, dynamic> entry) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (editorContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 700,
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: CourseProductPublishScreen(
            courseId: widget.courseId,
            product: Map<String, dynamic>.from(entry['product']),
            onSaved: () => Navigator.of(editorContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Học cụ liên quan · ${widget.courseTitle}',
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Đóng danh sách học cụ',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ApiView(
          path:
              '/marketplace/listings?courseId=${widget.courseId}&pageSize=100',
          builder: (data) {
            final entries = (data['items'] as List)
                .map((p) => {'product': p})
                .toList();
            if (entries.isEmpty) {
              return const Center(
                child: Text('Khóa học chưa có học cụ đang bán.'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final raw in entries)
                  Builder(
                    builder: (context) {
                      final entry = Map<String, dynamic>.from(raw);
                      final product = Map<String, dynamic>.from(
                        entry['product'],
                      );
                      final imageUrl = product['thumbnailUrl'] as String? ?? '';
                      return Card(
                        key: ValueKey(product['id']),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    SizedBox(
                                      width: 96,
                                      child: PrivateImage(
                                        assetId: Uri.parse(
                                          imageUrl,
                                        ).pathSegments.last,
                                        height: 96,
                                      ),
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          money(product['priceVnd']),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${product['isAvailable'] == true ? 'Còn hàng' : 'Hết hàng'} · ${listingStatus(product['approvalStatus'])}',
                                        ),
                                        if (product['rejectionReason'] != null)
                                          Text(
                                            'Lý do từ chối: ${product['rejectionReason']}',
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Công dụng',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(product['description']),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _deletingId != null
                                        ? null
                                        : () => _edit(entry),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Chỉnh sửa học cụ'),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    onPressed: _deletingId != null
                                        ? null
                                        : () => _delete(product),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(
                                      _deletingId == product['id']
                                          ? 'Đang xóa…'
                                          : 'Xóa học cụ',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class CourseProductsScreen extends ConsumerWidget {
  const CourseProductsScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Học cụ của khóa học')),
    body: ApiView(
      path: '/shop/products?courseId=$courseId&pageSize=100',
      builder: (data) {
        final items = data['items'] as List;
        if (items.isEmpty) {
          return const Center(child: Text('Khóa học chưa đăng bán học cụ.'));
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final entry in items)
              Card(
                child: ListTile(
                  leading: Image.network(
                    Uri.parse(
                      ref.read(dioProvider).options.baseUrl,
                    ).resolve(entry['product']['thumbnailUrl']).toString(),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(entry['product']['name']),
                  subtitle: Text(
                    '${money(entry['product']['priceVnd'])}\n${entry['product']['description']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/parent/shop/product/${entry['product']['id']}',
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

String listingStatus(dynamic status) =>
    const {
      'pending': 'Chờ duyệt',
      'approved': 'Đã duyệt',
      'rejected': 'Bị từ chối',
    }[status] ??
    '$status';

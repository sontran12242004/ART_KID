/// Preserve camelCase and supply snake_case aliases for existing Flutter models.
Map<String, dynamic> apiMap(dynamic value) {
  if (value is! Map) {
    throw const FormatException('Dữ liệu máy chủ không hợp lệ.');
  }
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    final key = entry.key.toString();
    final item = entry.value;
    final normalized = item is Map
        ? apiMap(item)
        : item is List
        ? item.map((v) => v is Map ? apiMap(v) : v).toList()
        : item;
    result[key] = normalized;
    result[key.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m[0]!.toLowerCase()}',
        )] =
        normalized;
  }
  return result;
}

List<dynamic> apiList(dynamic value) => value is List
    ? value
    : (value is Map ? (value['items'] as List<dynamic>? ?? []) : []);
Map<String, dynamic> apiProduct(dynamic value, {String? baseUrl}) {
  final wrapper = apiMap(value);
  final product = apiMap({
    ...?(wrapper['product'] as Map<String, dynamic>?),
    ...wrapper,
  });
  if (baseUrl != null) {
    String resolve(String url) =>
        url.startsWith('/') ? Uri.parse(baseUrl).resolve(url).toString() : url;
    product['thumbnail_url'] = resolve(
      product['thumbnail_url'] as String? ?? '',
    );
    product['images'] = (product['images'] as List? ?? [])
        .map((url) => resolve(url as String))
        .toList();
  }
  return product;
}

Map<String, dynamic> apiOrder(dynamic value, {String? baseUrl}) {
  final wrapper = apiMap(value);
  final result = apiMap({
    ...?(wrapper['order'] as Map<String, dynamic>?),
    ...wrapper,
  });
  result['shipping_info'] ??= <String, dynamic>{};
  result['items'] = (result['items'] as List<dynamic>? ?? []).map((item) {
    final map = apiMap(item);
    map['kit_name'] = map['title'] ?? map['kit_name'];
    final thumbnail = map['thumbnail_url'];
    if (baseUrl != null && thumbnail is String && thumbnail.startsWith('/')) {
      map['thumbnail_url'] = Uri.parse(baseUrl).resolve(thumbnail).toString();
    }
    return map;
  }).toList();
  return result;
}

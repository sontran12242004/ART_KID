import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/session_store.dart';

final apiDataProvider = FutureProvider.autoDispose.family<dynamic, String>((
  ref,
  path,
) async {
  ref.watch(sessionStoreProvider.select((s) => s.userId));
  return (await ref.watch(dioProvider).get<dynamic>(path)).data;
});
final mediaBytesProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) async {
    ref.watch(sessionStoreProvider.select((s) => s.userId));
    final result = await ref
        .watch(dioProvider)
        .get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
        );
    return Uint8List.fromList(result.data!);
  },
);

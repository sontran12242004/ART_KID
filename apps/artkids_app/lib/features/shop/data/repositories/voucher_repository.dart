import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_json.dart';
import '../../../../core/network/api_interceptor.dart';
import '../models/voucher.dart';

final voucherRepositoryProvider = Provider<VoucherRepository>(
  (ref) => VoucherRepositoryImpl(ref.watch(dioProvider)),
);

abstract class VoucherRepository {
  Future<List<Voucher>> getAvailableVouchers();
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required int orderSubtotalVnd,
  });
}

class VoucherRepositoryImpl implements VoucherRepository {
  VoucherRepositoryImpl(this.dio);
  final Dio dio;
  @override
  Future<List<Voucher>> getAvailableVouchers() async => apiList(
    (await dio.get('/vouchers/available')).data,
  ).map((v) => Voucher.fromJson(apiMap(v))).toList();
  @override
  Future<VoucherValidationResult> validateVoucher({
    required String code,
    required int orderSubtotalVnd,
  }) async {
    try {
      final v = apiMap(
        (await dio.post(
          '/vouchers/validate',
          data: {
            'code': code.trim().toUpperCase(),
            'subtotalVnd': orderSubtotalVnd,
          },
        )).data,
      );
      return VoucherValidationResult.success(
        voucher: Voucher.fromJson(apiMap(v['voucher'])),
        discountAmountVnd: (v['discount_amount_vnd'] as num).toInt(),
      );
    } catch (e) {
      return VoucherValidationResult.failure(
        errorMessage: apiError(e),
        errorCode: VoucherErrorCode.notApplicable,
      );
    }
  }
}

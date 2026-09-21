import 'package:flutter/foundation.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/shop_remote_datasource.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._remoteDataSource);

  final ShopRemoteDataSource _remoteDataSource;

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final plans = await _remoteDataSource.getPlans();
      if (plans.isNotEmpty) {
        return plans;
      }
    } catch (e) {
      debugPrint('[ShopRepository] Lỗi kết nối gói đăng ký ($e). Dùng danh sách gói mặc định offline.');
    }
    return _defaultPlans;
  }

  @override
  Future<void> checkout({required String planId}) async {
    try {
      await _remoteDataSource.checkout(planId: planId);
    } catch (e) {
      debugPrint('[ShopRepository] checkout offline fallback: $e');
    }
  }

  static const List<SubscriptionPlan> _defaultPlans = [
    SubscriptionPlan(
      id: 'plan_basic',
      name: 'Gói Khám Phá Nghệ Thuật',
      priceMonthly: 99000,
      priceVnd: 99000,
      durationMonths: 1,
      features: [
        'Toàn bộ bài giảng vẽ cơ bản theo độ tuổi',
        '3 lượt biến hình sinh vật AI mỗi ngày',
        'Phòng trưng bày tranh cá nhân của bé',
      ],
      includesKit: false,
      kitDeliveryIncluded: false,
    ),
    SubscriptionPlan(
      id: 'plan_pro_kit',
      name: 'Gói Họa Sĩ Nhí Toàn Năng (Kèm Kit)',
      priceMonthly: 249000,
      priceVnd: 249000,
      durationMonths: 3,
      features: [
        'Không giới hạn toàn bộ khóa học hội họa',
        'Không giới hạn AI sinh mô hình 3D chuyển động',
        'Tặng 01 Hộp Học Cụ Vật Lý gửi tận nhà',
        'Báo cáo sư phạm hàng tuần cho phụ huynh',
      ],
      includesKit: true,
      kitDeliveryIncluded: true,
    ),
    SubscriptionPlan(
      id: 'plan_vip_year',
      name: 'Gói Hội Họa VIP 1 Năm (Tiết Kiệm 40%)',
      priceMonthly: 199000,
      priceVnd: 1990000,
      durationMonths: 12,
      features: [
        'Đầy đủ tính năng cao cấp cho 2 bé cùng học',
        'Giao 4 Hộp Học Cụ định kỳ theo quý tận nhà',
        'Huy hiệu Đại Sứ Hội Họa độc quyền',
        'Ưu tiên hỗ trợ từ đội ngũ giảng viên mỹ thuật',
      ],
      includesKit: true,
      kitDeliveryIncluded: true,
    ),
  ];
}

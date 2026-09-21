/// Phân loại hình thức giảm giá của voucher
enum DiscountType {
  /// Giảm theo tỷ lệ phần trăm (VD: 10% đơn hàng, có thể kèm mức trần tối đa)
  percentage(label: 'Phần trăm'),

  /// Giảm số tiền cố định bằng VNĐ (VD: Giảm trực tiếp 30.000 đ)
  fixedAmount(label: 'Số tiền cố định');

  const DiscountType({required this.label});

  final String label;

  static DiscountType fromString(String? val) {
    if (val == null) return DiscountType.percentage;
    final normalized = val.toLowerCase().trim();
    switch (normalized) {
      case 'fixed_amount':
      case 'fixedamount':
      case 'fixed':
      case 'amount':
        return DiscountType.fixedAmount;
      case 'percentage':
      case 'percent':
      default:
        return DiscountType.percentage;
    }
  }
}

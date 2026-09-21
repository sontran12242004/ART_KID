/// API endpoint paths — app gọi qua API Gateway
class ApiConstants {
  ApiConstants._();

  // Auth
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authConsent = '/auth/consent';
  static const authKidPinVerify = '/auth/kid-pin/verify';
  static const children = '/children';

  // Courses
  static const courses = '/courses';
  static const lessons = '/lessons';
  static const progress = '/progress';

  // Commerce & Orders & Shop
  static const cart = '/commerce/cart';
  static const checkout = '/commerce/checkout';
  static const subscriptions = '/commerce/subscriptions';
  static const orders = '/commerce/orders';
  static const orderDetail = '/commerce/orders/{id}';
  static const orderCancel = '/commerce/orders/{id}/cancel';
  static const shopProducts = '/shop/products';
  static const shopProductDetail = '/shop/products/{id}';
  static const vouchersAvailable = '/vouchers/available';
  static const vouchersValidate = '/vouchers/validate';

  // Submissions & AI (Kid API — tối giản)
  static const kidSubmitDrawing = '/kid/submissions';
  static const kidSubmissionStatus = '/kid/submissions/{id}/status';
  static const kidCreatures = '/kid/creatures';

  // Media
  static const mediaUpload = '/media/upload';
  static const mediaPresigned = '/media/presigned-url';
}

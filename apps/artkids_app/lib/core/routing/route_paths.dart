class RoutePaths {
  RoutePaths._();

  // Shared
  static const splash = '/';
  static const modeSelector = '/mode-selector';

  // Parent Mode
  static const parentHome = '/parent';
  static const parentLogin = '/parent/login';
  static const parentRegister = '/parent/register';
  static const parentChildren = '/parent/children';
  static const parentCourses = '/parent/courses';
  static const parentSubscriptions = '/parent/subscriptions';
  static const parentShop = '/parent/shop';
  static const parentShopProductDetail = '/parent/shop/product/:productId';
  static const parentShopCart = '/parent/shop/cart';
  static const parentShopCheckout = '/parent/shop/checkout';
  static const parentOrders = '/parent/orders';
  static const parentOrderDetail = '/parent/orders/:orderId';
  static const parentProgress = '/parent/progress';
  static const parentChildCoursesProgress =
      '/parent/child-progress/:childId/courses';
  static const parentSettings = '/parent/settings';
  static const parentKidPinSetup = '/parent/kid-pin';

  // Kid Mode
  static const kidPinGate = '/kid/pin';
  static const kidHome = '/kid';
  static const kidLesson = '/kid/course/:courseId/lessons';
  static const kidDrawingSubmission = '/kid/lesson/:lessonId/submit';
  static const kidBadges = '/kid/badges';

  // Matching Game (Kid Mode)
  static const matchingGame = '/matching-game';
  static const matchingGameDraw = '/matching-game/draw/:pictureSetId';
  static const matchingGameMatch = '/matching-game/match/:pictureSetId';
  static const matchingGameGallery = '/matching-game/gallery';
}

import '../../features/connected/presentation/marketplace_screens.dart';
import '../../features/connected/presentation/seller_order_screens.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/connected/presentation/family_screens.dart';
import '../../features/connected/presentation/learning_screens.dart';
import '../../features/connected/presentation/grading_screens.dart';
import '../../features/connected/presentation/family_submission_browser.dart';
import '../../features/connected/presentation/commerce_screens.dart';
import '../../features/connected/presentation/workspace_screens.dart';
import '../../features/connected/presentation/course_product_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/mode_selector_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/kid_mode/presentation/screens/kid_pin_gate_screen.dart';
import '../../features/matching_game/presentation/screens/completed_gallery_screen.dart';
import '../../features/matching_game/presentation/screens/drawing_screen.dart';
import '../../features/matching_game/presentation/screens/matching_screen.dart';
import '../../features/matching_game/presentation/screens/picture_selection_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/parent_dashboard/presentation/screens/all_courses_progress_screen.dart';
import '../../features/parent_dashboard/presentation/screens/child_progress_screen.dart';
import '../../features/shop/presentation/screens/cart_screen.dart';
import '../../features/shop/presentation/screens/product_detail_screen.dart';
import '../../features/shop/presentation/screens/shop_home_screen.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, next) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    refreshListenable: refresh,
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final user = ref.read(authProvider).currentUser;
      final public = [
        '/',
        '/mode-selector',
        '/parent/login',
        '/parent/register',
      ].contains(state.uri.path);
      if (user == null) return public ? null : '/parent/login';
      if (user.role != 'parent' &&
          !state.uri.path.startsWith('/staff') &&
          !state.uri.path.startsWith('/submissions') &&
          !(user.role == 'admin' &&
              state.uri.path.startsWith('/parent/orders')) &&
          !['/parent/submissions', '/parent/live'].contains(state.uri.path)) {
        return '/staff';
      }
      if (user.role == 'parent' && state.uri.path.startsWith('/staff')) {
        return '/parent';
      }
      final path = state.uri.path;
      final reviewRoute = path.startsWith('/staff/marketplace/reviews');
      final sellerRoute =
          path.startsWith('/staff/marketplace') && !reviewRoute ||
          path.startsWith('/staff/courses/') && path.endsWith('/products/new');
      if (reviewRoute && user.role != 'admin' ||
          sellerRoute && user.role != 'instructor' ||
          path == '/staff/orders' && user.role != 'admin') {
        return '/staff';
      }
      if (user.role == 'parent' &&
          state.uri.path.startsWith('/kid') &&
          ref.read(authProvider).selectedChild == null) {
        return '/parent/children';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/staff/marketplace',
        builder: (_, _) => const MarketplaceListingsScreen(),
      ),
      GoRoute(
        path: '/staff/marketplace/new',
        builder: (_, _) => const CourseProductPublishScreen(),
      ),
      GoRoute(
        path: '/staff/marketplace/listings/:id',
        builder: (_, s) =>
            MarketplaceListingDetail(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/staff/marketplace/reviews',
        builder: (_, _) => const MarketplaceListingsScreen(review: true),
      ),
      GoRoute(
        path: '/staff/marketplace/reviews/:id',
        builder: (_, s) =>
            MarketplaceListingDetail(id: s.pathParameters['id']!, review: true),
      ),
      GoRoute(
        path: '/staff/marketplace/orders',
        builder: (_, _) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/staff/marketplace/orders/:id',
        builder: (_, s) => SellerOrderDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/staff', builder: (_, _) => const StaffWorkspace()),
      GoRoute(
        path: '/staff/grading',
        builder: (_, _) => const GradingCoursesScreen(),
      ),
      GoRoute(
        path: '/staff/grading/courses/:id',
        builder: (_, s) =>
            GradingLessonsScreen(courseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/staff/grading/lessons/:id',
        builder: (_, s) =>
            GradingSubmissionsScreen(lessonId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/staff/courses/:courseId/products/new',
        builder: (_, state) => CourseProductPublishScreen(
          courseId: state.pathParameters['courseId']!,
        ),
      ),
      GoRoute(
        path: '/parent/courses/:courseId/products',
        builder: (_, state) =>
            CourseProductsScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(path: '/staff/orders', builder: (_, _) => const AdminOrders()),
      GoRoute(
        path: '/parent/children',
        builder: (_, _) => const ChildrenScreen(),
      ),
      GoRoute(
        path: '/parent/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/parent/submissions',
        builder: (_, _) => const SubmissionsScreen(),
      ),
      GoRoute(
        path: '/parent/submissions/courses/:id',
        builder: (_, s) =>
            FamilySubmissionBrowser(courseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/parent/submissions/lessons/:id',
        builder: (_, s) =>
            FamilySubmissionBrowser(lessonId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/parent/submissions/unassigned',
        builder: (_, _) => const FamilySubmissionBrowser(unassigned: true),
      ),
      GoRoute(
        path: '/submissions/:id',
        builder: (_, s) => SubmissionDetail(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/parent/live',
        builder: (_, _) => const LiveClassesScreen(),
      ),
      GoRoute(
        path: '/kid/lesson/:id',
        builder: (_, s) => ConnectedLesson(lessonId: s.pathParameters['id']!),
      ),
      // Shared Routes
      GoRoute(path: RoutePaths.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: RoutePaths.modeSelector,
        builder: (_, _) => const ModeSelectorScreen(),
      ),

      // Parent Mode Routes
      GoRoute(
        path: RoutePaths.parentLogin,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentRegister,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentHome,
        builder: (_, _) => const ParentWorkspace(),
      ),
      GoRoute(
        path: RoutePaths.parentCourses,
        builder: (_, _) => const ConnectedCourses(),
      ),
      GoRoute(
        path: RoutePaths.parentSubscriptions,
        builder: (_, _) => const ConnectedPlans(),
      ),
      GoRoute(
        path: RoutePaths.parentShop,
        builder: (_, _) => const ShopHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentShopProductDetail,
        builder: (_, state) => ProductDetailScreen(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.parentShopCart,
        builder: (_, _) => const CartScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentShopCheckout,
        builder: (_, s) => ConnectedCheckout(
          type: s.uri.queryParameters['type'],
          id: s.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: RoutePaths.parentOrders,
        builder: (_, _) => const OrdersListScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentOrderDetail,
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: RoutePaths.parentProgress,
        builder: (_, state) => ChildProgressScreen(
          childId: state.uri.queryParameters['childId'] ?? 'child-1',
        ),
      ),
      GoRoute(
        path: RoutePaths.parentChildCoursesProgress,
        builder: (_, state) => AllCoursesProgressScreen(
          childId: state.pathParameters['childId'] ?? 'child-1',
        ),
      ),
      GoRoute(
        path: RoutePaths.parentKidPinSetup,
        builder: (_, _) => const ConnectedSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentSettings,
        builder: (_, _) => const ConnectedSettingsScreen(),
      ),

      // Kid Mode Routes
      GoRoute(
        path: RoutePaths.kidPinGate,
        builder: (_, _) => const KidPinGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.kidHome,
        builder: (_, _) => const ConnectedKidHome(),
      ),
      GoRoute(
        path: RoutePaths.kidLesson,
        builder: (_, state) => ConnectedLessons(
          courseId: state.pathParameters['courseId'] ?? 'default-course',
        ),
      ),
      GoRoute(
        path: RoutePaths.kidDrawingSubmission,
        builder: (_, state) => SubmissionUpload(
          lessonId: state.pathParameters['lessonId'] ?? 'default-lesson',
        ),
      ),
      GoRoute(
        path: RoutePaths.kidBadges,
        builder: (_, _) => const ConnectedBadges(),
      ),
      GoRoute(
        path: RoutePaths.matchingGame,
        builder: (_, _) => const PictureSelectionScreen(),
      ),
      GoRoute(
        path: RoutePaths.matchingGameDraw,
        builder: (_, state) {
          final pictureSetId =
              state.pathParameters['pictureSetId'] ?? 'living_room';
          return DrawingScreen(pictureSetId: pictureSetId);
        },
      ),
      GoRoute(
        path: RoutePaths.matchingGameMatch,
        builder: (_, state) {
          final pictureSetId =
              state.pathParameters['pictureSetId'] ?? 'living_room';
          return MatchingScreen(pictureSetId: pictureSetId);
        },
      ),
      GoRoute(
        path: RoutePaths.matchingGameGallery,
        builder: (_, _) => const CompletedGalleryScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

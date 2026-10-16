import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/mode_selector_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/courses/presentation/screens/course_list_screen.dart';
import '../../features/courses/presentation/screens/lesson_list_screen.dart';
import '../../features/hand_drawn_submission/presentation/screens/hand_drawn_submission_screen.dart';
import '../../features/kid_mode/presentation/screens/kid_badges_screen.dart';
import '../../features/kid_mode/presentation/screens/kid_home_screen.dart';
import '../../features/kid_mode/presentation/screens/kid_pin_gate_screen.dart';
import '../../features/matching_game/presentation/screens/completed_gallery_screen.dart';
import '../../features/matching_game/presentation/screens/drawing_screen.dart';
import '../../features/matching_game/presentation/screens/matching_screen.dart';
import '../../features/matching_game/presentation/screens/picture_selection_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/parent_dashboard/presentation/screens/all_courses_progress_screen.dart';
import '../../features/parent_dashboard/presentation/screens/child_progress_screen.dart';
import '../../features/parent_dashboard/presentation/screens/parent_home_screen.dart';
import '../../features/parent_dashboard/presentation/screens/parent_pin_setup_screen.dart';
import '../../features/parent_dashboard/presentation/screens/parent_settings_screen.dart';
import '../../features/shop/presentation/screens/cart_screen.dart';
import '../../features/shop/presentation/screens/product_detail_screen.dart';
import '../../features/shop/presentation/screens/shop_checkout_screen.dart';
import '../../features/shop/presentation/screens/shop_home_screen.dart';
import '../../features/shop/presentation/screens/subscription_plans_screen.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      // Dynamic routing / guards can be implemented here
      return null;
    },
    routes: [
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
        builder: (_, _) => const ParentHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentCourses,
        builder: (_, _) => const CourseListScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentSubscriptions,
        builder: (_, _) => const SubscriptionPlansScreen(),
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
        builder: (_, _) => const ShopCheckoutScreen(),
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
        builder: (_, _) => const ParentPinSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.parentSettings,
        builder: (_, _) => const ParentSettingsScreen(),
      ),

      // Kid Mode Routes
      GoRoute(
        path: RoutePaths.kidPinGate,
        builder: (_, _) => const KidPinGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.kidHome,
        builder: (_, _) => const KidHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.kidLesson,
        builder: (_, state) => LessonListScreen(
          courseId: state.pathParameters['courseId'] ?? 'default-course',
        ),
      ),
      GoRoute(
        path: RoutePaths.kidDrawingSubmission,
        builder: (_, state) => HandDrawnSubmissionScreen(
          lessonId: state.pathParameters['lessonId'] ?? 'default-lesson',
        ),
      ),
      GoRoute(
        path: RoutePaths.kidBadges,
        builder: (_, _) => const KidBadgesScreen(),
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
});

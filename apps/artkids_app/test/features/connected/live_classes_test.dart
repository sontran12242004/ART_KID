import 'package:artkids_app/core/network/api_interceptor.dart';
import 'package:artkids_app/core/network/dio_client.dart';
import 'package:artkids_app/core/network/session_store.dart';
import 'package:artkids_app/features/auth/domain/entities/child_profile.dart';
import 'package:artkids_app/features/auth/domain/entities/parent_user.dart';
import 'package:artkids_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:artkids_app/features/auth/domain/usecases/login_parent.dart';
import 'package:artkids_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:artkids_app/features/connected/presentation/live_class_screens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/http_fixture.dart';

class _TestAuthRepository implements AuthRepository {
  @override
  Future<List<ChildProfile>> getChildren() async => const [
    ChildProfile(id: 'child-1', nickname: 'Bé Bo', age: 8),
  ];

  @override
  Future<ParentUser> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<ParentUser> register({
    required String email,
    required String password,
    required String displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> recordParentalConsent() async {}

  @override
  Future<ChildProfile> createChild({
    required String nickname,
    required int birthYear,
  }) => throw UnimplementedError();

  @override
  Future<bool> verifyKidPin(String pin) async => true;
}

AuthNotifier _seededParentAuth([SessionStore? sessionStore]) {
  final repo = _TestAuthRepository();
  final notifier = AuthNotifier(LoginParentUseCase(repo), repo, sessionStore);
  notifier.updateUser(
    const ParentUser(
      id: 'parent-1',
      email: 'parent.test@example.invalid',
      fullName: 'Nguyen Test Parent',
      role: 'parent',
    ),
  );
  notifier.selectChild(
    const ChildProfile(id: 'child-1', nickname: 'Bé Bo', age: 8),
  );
  return notifier;
}

AuthNotifier _seededInstructorAuth([SessionStore? sessionStore]) {
  final repo = _TestAuthRepository();
  final notifier = AuthNotifier(LoginParentUseCase(repo), repo, sessionStore);
  notifier.updateUser(
    const ParentUser(
      id: 'instructor_test_01',
      email: 'instructor.test@example.invalid',
      fullName: 'Cô Minh Anh',
      role: 'instructor',
    ),
  );
  return notifier;
}

void main() {
  testWidgets(
    'displays upcoming/live/ended filters, long titles on small screen, and joins session with valid HTTPS URL',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Uri? launchedUri;
      Map<String, dynamic>? joinPayload;

      final dio = fixtureDio((request) {
        final uri = request.uri;
        if (uri.path.endsWith('/live/sessions') &&
            uri.queryParameters['status'] == 'upcoming') {
          return jsonResponse({
            'items': [
              {
                'id': 'session-upcoming-1',
                'classId': 'class-1',
                'className':
                    'Lớp Vẽ Cơ Bản Sáng Tạo Siêu Dài Dành Cho Thiếu Nhi Từ 6 Đến 12 Tuổi',
                'classStatus': 'open',
                'capacity': 20,
                'courseId': 'course_basics',
                'courseTitle': 'Vẽ cơ bản',
                'instructorId': 'inst-1',
                'instructorName': 'Cô Minh Anh',
                'lessonId': 'lesson-1',
                'lessonTitle': 'Bài 1: Nét vẽ đầu tiên',
                'title':
                    'Buổi 1: Làm quen với nét vẽ cơ bản, hình khối và bố cục bức tranh mùa hè',
                'startsAt': '2026-11-05T11:00:00Z',
                'endsAt': '2026-11-05T12:00:00Z',
                'opensAt': '2026-11-05T10:45:00Z',
                'provider': 'zoom',
                'providerLabel': 'Zoom',
                'status': 'scheduled',
                'effectiveStatus': 'scheduled',
                'filterGroup': 'upcoming',
                'hasRoomUrl': false,
                'canJoin': false,
                'joinBlockedReason':
                    'Chưa đến giờ vào lớp. Phòng học sẽ mở trước giờ bắt đầu 15 phút.',
                'childId': 'child-1',
                'childNickname': 'Bé Bo',
              },
            ],
            'page': 1,
            'pageSize': 50,
            'total': 1,
            'counts': {'upcoming': 1, 'live': 1, 'ended': 0},
          });
        }
        if (uri.path.endsWith('/live/sessions') &&
            uri.queryParameters['status'] == 'live') {
          return jsonResponse({
            'items': [
              {
                'id': 'session-live-1',
                'classId': 'class-2',
                'className': 'Lớp Phối Màu B2',
                'classStatus': 'open',
                'capacity': 25,
                'courseId': 'course_basics',
                'courseTitle': 'Vẽ cơ bản',
                'instructorId': 'inst-2',
                'instructorName': 'Thầy Hoàng Nam',
                'lessonId': 'lesson-2',
                'lessonTitle': 'Phối màu nước',
                'title': 'Thực hành phối màu nước chuyển sắc',
                'startsAt': '2026-11-02T00:00:00Z',
                'endsAt': '2026-11-02T02:00:00Z',
                'opensAt': '2026-11-01T23:45:00Z',
                'provider': 'google_meet',
                'providerLabel': 'Google Meet',
                'status': 'live',
                'effectiveStatus': 'live',
                'filterGroup': 'live',
                'hasRoomUrl': true,
                'canJoin': true,
                'joinBlockedReason': null,
                'childId': 'child-1',
                'childNickname': 'Bé Bo',
              },
            ],
            'page': 1,
            'pageSize': 50,
            'total': 1,
            'counts': {'upcoming': 1, 'live': 1, 'ended': 0},
          });
        }
        if (uri.path.endsWith('/live/sessions') &&
            uri.queryParameters['status'] == 'ended') {
          return jsonResponse({
            'items': [],
            'page': 1,
            'pageSize': 50,
            'total': 0,
            'counts': {'upcoming': 1, 'live': 1, 'ended': 0},
          });
        }
        if (uri.path.endsWith('/live/sessions/session-live-1/room/token') &&
            request.method == 'POST') {
          joinPayload = Map<String, dynamic>.from(request.data as Map);
          return jsonResponse({
            'sessionId': 'session-live-1',
            'classId': 'class-2',
            'className': 'Lớp Phối Màu B2',
            'sessionTitle': 'Thực hành phối màu nước chuyển sắc',
            'capacity': 25,
            'isOneOnOne': false,
            'roomName': 'artkids-session-session-live-1',
            'roomVersion': 1,
            'roomToken': 'room-jwt-student-1',
            'participantIdentity': 'student:child-1',
            'participantName': 'Bé Bo',
            'participantRole': 'student',
            'permissions': {
              'canPublishAudio': true,
              'canPublishVideo': true,
              'canSubscribe': true,
              'canModerateAudio': false,
              'canEndSession': false,
            },
            'sfu': {
              'provider': 'livekit',
              'isConfigured': true,
              'serverUrl': 'wss://livekit.artkids.local',
              'accessToken': 'lk-jwt-1',
              'missingConfigurationKeys': <String>[],
            },
          });
        }
        if (uri.path.endsWith('/live/sessions/session-live-1/room/connect') &&
            request.method == 'POST') {
          return jsonResponse({
            'connected': true,
            'roomName': 'artkids-session-session-live-1',
            'participants': [
              {
                'identity': 'instructor:inst-2',
                'displayName': 'Thầy Hoàng Nam',
                'role': 'instructor',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
              {
                'identity': 'student:child-1',
                'displayName': 'Bé Bo',
                'role': 'student',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
            ],
          });
        }
        if (uri.path
                .endsWith('/live/sessions/session-live-1/room/disconnect') &&
            request.method == 'POST') {
          return jsonResponse({'disconnected': true});
        }
        if (uri.path.endsWith('/live/sessions/session-live-1')) {
          return jsonResponse({
            'id': 'session-live-1',
            'title': 'Thực hành phối màu nước chuyển sắc',
            'startsAt': '2026-11-02T00:00:00Z',
            'endsAt': '2026-11-02T02:00:00Z',
            'opensAt': '2026-11-01T23:45:00Z',
            'provider': 'google_meet',
            'providerLabel': 'Google Meet',
            'status': 'live',
            'effectiveStatus': 'live',
            'filterGroup': 'live',
            'hasRoomUrl': true,
            'canJoin': true,
            'joinBlockedReason': null,
            'childId': 'child-1',
            'childNickname': 'Bé Bo',
            'liveClass': {
              'id': 'class-2',
              'name': 'Lớp Phối Màu B2',
              'status': 'open',
              'capacity': 25,
              'enrolledCount': 12,
              'courseId': 'course_basics',
              'courseTitle': 'Vẽ cơ bản',
              'courseDescription': 'Khóa học nền tảng về màu sắc và đường nét.',
              'ageRange': '6–10 tuổi',
              'instructorId': 'inst-2',
              'instructorName': 'Thầy Hoàng Nam',
            },
            'lesson': {
              'id': 'lesson-2',
              'title': 'Phối màu nước',
              'orderIndex': 2,
              'practiceInstructions': 'Chuẩn bị cọ tròn số 6 và giấy định lượng 300gsm.',
              'hasVideo': true,
            },
            'classSessions': [
              {
                'id': 'session-live-1',
                'title': 'Thực hành phối màu nước chuyển sắc',
                'startsAt': '2026-11-02T00:00:00Z',
                'endsAt': '2026-11-02T02:00:00Z',
                'provider': 'google_meet',
                'providerLabel': 'Google Meet',
                'status': 'live',
                'effectiveStatus': 'live',
                'filterGroup': 'live',
                'isCurrent': true,
              },
            ],
          });
        }
        return jsonResponse([]);
      });

      final router = GoRouter(
        initialLocation: '/parent/live',
        routes: [
          GoRoute(
            path: '/parent/live',
            builder: (_, _) => const LiveClassesScreen(),
          ),
          GoRoute(
            path: '/parent/live/sessions/:id',
            builder: (_, s) => LiveSessionDetailScreen(
              sessionId: s.pathParameters['id']!,
              childId: s.uri.queryParameters['childId'],
            ),
          ),
          GoRoute(
            path: '/parent/live/sessions/:id/room',
            builder: (_, s) => LiveClassroomScreen(
              sessionId: s.pathParameters['id']!,
              childId: s.uri.queryParameters['childId'],
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            authProvider.overrideWith((ref) => _seededParentAuth()),
            urlLauncherProvider.overrideWithValue((uri) async {
              launchedUri = uri;
              return true;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Upcoming filter is active by default and displays the blocked reason clearly
      expect(find.text('Lớp học trực tuyến'), findsOneWidget);
      expect(find.textContaining('Sắp diễn ra (1)'), findsOneWidget);
      expect(find.textContaining('Cô Minh Anh'), findsOneWidget);
      expect(find.text('Zoom'), findsOneWidget);
      expect(
        find.text(
          'Chưa đến giờ vào lớp. Phòng học sẽ mở trước giờ bắt đầu 15 phút.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tham gia lớp học'), findsNothing);

      // Switch to "Đang diễn ra" filter
      await tester.tap(find.textContaining('Đang diễn ra (1)'));
      await tester.pumpAndSettle();

      expect(
        find.text('Thực hành phối màu nước chuyển sắc'),
        findsOneWidget,
      );
      expect(find.text('Google Meet'), findsOneWidget);
      expect(find.text('Tham gia lớp học'), findsOneWidget);

      // Tap "Tham gia lớp học" on the live session card -> navigates to in-app Pre-join screen
      await tester.tap(find.text('Tham gia lớp học'));
      await tester.pumpAndSettle();

      expect(joinPayload, {'childId': 'child-1'});
      expect(
        find.text('Kiểm tra thiết bị trước khi vào phòng'),
        findsOneWidget,
      );
      expect(find.text('Vào phòng học trực tuyến'), findsOneWidget);

      // Enter the in-app room and then leave back to the list
      await tester.ensureVisible(find.text('Vào phòng học trực tuyến'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vào phòng học trực tuyến'));
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối'), findsOneWidget);
      await tester.tap(find.text('Rời phòng'));
      await tester.pumpAndSettle();
      expect(launchedUri, isNull);

      // Open detail screen
      await tester.tap(find.text('Xem chi tiết buổi học'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết buổi học'), findsOneWidget);
      expect(
        find.text('Khóa học nền tảng về màu sắc và đường nét.'),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        find.text('Chuẩn bị cọ tròn số 6 và giấy định lượng 300gsm.'),
        findsOneWidget,
      );

      // Go back and switch to "Đã kết thúc" (empty state)
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Đã kết thúc'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có buổi học nào đã kết thúc'), findsOneWidget);
    },
  );

  testWidgets(
    'handles API connection error with retry, unauthorized 403 detail access, and expired 401 session',
    (tester) async {
      var failList = true;
      final sessionStore = SessionStore();
      sessionStore.accept({
        'accessToken': 'expired-token',
        'refreshToken': 'invalid-refresh',
        'user': {'id': 'parent-1', 'role': 'parent'},
      });

      late ProviderContainer container;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'));
      dio.httpClientAdapter = FixtureAdapter((request) {
        final uri = request.uri;
        if (uri.path.endsWith('/live/sessions')) {
          if (failList) {
            return jsonResponse(
              {'title': 'Máy chủ đang bảo trì tạm thời.'},
              status: 503,
            );
          }
          return jsonResponse({
            'items': [],
            'page': 1,
            'pageSize': 50,
            'total': 0,
            'counts': {'upcoming': 0, 'live': 0, 'ended': 0},
          });
        }
        if (uri.path.endsWith('/live/sessions/forbidden-session')) {
          return jsonResponse(
            {'title': 'Bé chưa đăng ký tham gia lớp học trực tuyến này.'},
            status: 403,
          );
        }
        if (uri.path.endsWith('/live/sessions/expired-auth-session')) {
          return jsonResponse({'title': 'Phiên đăng nhập hết hạn.'}, status: 401);
        }
        if (uri.path.endsWith('/auth/refresh')) {
          return jsonResponse({'title': 'Refresh token không hợp lệ.'}, status: 401);
        }
        return jsonResponse([]);
      });

      container = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWith((ref) => sessionStore),
          dioProvider.overrideWith((ref) {
            dio.interceptors.clear();
            dio.interceptors.add(ApiInterceptor(ref, dio));
            return dio;
          }),
          authProvider.overrideWith(
            (ref) => _seededParentAuth(ref.read(sessionStoreProvider.notifier)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LiveClassesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Error state and retry button
      expect(find.text('Không thể tải lịch học trực tuyến'), findsOneWidget);
      expect(find.text('Máy chủ đang bảo trì tạm thời.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      failList = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có buổi học sắp diễn ra'), findsOneWidget);

      // 403 unauthorized session detail
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LiveSessionDetailScreen(
              sessionId: 'forbidden-session',
              childId: 'child-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể mở thông tin buổi học'), findsOneWidget);
      expect(
        find.text('Bé chưa đăng ký tham gia lớp học trực tuyến này.'),
        findsOneWidget,
      );

      // 401 expired session clears session store
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LiveSessionDetailScreen(
              sessionId: 'expired-auth-session',
              childId: 'child-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(sessionStoreProvider).accessToken, isNull);
    },
  );

  testWidgets(
    'instructor views teaching schedule, filters including cancelled, 1-on-1 & group student summary, and manages session lifecycle',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Uri? launchedUri;
      var sessionStatus = 'scheduled';
      String? sessionRoomUrl;
      final statePayloads = <Map<String, dynamic>>[];
      Map<String, dynamic>? updatedSessionPayload;

      Map<String, dynamic> buildScheduledSession() => {
        'id': 'inst-session-1',
        'classId': 'class-1on1',
        'className': 'Lớp Kèm 1-1 Cọ Nhí C1',
        'classStatus': 'open',
        'capacity': 1,
        'enrolledCount': 1,
        'enrolledStudentNames': ['Bé Bo'],
        'courseId': 'course_basics',
        'courseTitle': 'Vẽ cơ bản',
        'instructorId': 'instructor_test_01',
        'instructorName': 'Cô Minh Anh',
        'lessonId': 'lesson-1',
        'lessonTitle': 'Bài 1: Nét vẽ đầu tiên',
        'title': 'Buổi 1: Hướng dẫn cầm cọ 1 kèm 1',
        'startsAt': '2026-11-05T11:00:00Z',
        'endsAt': '2026-11-05T12:00:00Z',
        'opensAt': '2026-11-05T10:45:00Z',
        'provider': 'google_meet',
        'providerLabel': 'Google Meet',
        'status': sessionStatus,
        'effectiveStatus': sessionStatus,
        'filterGroup': sessionStatus == 'live'
            ? 'live'
            : sessionStatus == 'scheduled'
            ? 'upcoming'
            : 'ended',
        'hasRoomUrl': sessionRoomUrl != null,
        'roomUrl': sessionRoomUrl,
        'canJoin': sessionStatus == 'live' && sessionRoomUrl != null,
        'joinBlockedReason': sessionRoomUrl == null
            ? 'Chưa cấu hình liên kết phòng học. Vui lòng cập nhật đường dẫn phòng học (HTTPS) trước khi vào phòng dạy.'
            : null,
        'canStartSession': sessionStatus == 'scheduled',
        'canEndSession': sessionStatus == 'live',
        'canCancelSession':
            sessionStatus == 'scheduled' || sessionStatus == 'live',
        'canEditSession': sessionStatus == 'scheduled',
      };

      final groupSession = {
        'id': 'inst-session-2',
        'classId': 'class-group',
        'className': 'Lớp Vẽ Nhóm Sáng Tạo A1',
        'classStatus': 'open',
        'capacity': 20,
        'enrolledCount': 12,
        'enrolledStudentNames': ['Bé Bo', 'Bé Mi'],
        'courseId': 'course_basics',
        'courseTitle': 'Phối màu nâng cao',
        'instructorId': 'instructor_test_01',
        'instructorName': 'Cô Minh Anh',
        'title': 'Buổi 2: Thực hành pha màu nhóm',
        'startsAt': '2026-11-06T11:00:00Z',
        'endsAt': '2026-11-06T12:00:00Z',
        'opensAt': '2026-11-06T10:45:00Z',
        'provider': 'zoom',
        'providerLabel': 'Zoom',
        'status': 'scheduled',
        'effectiveStatus': 'scheduled',
        'filterGroup': 'upcoming',
        'hasRoomUrl': true,
        'roomUrl': 'https://zoom.us/j/123456789',
        'canJoin': false,
        'joinBlockedReason':
            'Chưa đến khung giờ mở phòng (15 phút trước giờ học). Bạn có thể bấm "Bắt đầu buổi học" khi sẵn sàng dạy.',
      };

      final cancelledSession = {
        'id': 'inst-session-cancelled',
        'classId': 'class-1on1',
        'className': 'Lớp Kèm 1-1 Cọ Nhí C1',
        'classStatus': 'open',
        'capacity': 1,
        'enrolledCount': 1,
        'enrolledStudentNames': ['Bé Bo'],
        'courseId': 'course_basics',
        'courseTitle': 'Vẽ cơ bản',
        'instructorId': 'instructor_test_01',
        'instructorName': 'Cô Minh Anh',
        'title': 'Buổi học bù đã dời lịch',
        'startsAt': '2026-11-01T11:00:00Z',
        'endsAt': '2026-11-01T12:00:00Z',
        'opensAt': '2026-11-01T10:45:00Z',
        'provider': 'google_meet',
        'providerLabel': 'Google Meet',
        'status': 'cancelled',
        'effectiveStatus': 'cancelled',
        'filterGroup': 'ended',
        'hasRoomUrl': true,
        'canJoin': false,
        'joinBlockedReason': 'Buổi học này đã bị hủy.',
      };

      final dio = fixtureDio((request) {
        final uri = request.uri;
        if (uri.path.endsWith('/live/sessions') && request.method == 'GET') {
          final status = uri.queryParameters['status'] ?? 'all';
          final items = switch (status) {
            'cancelled' => [cancelledSession],
            'upcoming' => [buildScheduledSession(), groupSession],
            _ => [buildScheduledSession(), groupSession, cancelledSession],
          };
          return jsonResponse({
            'items': items,
            'page': 1,
            'pageSize': 50,
            'total': items.length,
            'counts': {
              'all': 3,
              'upcoming': 2,
              'live': sessionStatus == 'live' ? 1 : 0,
              'ended': 1,
              'cancelled': 1,
            },
          });
        }
        if (uri.path.endsWith(
              '/live/classes/class-1on1/sessions/inst-session-1',
            ) &&
            request.method == 'PUT') {
          updatedSessionPayload = Map<String, dynamic>.from(
            request.data as Map,
          );
          sessionRoomUrl = updatedSessionPayload!['roomUrl']?.toString();
          return jsonResponse(buildScheduledSession());
        }
        if (uri.path.endsWith('/live/sessions/inst-session-1/state') &&
            request.method == 'POST') {
          final body = Map<String, dynamic>.from(request.data as Map);
          statePayloads.add(body);
          sessionStatus = body['status'].toString();
          return jsonResponse(buildScheduledSession());
        }
        if (uri.path.endsWith('/live/sessions/inst-session-1/room/token') &&
            request.method == 'POST') {
          return jsonResponse({
            'sessionId': 'inst-session-1',
            'classId': 'class-1on1',
            'className': 'Lớp Kèm 1-1 Cọ Nhí C1',
            'sessionTitle': 'Buổi 1: Hướng dẫn cầm cọ 1 kèm 1',
            'capacity': 1,
            'isOneOnOne': true,
            'roomName': 'artkids-session-inst-session-1',
            'roomVersion': 1,
            'roomToken': 'room-jwt-inst-1',
            'participantIdentity': 'instructor:instructor_test_01',
            'participantName': 'Cô Minh Anh',
            'participantRole': 'instructor',
            'permissions': {
              'canPublishAudio': true,
              'canPublishVideo': true,
              'canSubscribe': true,
              'canModerateAudio': true,
              'canEndSession': true,
            },
            'sfu': {
              'provider': 'livekit',
              'isConfigured': false,
              'serverUrl': null,
              'accessToken': null,
              'missingConfigurationKeys': [
                'LiveKit:Url',
                'LiveKit:ApiKey',
                'LiveKit:ApiSecret',
              ],
            },
          });
        }
        if (uri.path.endsWith('/live/sessions/inst-session-1/room/connect') &&
            request.method == 'POST') {
          return jsonResponse({
            'connected': true,
            'roomName': 'artkids-session-inst-session-1',
            'participants': [
              {
                'identity': 'instructor:instructor_test_01',
                'displayName': 'Cô Minh Anh',
                'role': 'instructor',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
              {
                'identity': 'student:child-1',
                'displayName': 'Bé Bo',
                'role': 'student',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
            ],
          });
        }
        if (uri.path.endsWith('/live/sessions/inst-session-1/room/state') &&
            request.method == 'POST') {
          final body = Map<String, dynamic>.from(request.data as Map);
          return jsonResponse({
            'connected': true,
            'muteRequestedByInstructor': false,
            'participants': [
              {
                'identity': 'instructor:instructor_test_01',
                'displayName': 'Cô Minh Anh',
                'role': 'instructor',
                'micEnabled': body['micEnabled'] == true,
                'cameraEnabled': body['cameraEnabled'] == true,
                'cameraFacing': body['cameraFacing'] ?? 'front',
                'connectionState': 'connected',
              },
              {
                'identity': 'student:child-1',
                'displayName': 'Bé Bo',
                'role': 'student',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
            ],
          });
        }
        if (uri.path.endsWith('/live/sessions/inst-session-1/room/moderate') &&
            request.method == 'POST') {
          return jsonResponse({
            'moderated': true,
            'targetIdentity': 'student:child-1',
            'action': 'mute_mic',
            'participants': [
              {
                'identity': 'instructor:instructor_test_01',
                'displayName': 'Cô Minh Anh',
                'role': 'instructor',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
              {
                'identity': 'student:child-1',
                'displayName': 'Bé Bo',
                'role': 'student',
                'micEnabled': false,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
            ],
          });
        }
        if (uri.path
                .endsWith('/live/sessions/inst-session-1/room/disconnect') &&
            request.method == 'POST') {
          return jsonResponse({'disconnected': true});
        }
        if (uri.path.endsWith('/live/sessions/inst-session-1') &&
            request.method == 'GET') {
          final base = buildScheduledSession();
          return jsonResponse({
            ...base,
            'liveClass': {
              'id': 'class-1on1',
              'name': 'Lớp Kèm 1-1 Cọ Nhí C1',
              'status': 'open',
              'capacity': 1,
              'enrolledCount': 1,
              'courseId': 'course_basics',
              'courseTitle': 'Vẽ cơ bản',
              'courseDescription': 'Khóa học kèm riêng giúp bé rèn nét vẽ.',
              'ageRange': '6–10 tuổi',
              'instructorId': 'instructor_test_01',
              'instructorName': 'Cô Minh Anh',
            },
            'roster': [
              {
                'enrollmentId': 'enr-1',
                'childId': 'child-1',
                'nickname': 'Bé Bo',
                'status': 'enrolled',
                'attended': true,
                'isCurrentlyInRoom': false,
                'totalDurationSeconds': 1800,
              },
            ],
            'classSessions': [
              {...base, 'isCurrent': true},
            ],
          });
        }
        if (uri.path.endsWith('/live/sessions/other-instructor-session')) {
          return jsonResponse(
            {'title': 'Session not found.'},
            status: 404,
          );
        }
        return jsonResponse([]);
      });

      final router = GoRouter(
        initialLocation: '/parent/live',
        routes: [
          GoRoute(
            path: '/parent/live',
            builder: (_, _) => const LiveClassesScreen(),
          ),
          GoRoute(
            path: '/parent/live/sessions/:id',
            builder: (_, s) =>
                LiveSessionDetailScreen(sessionId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/parent/live/sessions/:id/room',
            builder: (_, s) =>
                LiveClassroomScreen(sessionId: s.pathParameters['id']!),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            authProvider.overrideWith((ref) => _seededInstructorAuth()),
            urlLauncherProvider.overrideWithValue((uri) async {
              launchedUri = uri;
              return true;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verify instructor default filter "Tất cả", 1-on-1 student name, group student count, and missing link badge
      expect(find.textContaining('Tất cả (3)'), findsOneWidget);
      expect(find.textContaining('Đã hủy (1)'), findsOneWidget);
      expect(find.text('Bé Bo (Lớp 1 kèm 1)'), findsWidgets);
      expect(find.text('Chưa cấu hình liên kết phòng học'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.text('12/20 học viên'), findsOneWidget);

      // Filter by "Đã hủy"
      await tester.drag(find.byType(ListView), const Offset(0, 450));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Đã hủy (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Buổi học bù đã dời lịch'), findsOneWidget);

      // Switch back to "Tất cả" and open detail of inst-session-1 by tapping the card title
      await tester.tap(find.textContaining('Tất cả (3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buổi 1: Hướng dẫn cầm cọ 1 kèm 1'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thêm liên kết phòng học'));
      await tester.pumpAndSettle();
      expect(find.text('Điều khiển buổi dạy của Gia sư'), findsOneWidget);
      expect(find.text('Thêm liên kết phòng học'), findsOneWidget);
      expect(find.text('Bắt đầu buổi học'), findsOneWidget);

      // 1. Add HTTPS room link
      await tester.tap(find.text('Thêm liên kết phòng học'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'https://meet.google.com/art-kids-1on1-room',
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(
        updatedSessionPayload?['roomUrl'],
        'https://meet.google.com/art-kids-1on1-room',
      );

      // 2. Start session (transition scheduled -> live)
      await tester.ensureVisible(find.text('Bắt đầu buổi học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu buổi học'));
      await tester.pumpAndSettle();
      expect(statePayloads.last, {'status': 'live'});

      // 3. Enter in-app room ("Vào phòng dạy")
      await tester.ensureVisible(find.text('Vào phòng dạy'));
      await tester.pumpAndSettle();
      expect(find.text('Vào phòng dạy'), findsOneWidget);
      await tester.tap(find.text('Vào phòng dạy'));
      await tester.pumpAndSettle();

      // Verify Pre-join screen & honest SFU notice
      expect(
        find.text('Kiểm tra thiết bị trước khi vào phòng'),
        findsOneWidget,
      );
      expect(find.textContaining('LiveKit:Url'), findsOneWidget);
      await tester.ensureVisible(find.text('Vào phòng dạy trực tuyến'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vào phòng dạy trực tuyến'));
      await tester.pumpAndSettle();

      // Verify 1-on-1 active room stage, toggle camera (shows avatar), switch camera, and mute student mic
      expect(find.text('Cô Minh Anh (Bạn)'), findsWidgets);
      expect(find.text('Bé Bo'), findsWidgets);
      await tester.tap(find.text('Tắt cam'));
      await tester.pumpAndSettle();
      expect(find.text('Camera đang tắt'), findsOneWidget);

      await tester.tap(find.text('Người tham gia (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Tắt mic'), findsWidgets);
      await tester.tap(find.text('Tắt mic').last);
      await tester.pumpAndSettle();
      expect(find.text('Đã tắt microphone của Bé Bo.'), findsOneWidget);

      // Leave room without ending the session for everyone
      await tester.tap(find.text('Rời phòng'));
      await tester.pumpAndSettle();
      expect(launchedUri, isNull);

      // 4. Verify student roster & attendance
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(
        find.text('Danh sách học viên & Điểm danh (1/1)'),
        findsOneWidget,
      );
      expect(
        find.text('Đã điểm danh · Thời lượng: 30 phút'),
        findsOneWidget,
      );

      // 5. Complete session ("Kết thúc buổi học") with confirmation dialog
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kết thúc buổi học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kết thúc buổi học'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận kết thúc buổi học'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        'https://meet.google.com/art-kids-1on1-recording',
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(statePayloads.last, {
        'status': 'completed',
        'recordingUrl': 'https://meet.google.com/art-kids-1on1-recording',
      });

      // 6. Verify cross-instructor session access is blocked (404)
      router.go('/parent/live/sessions/other-instructor-session');
      await tester.pumpAndSettle();
      expect(find.text('Không thể mở thông tin buổi học'), findsOneWidget);
      expect(find.textContaining('404'), findsOneWidget);
    },
  );

  testWidgets(
    'in-app classroom handles denied permissions recovery, group class layout, instructor ending session, and revoked token 409',
    (tester) async {
      var permsGranted = false;
      var openedSystemSettings = false;
      var sessionEnded = false;

      final permService = _ConfigurablePermissionService(
        onCheckOrRequest: () => LiveMediaPermissionState(
          cameraGranted: permsGranted,
          microphoneGranted: permsGranted,
          cameraPermanentlyDenied: !permsGranted,
          microphonePermanentlyDenied: !permsGranted,
        ),
        onOpenSettings: () async {
          openedSystemSettings = true;
          return true;
        },
      );

      final dio = fixtureDio((request) {
        final uri = request.uri;
        if (uri.path.endsWith('/live/sessions/group-session-1/room/token') &&
            request.method == 'POST') {
          if (sessionEnded) {
            return jsonResponse(
              {
                'message':
                    'Buổi học đã kết thúc. Không thể cấp hoặc sử dụng lại token vào phòng.',
              },
              status: 409,
            );
          }
          return jsonResponse({
            'sessionId': 'group-session-1',
            'classId': 'class-group-1',
            'className': 'Lớp Vẽ Nhóm B1',
            'sessionTitle': 'Buổi 3: Vẽ phong cảnh nhóm',
            'capacity': 15,
            'isOneOnOne': false,
            'roomName': 'artkids-session-group-session-1',
            'roomVersion': 1,
            'roomToken': 'room-jwt-group-inst',
            'participantIdentity': 'instructor:instructor_test_01',
            'participantName': 'Cô Minh Anh',
            'participantRole': 'instructor',
            'permissions': {
              'canPublishAudio': true,
              'canPublishVideo': true,
              'canSubscribe': true,
              'canModerateAudio': true,
              'canEndSession': true,
            },
            'sfu': {
              'provider': 'livekit',
              'isConfigured': true,
              'serverUrl': 'wss://livekit.artkids.local',
              'accessToken': 'lk-group-jwt',
              'missingConfigurationKeys': <String>[],
            },
          });
        }
        if (uri.path.endsWith('/live/sessions/group-session-1/room/connect') &&
            request.method == 'POST') {
          return jsonResponse({
            'connected': true,
            'roomName': 'artkids-session-group-session-1',
            'participants': [
              {
                'identity': 'instructor:instructor_test_01',
                'displayName': 'Cô Minh Anh',
                'role': 'instructor',
                'micEnabled': true,
                'cameraEnabled': true,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
              {
                'identity': 'student:child-1',
                'displayName': 'Bé Bo',
                'role': 'student',
                'micEnabled': true,
                'cameraEnabled': false,
                'cameraFacing': 'front',
                'connectionState': 'connected',
              },
              {
                'identity': 'student:child-2',
                'displayName': 'Bé Miu',
                'role': 'student',
                'micEnabled': false,
                'cameraEnabled': true,
                'cameraFacing': 'back',
                'connectionState': 'connected',
              },
            ],
          });
        }
        if (uri.path.endsWith('/live/sessions/group-session-1/room/end') &&
            request.method == 'POST') {
          sessionEnded = true;
          return jsonResponse({
            'ended': true,
            'status': 'completed',
            'roomVersion': 2,
          });
        }
        return jsonResponse({});
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            authProvider.overrideWith((ref) => _seededInstructorAuth()),
            liveMediaPermissionProvider.overrideWithValue(permService),
          ],
          child: const MaterialApp(
            home: LiveClassroomScreen(sessionId: 'group-session-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Permission denied state on Pre-join
      expect(
        find.text('Quyền Camera & Microphone đang bị từ chối'),
        findsOneWidget,
      );
      await tester.tap(find.text('Mở cài đặt quyền ứng dụng'));
      await tester.pumpAndSettle();
      expect(openedSystemSettings, isTrue);

      // Grant permissions and re-check
      permsGranted = true;
      await tester.tap(find.text('Cấp quyền Camera & Mic'));
      await tester.pumpAndSettle();
      expect(
        find.text('Quyền Camera & Microphone đang bị từ chối'),
        findsNothing,
      );

      // 2. Enter group room
      await tester.ensureVisible(find.text('Vào phòng dạy trực tuyến'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vào phòng dạy trực tuyến'));
      await tester.pumpAndSettle();

      expect(find.text('Người tham gia (3)'), findsOneWidget);
      expect(find.text('Bé Bo'), findsWidgets);
      expect(find.text('Bé Miu'), findsWidgets);

      // 3. Instructor ends session for all
      await tester.tap(find.text('Kết thúc buổi học'));
      await tester.pumpAndSettle();
      expect(find.text('Kết thúc buổi học cho tất cả?'), findsOneWidget);
      await tester.tap(find.text('Kết thúc buổi học').last);
      await tester.pumpAndSettle();
      expect(sessionEnded, isTrue);
    },
  );

  testWidgets(
    'in-app classroom supports screen sharing: OS permission cancel/approve, active banner, stop share keeping call active, student viewer stage with fullscreen, and instructor granting/revoking student permission',
    (tester) async {
      var osPermissionApproved = false;
      var nativeStoppedCount = 0;
      Map<String, dynamic>? activeScreenShare;
      var studentCanShare = false;

      // 1x1 transparent PNG base64 for valid Image.memory rendering
      const validPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

      final screenShareService = _ConfigurableScreenShareService(
        onStart: () async {
          if (!osPermissionApproved) {
            return const LiveScreenShareStartResult(
              started: false,
              reason: 'user_cancelled',
              message: 'Bạn đã hủy hoặc từ chối cấp quyền chia sẻ màn hình.',
            );
          }
          return const LiveScreenShareStartResult(
            started: true,
            width: 1920,
            height: 1080,
            frameBase64: validPngBase64,
          );
        },
        onCaptureFrame: () async => const LiveScreenShareFrame(
          active: true,
          width: 1920,
          height: 1080,
          frameBase64: validPngBase64,
        ),
        onStop: () async {
          nativeStoppedCount++;
        },
      );

      Map<String, dynamic> buildRoomSnapshot() => {
        'connected': true,
        'roomName': 'artkids-session-share-1',
        'canShareScreen': true,
        'screenShare': activeScreenShare,
        'participants': [
          {
            'identity': 'instructor:instructor_test_01',
            'displayName': 'Cô Minh Anh',
            'role': 'instructor',
            'micEnabled': true,
            'cameraEnabled': true,
            'cameraFacing': 'front',
            'connectionState': 'connected',
            'canShareScreen': true,
            'screenSharing': activeScreenShare != null,
          },
          {
            'identity': 'student:child-1',
            'displayName': 'Bé Bo',
            'role': 'student',
            'micEnabled': true,
            'cameraEnabled': true,
            'cameraFacing': 'front',
            'connectionState': 'connected',
            'canShareScreen': studentCanShare,
            'screenSharing': false,
          },
        ],
      };

      final dio = fixtureDio((request) {
        final uri = request.uri;
        if (uri.path.endsWith('/live/sessions/share-session-1/room/token') &&
            request.method == 'POST') {
          return jsonResponse({
            'sessionId': 'share-session-1',
            'classId': 'class-1on1',
            'className': 'Lớp Kèm 1-1 Cọ Nhí C1',
            'sessionTitle': 'Buổi 2: Chia sẻ bài giảng màu nước',
            'capacity': 1,
            'isOneOnOne': true,
            'roomName': 'artkids-session-share-1',
            'roomVersion': 1,
            'roomToken': 'room-jwt-share-inst',
            'participantIdentity': 'instructor:instructor_test_01',
            'participantName': 'Cô Minh Anh',
            'participantRole': 'instructor',
            'permissions': {
              'canPublishAudio': true,
              'canPublishVideo': true,
              'canPublishSources': [
                'camera',
                'microphone',
                'screen_share',
                'screen_share_audio',
              ],
              'canSubscribe': true,
              'canModerateAudio': true,
              'canShareScreen': true,
              'canGrantScreenShare': true,
              'canEndSession': true,
            },
            'sfu': {
              'provider': 'livekit',
              'isConfigured': true,
              'serverUrl': 'wss://livekit.artkids.local',
              'accessToken': 'lk-share-jwt',
              'missingConfigurationKeys': <String>[],
            },
          });
        }
        if (uri.path.endsWith('/live/sessions/share-session-1/room/connect') &&
            request.method == 'POST') {
          return jsonResponse(buildRoomSnapshot());
        }
        if (uri.path.endsWith(
              '/live/sessions/share-session-1/room/screen-share/start',
            ) &&
            request.method == 'POST') {
          final body = Map<String, dynamic>.from(request.data as Map);
          activeScreenShare = {
            'isActive': true,
            'presenterIdentity': 'instructor:instructor_test_01',
            'presenterName': 'Cô Minh Anh',
            'presenterRole': 'instructor',
            'scope': body['scope'] ?? 'entire_screen',
            'contentLabel': body['contentLabel'] ?? 'Toàn màn hình thiết bị',
            'includeDeviceAudio': body['includeDeviceAudio'] == true,
            'width': body['width'] ?? 1920,
            'height': body['height'] ?? 1080,
            'aspectRatio': 1.7778,
            'frameBase64': body['frameBase64'] ?? validPngBase64,
            'sequence': 1,
          };
          return jsonResponse(buildRoomSnapshot());
        }
        if (uri.path.endsWith(
              '/live/sessions/share-session-1/room/screen-share/frame',
            ) &&
            request.method == 'POST') {
          return jsonResponse(buildRoomSnapshot());
        }
        if (uri.path.endsWith(
              '/live/sessions/share-session-1/room/screen-share/stop',
            ) &&
            request.method == 'POST') {
          activeScreenShare = null;
          return jsonResponse(buildRoomSnapshot());
        }
        if (uri.path.endsWith(
              '/live/sessions/share-session-1/room/screen-share/permission',
            ) &&
            request.method == 'POST') {
          final body = Map<String, dynamic>.from(request.data as Map);
          studentCanShare = body['canShareScreen'] == true;
          return jsonResponse(buildRoomSnapshot());
        }
        return jsonResponse(buildRoomSnapshot());
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            authProvider.overrideWith((ref) => _seededInstructorAuth()),
            liveScreenShareProvider.overrideWithValue(screenShareService),
          ],
          child: const MaterialApp(
            home: LiveClassroomScreen(sessionId: 'share-session-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Vào phòng dạy trực tuyến'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vào phòng dạy trực tuyến'));
      await tester.pumpAndSettle();

      // 1. Tap "Chia sẻ màn hình", verify scope dialog, and test OS permission denial/cancel
      expect(find.text('Chia sẻ màn hình'), findsOneWidget);
      await tester.tap(find.text('Chia sẻ màn hình'));
      await tester.pumpAndSettle();

      expect(
        find.text('Xác nhận chia sẻ màn hình'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Camera và Microphone của bạn vẫn hoạt động độc lập',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Tiếp tục & Chọn màn hình'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn đã hủy hoặc từ chối cấp quyền chia sẻ màn hình.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Bạn đang chia sẻ màn hình'),
        findsNothing,
      );

      // 2. Approve OS permission and start sharing screen
      osPermissionApproved = true;
      await tester.tap(find.text('Chia sẻ màn hình'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục & Chọn màn hình'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn đang chia sẻ màn hình · Camera & Mic vẫn hoạt động'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Đang chia sẻ màn hình: Cô Minh Anh'),
        findsOneWidget,
      );
      expect(find.text('Dừng chia sẻ'), findsWidgets);

      // Verify Fullscreen button opens fullscreen viewer and closes cleanly
      await tester.tap(find.byTooltip('Xem toàn màn hình / xoay ngang'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Thoát toàn màn hình'), findsOneWidget);
      await tester.tap(find.byTooltip('Thoát toàn màn hình'));
      await tester.pumpAndSettle();

      // 3. Stop screen sharing -> call remains active and layout returns to video
      await tester.tap(find.text('Dừng chia sẻ').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn đang chia sẻ màn hình · Camera & Mic vẫn hoạt động'),
        findsNothing,
      );
      expect(nativeStoppedCount, greaterThanOrEqualTo(1));
      expect(find.text('Cô Minh Anh (Bạn)'), findsWidgets);
      expect(find.text('Bé Bo'), findsWidgets);

      // 4. Grant and revoke student screen-share permission in Participants sheet
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Người tham gia (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Cấp quyền chia sẻ'), findsOneWidget);
      await tester.tap(find.text('Cấp quyền chia sẻ'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đã cấp quyền chia sẻ màn hình cho Bé Bo.'),
        findsOneWidget,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).clearSnackBars();
      await tester.pumpAndSettle();
    },
  );
}

class _ConfigurableScreenShareService extends LiveScreenShareService {
  _ConfigurableScreenShareService({
    required this.onStart,
    required this.onCaptureFrame,
    required this.onStop,
  });

  final Future<LiveScreenShareStartResult> Function() onStart;
  final Future<LiveScreenShareFrame?> Function() onCaptureFrame;
  final Future<void> Function() onStop;

  @override
  Future<LiveScreenShareCapabilities> getCapabilities() async =>
      const LiveScreenShareCapabilities(
        supported: true,
        platform: 'android',
        supportsSystemScreenShare: true,
        supportsDeviceAudio: true,
        scopeDescription:
            'Toàn bộ màn hình thiết bị Android (MediaProjection).',
        deviceAudioNotice:
            'Âm thanh thiết bị là luồng riêng với microphone đàm thoại.',
      );

  @override
  Future<LiveScreenShareStartResult> startScreenShare({
    bool includeDeviceAudio = false,
  }) => onStart();

  @override
  Future<LiveScreenShareFrame?> captureFrame() => onCaptureFrame();

  @override
  Future<void> stopScreenShare() => onStop();
}

class _ConfigurablePermissionService extends LiveMediaPermissionService {
  const _ConfigurablePermissionService({
    required this.onCheckOrRequest,
    required this.onOpenSettings,
  });

  final LiveMediaPermissionState Function() onCheckOrRequest;
  final Future<bool> Function() onOpenSettings;

  @override
  Future<LiveMediaPermissionState> checkPermissions() async =>
      onCheckOrRequest();

  @override
  Future<LiveMediaPermissionState> requestPermissions() async =>
      onCheckOrRequest();

  @override
  Future<bool> openSystemSettings() => onOpenSettings();
}

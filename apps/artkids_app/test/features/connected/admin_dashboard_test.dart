import 'package:artkids_app/features/auth/domain/entities/parent_user.dart';
import 'package:artkids_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:artkids_app/features/auth/domain/usecases/login_parent.dart';
import 'package:artkids_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:artkids_app/features/connected/data/connected_api.dart';
import 'package:artkids_app/features/connected/presentation/admin_dashboard.dart';
import 'package:artkids_app/features/connected/presentation/workspace_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  for (final role in ['admin', 'instructor']) {
    testWidgets(
      '$role workspace only exposes the relevant dashboard and authoring',
      (tester) async {
        tester.view.physicalSize = Size(role == 'admin' ? 390 : 1000, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = _UnusedRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) =>
                    AuthNotifier(LoginParentUseCase(repository), repository)
                      ..updateUser(
                        ParentUser(
                          id: 'staff',
                          email: 'staff@example.invalid',
                          fullName: 'Test Staff',
                          role: role,
                        ),
                      ),
              ),
              apiDataProvider(AdminDashboard.path).overrideWith((ref) async {
                expect(role, 'admin');
                return {
                  'totalRevenueVnd': 1500000,
                  'monthRevenueVnd': 500000,
                  'revenueMonth': '11/2026',
                  'courseCount': 12,
                  'publishedCourseCount': 10,
                  'paidOrderCount': 8,
                  'pendingOrderCount': 2,
                  'childCount': 30,
                  'pendingProductCount': 3,
                };
              }),
              apiDataProvider('/courses?pageSize=100').overrideWith((
                ref,
              ) async {
                expect(role, 'instructor');
                return {'items': []};
              }),
            ],
            child: const MaterialApp(home: StaffWorkspace()),
          ),
        );
        await tester.pumpAndSettle();
        if (role == 'admin') {
          expect(find.byType(AdminDashboard), findsOneWidget);
          expect(find.text('Tạo khóa học'), findsNothing);
          expect(find.text('Tổng tiền đã nhận'), findsOneWidget);
          expect(find.text('12'), findsOneWidget);
        } else {
          expect(find.byType(AdminDashboard), findsNothing);
          expect(find.text('Tạo khóa học'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

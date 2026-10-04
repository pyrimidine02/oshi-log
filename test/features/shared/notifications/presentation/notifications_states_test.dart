import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/shared/notifications/application/notifications_controller.dart';
import 'package:oshi_log/features/shared/notifications/domain/entities/notification_entities.dart';
import 'package:oshi_log/features/shared/notifications/presentation/pages/notifications_page.dart';
import 'package:oshi_log/platform/notifications/local_notifications_service.dart';

import '../../../../testing/tolerant_local_file_comparator.dart';
import '../../../../testing/platform_golden.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() {
    final original = goldenFileComparator;
    goldenFileComparator = TolerantLocalFileComparator(
      Uri.file(
        '${Directory.current.path}/test/features/shared/notifications/'
        'presentation/notifications_states_test.dart',
      ),
      precisionTolerance: 0.015,
    );
    addTearDown(() => goldenFileComparator = original);
  });
  testWidgets('failed swipe and bulk deletion keep rows and explain retry', (
    tester,
  ) async {
    final local = _Local(null);
    addTearDown(local.dispose);
    late _Notifications controller;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NotificationsPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(false),
          localNotificationsServiceProvider.overrideWithValue(local),
          notificationsControllerProvider.overrideWith(
            (ref) => controller = _Notifications(
              ref,
              AsyncData([
                NotificationItem(
                  id: 'saved',
                  title: 'Keep this notice',
                  body: 'Body',
                  createdAt: DateTime(2026, 10, 4),
                  isRead: true,
                ),
              ]),
            ),
          ),
        ],
        child: _app('ko', router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(controller.deletes, 1);
    expect(find.text('Keep this notice'), findsOneWidget);
    expect(find.text('알림을 삭제하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    expect(controller.deletes, 2);
    expect(find.text('Keep this notice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (locale, brightness) in [
    ('ko', Brightness.light),
    ('ko', Brightness.dark),
    ('ja', Brightness.light),
    ('ja', Brightness.dark),
  ]) {
    for (final compact in [false, true]) {
      final variant =
          '${locale}_${brightness.name}_${compact ? '320_200' : '390_100'}';
      testWidgets('denied permission and unread empty actions fit $variant', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(
          Size(compact ? 320 : 390, compact ? 760 : 844),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final local = _Local(false);
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const NotificationsPage()),
            GoRoute(
              path: '/settings/notifications',
              builder: (_, _) =>
                  const Scaffold(body: Text('settings destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(local.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isAuthenticatedProvider.overrideWithValue(false),
              localNotificationsServiceProvider.overrideWithValue(local),
              notificationsControllerProvider.overrideWith(
                (ref) => _Notifications(
                  ref,
                  AsyncData([
                    NotificationItem(
                      id: 'read',
                      title: 'Read notice',
                      body: 'Body',
                      createdAt: DateTime(2026, 10, 4),
                      isRead: true,
                    ),
                  ]),
                ),
              ),
            ],
            child: _app(
              locale,
              router,
              brightness: brightness,
              textScale: compact ? 2 : 1,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'ko' ? '기기 알림이 꺼져 있어요' : '端末の通知がオフになっています'),
          findsOneWidget,
        );
        expect(local.requests, 0);
        await tester.tap(find.text(locale == 'ko' ? '읽지 않음' : '未読'));
        await tester.pumpAndSettle();
        final all = find.text(locale == 'ko' ? '전체 알림 보기' : 'すべての通知を見る');
        await tester.ensureVisible(all);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('notifications-states-golden')),
          matchesGoldenFile(
            '$platformGoldenDirectory/notifications_denied_unread_empty_$variant.png',
          ),
        );
        await tester.tap(all);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Read notice'));
        await tester.pumpAndSettle();
        expect(find.text('Read notice'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('settings destination'), findsOneWidget);
        expect(local.requests, 0);
        expect(tester.takeException(), isNull);
      });
      testWidgets(
        'unknown permission stays distinct from denied and errors retry $variant',
        (tester) async {
          await tester.binding.setSurfaceSize(
            Size(compact ? 320 : 390, compact ? 760 : 844),
          );
          addTearDown(() => tester.binding.setSurfaceSize(null));
          late _Notifications controller;
          final local = _Local(null);
          addTearDown(local.dispose);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const NotificationsPage()),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                isAuthenticatedProvider.overrideWithValue(false),
                localNotificationsServiceProvider.overrideWithValue(local),
                notificationsControllerProvider.overrideWith(
                  (ref) => controller = _Notifications(
                    ref,
                    AsyncError(
                      const NetworkFailure('offline'),
                      StackTrace.current,
                    ),
                  ),
                ),
              ],
              child: _app(
                locale,
                router,
                brightness: brightness,
                textScale: compact ? 2 : 1,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(locale == 'ko' ? '기기 알림이 꺼져 있어요' : '端末の通知がオフになっています'),
            findsNothing,
          );
          expect(
            find.text(locale == 'ko' ? '알림을 불러오지 못했어요' : '通知を読み込めませんでした'),
            findsOneWidget,
          );
          final retry = find.text(locale == 'ko' ? '다시 시도' : '再試行');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('notifications-states-golden')),
            matchesGoldenFile(
              '$platformGoldenDirectory/notifications_error_$variant.png',
            ),
          );
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(controller.loads, 2);
          expect(controller.forceRefresh, isTrue);
          expect(local.requests, 0);
        },
      );
    }
  }
}

Widget _app(
  String locale,
  GoRouter router, {
  Brightness brightness = Brightness.light,
  double textScale = 2,
}) => MaterialApp.router(
  locale: Locale(locale),
  supportedLocales: const [Locale('ko'), Locale('ja')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: brightness == Brightness.dark
      ? GBTTheme.darkFor(locale)
      : GBTTheme.lightFor(locale),
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: RepaintBoundary(
      key: const ValueKey('notifications-states-golden'),
      child: child!,
    ),
  ),
);

class _Notifications extends NotificationsController {
  _Notifications(super.ref, this.result);
  final AsyncValue<List<NotificationItem>> result;
  int loads = 0;
  bool forceRefresh = false;
  int deletes = 0;
  @override
  Future<Result<void>> deleteNotification(String id) async {
    deletes++;
    return const Result.failure(NetworkFailure('offline'));
  }

  @override
  Future<Result<void>> deleteAllNotifications() async {
    deletes++;
    return const Result.failure(NetworkFailure('offline'));
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {
    loads++;
    this.forceRefresh = forceRefresh;
    state = result;
  }
}

class _Local extends LocalNotificationsService {
  _Local(this.permission);
  final bool? permission;
  int requests = 0;
  @override
  Future<bool?> hasPermission() async => permission;
  @override
  Future<bool> requestPermissions() async {
    requests++;
    return permission ?? false;
  }
}

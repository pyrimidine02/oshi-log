import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/app/compositions/user_profile/presentation/field_user_profile/field_user_profile_page.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/features/identity/account/application/settings_controller.dart';

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
        '${Directory.current.path}/test/features/feed/presentation/'
        'field_user_profile/field_user_profile_states_test.dart',
      ),
      precisionTolerance: 0.015,
    );
    addTearDown(() => goldenFileComparator = original);
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
      for (final (failure, stateName, titleKo, titleJa) in [
        (
          const NotFoundFailure('gone'),
          'deleted',
          '프로필을 찾을 수 없어요',
          'プロフィールが見つかりません',
        ),
        (
          const AuthFailure('private', code: '403'),
          'private',
          '이 프로필을 볼 수 없어요',
          'このプロフィールは表示できません',
        ),
      ]) {
        testWidgets(
          '$stateName profile exits while own profile still loading $variant',
          (tester) async {
            await tester.binding.setSurfaceSize(
              Size(compact ? 320 : 390, compact ? 760 : 844),
            );
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final router = GoRouter(
              initialLocation: '/profile',
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) =>
                      const FieldUserProfilePage(userId: 'other'),
                ),
                GoRoute(
                  path: '/community',
                  builder: (_, _) =>
                      const Scaffold(body: Text('community destination')),
                ),
              ],
            );
            addTearDown(router.dispose);
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  userProfileControllerProvider.overrideWith(
                    (ref) => UserProfileController(ref),
                  ),
                  userProfileByIdProvider(
                    'other',
                  ).overrideWith((ref) => _Profile(ref, failure)),
                ],
                child: MaterialApp.router(
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
                    ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
                    child: RepaintBoundary(
                      key: const ValueKey('profile-states-golden'),
                      child: child!,
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(
              find.text(locale == 'ko' ? titleKo : titleJa),
              findsOneWidget,
            );
            final exit = find.text(locale == 'ko' ? '커뮤니티로 돌아가기' : 'コミュニティに戻る');
            await tester.ensureVisible(exit);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byKey(const ValueKey('profile-states-golden')),
              matchesGoldenFile(
                '$platformGoldenDirectory/profile_${stateName}_$variant.png',
              ),
            );
            await tester.tap(exit);
            await tester.pumpAndSettle();
            expect(find.text('community destination'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

class _Profile extends UserProfileByIdController {
  _Profile(Ref ref, this.failure) : super(ref, 'other');
  final Failure failure;
  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = AsyncError(failure, StackTrace.current);
  }
}

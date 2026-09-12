import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/settings/application/settings_controller.dart';
import 'package:oshi_log/features/settings/domain/entities/user_profile.dart';
import 'package:oshi_log/features/settings/presentation/pages/community_settings_page.dart';

void main() {
  testWidgets(
    'profile actions stack with 48dp targets at 320dp and 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) => true),
            userProfileControllerProvider.overrideWith(
              (ref) => _ReadyUserProfileController(ref),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            supportedLocales: const [Locale('ko')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: GBTTheme.light,
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 760),
                textScaler: TextScaler.linear(2),
              ),
              child: CommunitySettingsPage(),
            ),
          ),
        ),
      );
      await tester.pump();

      final myProfile = find.widgetWithText(FilledButton, '내 프로필');
      final editProfile = find.widgetWithText(OutlinedButton, '프로필 수정');

      expect(myProfile, findsOneWidget);
      expect(editProfile, findsOneWidget);
      expect(tester.getSize(myProfile).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(editProfile).height, greaterThanOrEqualTo(48));
      expect(
        tester.getTopLeft(editProfile).dy,
        greaterThan(tester.getBottomLeft(myProfile).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReadyUserProfileController extends UserProfileController {
  _ReadyUserProfileController(super.ref) {
    state = AsyncData(
      UserProfile(
        id: 'user-1',
        email: 'mari@example.com',
        displayName: '마리',
        role: 'USER',
        accountRole: 'USER',
        baselineAccessLevel: 'USER',
        effectiveAccessLevel: 'USER',
        grants: const [],
        projectRolesByProject: const {},
        createdAt: DateTime.utc(2024, 3, 2),
      ),
    );
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/settings/presentation/widgets/profile_edit_identity_document.dart';

void main() {
  late TextEditingController displayNameController;
  late TextEditingController bioController;

  setUp(() {
    displayNameController = TextEditingController(text: 'Yamada Tabi');
    bioController = TextEditingController(
      text: 'Tokyo live-house field notes.',
    );
  });

  tearDown(() {
    displayNameController.dispose();
    bioController.dispose();
  });

  Future<void> pumpDocument(WidgetTester tester, {double textScale = 1}) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 760),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: ProfileEditIdentityDocument(
              displayNameController: displayNameController,
              bioController: bioController,
              maxDisplayNameLength: 30,
              maxBioLength: 200,
              maskedEmail: 'ya***@example.com',
              accessLabel: 'MEMBER / Traveler',
              memberSinceLabel: 'Member since 2026-01-04',
              hasPendingAvatar: false,
              hasPendingCover: false,
              isUploadingAvatar: false,
              isUploadingCover: false,
              onChangeAvatar: () {},
              onChangeCover: () {},
              onRefresh: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('uses an identity document instead of settings cards', (
    tester,
  ) async {
    await pumpDocument(tester);

    expect(
      find.byKey(const ValueKey('profile-edit-identity-document')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-edit-media-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-edit-basic-fields')),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('keeps media actions usable at 320dp and 200 percent text', (
    tester,
  ) async {
    await pumpDocument(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('profile-edit-change-cover')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('profile-edit-change-avatar')))
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}

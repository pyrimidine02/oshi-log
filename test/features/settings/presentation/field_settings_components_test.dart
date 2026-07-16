import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/settings/presentation/widgets/field_settings_components.dart';

void main() {
  testWidgets('renders document rows without nested card containers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const Scaffold(
          body: FieldSettingsSection(
            title: 'ACCOUNT',
            children: [
              FieldSettingsRow(
                icon: Icons.person_outline,
                title: 'Edit profile',
                subtitle: 'Name, avatar and introduction',
              ),
              FieldSettingsRow(
                icon: Icons.lock_outline,
                title: 'Change password',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Divider), findsOneWidget);
    expect(
      find.byKey(const ValueKey('field-settings-row-Edit profile')),
      findsOneWidget,
    );
  });

  testWidgets('keeps settings rows usable at 320dp and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FieldSettingsSection(
                title: 'PRIVACY AND LEGAL',
                children: [
                  FieldSettingsRow(
                    icon: Icons.gpp_good_outlined,
                    title: 'Privacy and data subject rights',
                    subtitle:
                        'Manage translation, processing restriction, and deletion',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final row = find.byKey(
      const ValueKey('field-settings-row-Privacy and data subject rights'),
    );
    expect(row, findsOneWidget);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}

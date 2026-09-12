import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/sheets/gbt_bottom_sheet.dart';

void main() {
  testWidgets('action menu scrolls to cancel at 320dp and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? result = 'pending';
    await tester.pumpWidget(
      _host((context) async {
        result = await showGBTActionSheet<String>(
          context: context,
          actions: const [
            GBTActionSheetItem(label: '프로필 보기', value: 'profile'),
            GBTActionSheetItem(label: '게시글 수정', value: 'edit'),
            GBTActionSheetItem(
              label: '게시글 삭제',
              value: 'delete',
              isDestructive: true,
            ),
            GBTActionSheetItem(label: '게시글 신고', value: 'report'),
            GBTActionSheetItem(label: '사용자 차단', value: 'block'),
          ],
          cancelLabel: '취소',
        );
      }),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets(
    'sheet sits immediately above keyboard on each platform',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          (context) async {
            await showGBTBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              child: const SizedBox(key: Key('sheet-content'), height: 120),
            );
          },
          platform: debugDefaultTargetPlatformOverride!,
          keyboardInset: 280,
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byKey(const Key('sheet-content'))).dy,
        closeTo(480, 1),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('confirmation actions stay reachable with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool? result;
    await tester.pumpWidget(
      _host((context) async {
        result = await showGBTConfirmationSheet(
          context: context,
          title: '게시글을 삭제할까요?',
          message: '삭제한 여행 기록과 댓글은 다시 복구할 수 없습니다.',
          confirmLabel: '게시글 삭제',
          cancelLabel: '계속 읽기',
          isDestructive: true,
        );
      }),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final action = find.widgetWithText(FilledButton, '게시글 삭제');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

Widget _host(
  Future<void> Function(BuildContext) onOpen, {
  TargetPlatform platform = TargetPlatform.android,
  double keyboardInset = 0,
}) {
  return MaterialApp(
    theme: GBTTheme.light.copyWith(platform: platform),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onOpen(context),
          child: const Text('열기'),
        ),
      ),
    ),
  );
}

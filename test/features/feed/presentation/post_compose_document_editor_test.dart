import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/presentation/widgets/post_compose_components.dart';

void main() {
  group('PostComposeDocumentEditor', () {
    testWidgets('shares title and content field contract', (tester) async {
      final titleController = TextEditingController(text: '기록 제목');
      final contentController = TextEditingController(text: '현장 기록');
      addTearDown(titleController.dispose);
      addTearDown(contentController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostComposeDocumentEditor(
                titleController: titleController,
                contentController: contentController,
                autofocusTitle: false,
                header: const Text('게시 대상'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('게시 대상'), findsOneWidget);
      final titleField = tester.widget<TextField>(
        find.byKey(const ValueKey('post-compose-title')),
      );
      final contentField = tester.widget<TextField>(
        find.byKey(const ValueKey('post-compose-content')),
      );

      expect(titleField.controller, same(titleController));
      expect(titleField.maxLength, 60);
      expect(titleField.textInputAction, TextInputAction.next);
      expect(contentField.controller, same(contentController));
      expect(contentField.maxLength, 3000);
      expect(contentField.minLines, 8);
      expect(contentField.textInputAction, TextInputAction.newline);
    });

    testWidgets('accepts input and remains usable at 320dp with large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final titleController = TextEditingController();
      final contentController = TextEditingController();
      addTearDown(titleController.dispose);
      addTearDown(contentController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: PostComposeDocumentEditor(
                  titleController: titleController,
                  contentController: contentController,
                  autofocusTitle: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('post-compose-title')),
        '신규 여행 기록',
      );
      await tester.enterText(
        find.byKey(const ValueKey('post-compose-content')),
        '공연장에서 남긴 현장 메모',
      );
      await tester.pump();

      expect(titleController.text, '신규 여행 기록');
      expect(contentController.text, '공연장에서 남긴 현장 메모');
      expect(tester.takeException(), isNull);
    });
  });
}

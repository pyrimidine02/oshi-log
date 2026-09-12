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

    testWidgets('can match travel review field limits and hints', (
      tester,
    ) async {
      final titleController = TextEditingController();
      final contentController = TextEditingController();
      addTearDown(titleController.dispose);
      addTearDown(contentController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostComposeDocumentEditor(
              titleController: titleController,
              contentController: contentController,
              autofocusTitle: false,
              titleHintText: '이번 여행은 어떠셨나요?',
              contentHintText: '자세한 후기를 남겨주세요.',
              maxTitleLines: 2,
              minContentLines: 5,
              maxTitleLength: 255,
              maxContentLength: 20000,
            ),
          ),
        ),
      );

      final titleField = tester.widget<TextField>(
        find.byKey(const ValueKey('post-compose-title')),
      );
      final contentField = tester.widget<TextField>(
        find.byKey(const ValueKey('post-compose-content')),
      );

      expect(find.text('이번 여행은 어떠셨나요?'), findsOneWidget);
      expect(find.text('자세한 후기를 남겨주세요.'), findsOneWidget);
      expect(titleField.maxLength, 255);
      expect(titleField.maxLines, 2);
      expect(titleField.textInputAction, TextInputAction.newline);
      expect(contentField.maxLength, 20000);
      expect(contentField.minLines, 5);
    });

    testWidgets('topic sheet stays above keyboard and closes at large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                size: const Size(320, 720),
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 300),
              ),
              child: child!,
            );
          },
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showPostTopicPickerSheet(
                    context,
                    selectedTopic: null,
                    options: const ['성지순례', '공연 후기'],
                  ).then((_) => closed = true);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final closeAction = find.widgetWithText(TextButton, '닫기');
      expect(closeAction, findsOneWidget);
      expect(tester.getSize(closeAction).height, greaterThanOrEqualTo(48));
      expect(tester.getBottomLeft(closeAction).dy, lessThanOrEqualTo(420));

      await tester.tap(closeAction);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'tag sheet returns a selected tag at large text with keyboard',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        String? selectedTag;

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  size: const Size(320, 720),
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 300),
                ),
                child: child!,
              );
            },
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    selectedTag = await showPostTagPickerSheet(
                      context,
                      selectedTags: const ['공연'],
                      suggestions: const ['공연', '성지순례'],
                    );
                  },
                  child: const Text('open-tags'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('open-tags'));
        await tester.pumpAndSettle();

        final closeAction = find.widgetWithText(TextButton, '닫기');
        expect(closeAction, findsOneWidget);
        expect(tester.getSize(closeAction).height, greaterThanOrEqualTo(48));
        expect(tester.getBottomLeft(closeAction).dy, lessThanOrEqualTo(420));

        await tester.tap(find.widgetWithText(ActionChip, '#성지순례'));
        await tester.pumpAndSettle();

        expect(selectedTag, '성지순례');
        expect(tester.takeException(), isNull);
      },
    );

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

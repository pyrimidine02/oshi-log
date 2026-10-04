/// EN: Manual daily ordering and offline text, without claiming offline maps.
/// KO: 수동 당일 순서와 오프라인 텍스트를 보여주며 지도 저장을 암시하지 않습니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/event_time_policy.dart';
import '../application/today_controller.dart';
import '../domain/today_plan.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});
  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !ref.read(todayControllerProvider).isSaving) {
      ref.read(todayControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(context.l10n(ko: '오늘 목록', en: 'Today list', ja: '今日のリスト')),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.accountRequired
            ? Center(
                child: Text(
                  context.l10n(
                    ko: '로그인한 계정을 다시 확인해주세요.',
                    en: 'Please check your signed-in account.',
                    ja: 'ログイン中のアカウントを確認してください。',
                  ),
                ),
              )
            : state.plan == null
            ? Center(
                child: TextButton(
                  onPressed: controller.load,
                  child: Text(
                    context.l10n(
                      ko: '목록을 불러오지 못했어요. 다시 시도',
                      en: 'Could not load the list. Retry',
                      ja: 'リストを読み込めませんでした。再試行',
                    ),
                  ),
                ),
              )
            : TodayPlaceList(
                state: state,
                onMove: controller.move,
                onToggleSkipped: controller.toggleSkipped,
                onRemove: controller.remove,
                onDownload: controller.downloadText,
                onOpenText: (text) => showTodayText(context, text),
                onStartToday: () => _confirmReset(context, controller),
                onBrowsePlaces: () => context.goNamed(AppRoutes.map),
              ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    TodayController controller,
  ) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n(
            ko: '오늘 목록을 새로 시작할까요?',
            en: 'Start a new list for today?',
            ja: '今日のリストを新しくしますか？',
          ),
        ),
        content: Text(
          context.l10n(
            ko: '이 목록의 장소와 저장 텍스트를 지웁니다. 방문 기록은 그대로 남아요.',
            en: 'This clears this list and its saved text. Visit records stay unchanged.',
            ja: 'このリストの場所と保存テキストを消去します。訪問記録は残ります。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n(ko: '새로 시작', en: 'Start new', ja: '新しくする'),
            ),
          ),
        ],
      ),
    );
    if (reset == true && mounted) await controller.startToday();
  }
}

class TodayPlaceList extends StatelessWidget {
  const TodayPlaceList({
    super.key,
    required this.state,
    required this.onMove,
    required this.onToggleSkipped,
    required this.onRemove,
    required this.onDownload,
    required this.onOpenText,
    required this.onStartToday,
    required this.onBrowsePlaces,
  });
  final TodayState state;
  final void Function(int, int) onMove;
  final ValueChanged<String> onToggleSkipped;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onDownload;
  final ValueChanged<TodayTextSnapshot> onOpenText;
  final VoidCallback onStartToday;
  final VoidCallback onBrowsePlaces;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan!;
    final previousDate = plan.date != todayDateKey(DateTime.now());
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.date} JST',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  context.l10n(
                    ko: '이 계정의 이 기기에만 저장됩니다. 순서는 직접 바꿀 수 있어요.',
                    en: 'Saved on this device for this account. Set your own order.',
                    ja: 'このアカウントのこの端末に保存されます。順番は手動で変更できます。',
                  ),
                ),
                if (previousDate)
                  Text(
                    context.l10n(
                      ko: '이전 날짜의 목록입니다. 새 날을 시작하려면 아래에서 초기화해주세요.',
                      en: 'This is an earlier dated list. Start a new list below for today.',
                      ja: '別の日付のリストです。今日のリストは下から新しくできます。',
                    ),
                  ),
                if (state.failure != null)
                  Text(
                    context.l10n(
                      ko: '저장·갱신에 실패했어요. 마지막으로 저장된 내용을 유지합니다.',
                      en: 'Save or update failed. The last saved content is retained.',
                      ja: '保存・更新に失敗しました。最後に保存した内容を保持しています。',
                    ),
                    key: const Key('today-save-failure'),
                  ),
                Wrap(
                  spacing: GBTSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onBrowsePlaces,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(
                        context.l10n(
                          ko: '지도에서 장소 선택',
                          en: 'Choose places on the map',
                          ja: '地図で場所を選ぶ',
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('today-reset'),
                      onPressed: state.isSaving ? null : onStartToday,
                      child: Text(
                        context.l10n(
                          ko: '오늘 목록 새로 시작',
                          en: 'Start a new today list',
                          ja: '今日のリストを新しくする',
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.isSaving) const LinearProgressIndicator(),
                if (plan.entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GBTSpacing.lg,
                    ),
                    child: Text(
                      context.l10n(
                        ko: '장소 상세에서 「오늘 목록에 추가」를 눌러주세요.',
                        en: 'Choose “Add to today list” on a place detail.',
                        ja: '場所の詳細で「今日のリストに追加」を押してください。',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: plan.entries.length,
          itemBuilder: (context, index) {
            final entry = plan.entries[index];
            return Padding(
              key: ValueKey('today-${entry.key}'),
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.md,
                vertical: GBTSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  Semantics(
                    header: true,
                    child: Text(
                      '${index + 1}. ${entry.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(entry.address),
                  Text(
                    entry.skipped
                        ? context.l10n(ko: '건너뛰기', en: 'Skipped', ja: 'スキップ')
                        : context.l10n(
                            ko: '방문 후보 · 방문 인증 아님',
                            en: 'Planned stop · not a verified visit',
                            ja: '訪問候補・訪問認証ではありません',
                          ),
                  ),
                  Wrap(
                    spacing: GBTSpacing.xs,
                    children: [
                      IconButton(
                        key: ValueKey('today-up-${entry.key}'),
                        tooltip: context.l10n(
                          ko: '위로 이동',
                          en: 'Move up',
                          ja: '上へ移動',
                        ),
                        onPressed: state.isSaving || index == 0
                            ? null
                            : () => onMove(index, index - 1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        key: ValueKey('today-down-${entry.key}'),
                        tooltip: context.l10n(
                          ko: '아래로 이동',
                          en: 'Move down',
                          ja: '下へ移動',
                        ),
                        onPressed:
                            state.isSaving || index == plan.entries.length - 1
                            ? null
                            : () => onMove(index, index + 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      TextButton(
                        key: ValueKey('today-skip-${entry.key}'),
                        onPressed: state.isSaving
                            ? null
                            : () => onToggleSkipped(entry.key),
                        child: Text(
                          entry.skipped
                              ? context.l10n(
                                  ko: '다시 포함',
                                  en: 'Include again',
                                  ja: '再び含める',
                                )
                              : context.l10n(
                                  ko: '건너뛰기',
                                  en: 'Skip',
                                  ja: 'スキップ',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: state.isSaving
                            ? null
                            : () => onRemove(entry.key),
                        child: Text(
                          context.l10n(
                            ko: '목록에서 제거',
                            en: 'Remove from list',
                            ja: 'リストから削除',
                          ),
                        ),
                      ),
                    ],
                  ),
                  DownloadStatusRow(
                    entry: entry,
                    failed: state.failedDownloads.contains(entry.key),
                  ),
                  Wrap(
                    spacing: GBTSpacing.sm,
                    children: [
                      TextButton(
                        key: ValueKey('today-download-${entry.key}'),
                        onPressed: state.isSaving
                            ? null
                            : () => onDownload(entry.key),
                        child: Text(
                          entry.text == null
                              ? context.l10n(
                                  ko: '텍스트 저장',
                                  en: 'Save text offline',
                                  ja: 'テキストを保存',
                                )
                              : context.l10n(
                                  ko: '텍스트 갱신',
                                  en: 'Update saved text',
                                  ja: '保存テキストを更新',
                                ),
                        ),
                      ),
                      if (entry.text != null)
                        TextButton(
                          key: ValueKey('today-read-${entry.key}'),
                          onPressed: () => onOpenText(entry.text!),
                          child: Text(
                            context.l10n(
                              ko: '저장 텍스트 읽기',
                              en: 'Read saved text',
                              ja: '保存テキストを読む',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: GBTSpacing.bottomNavClearanceOf(context)),
        ),
      ],
    );
  }
}

class DownloadStatusRow extends StatelessWidget {
  const DownloadStatusRow({
    super.key,
    required this.entry,
    required this.failed,
  });
  final TodayPlace entry;
  final bool failed;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (failed)
        Text(
          context.l10n(
            ko: '텍스트 갱신 실패 · 다시 시도할 수 있어요',
            en: 'Text update failed · retry available',
            ja: 'テキスト更新に失敗・再試行できます',
          ),
        ),
      Text(
        entry.text == null
            ? context.l10n(
                ko: '상세 텍스트 미저장',
                en: 'Detail text not saved',
                ja: '詳細テキストは未保存',
              )
            : context.l10n(
                ko: '텍스트 저장 완료 · ${_savedAt(entry.text!)} JST',
                en: 'Text saved · ${_savedAt(entry.text!)} JST',
                ja: 'テキスト保存済み・${_savedAt(entry.text!)} JST',
              ),
      ),
    ],
  );
}

String _savedAt(TodayTextSnapshot text) =>
    DateFormat('yyyy-MM-dd HH:mm').format(EventTimePolicy.inJst(text.savedAt));

Future<void> showTodayText(BuildContext context, TodayTextSnapshot text) {
  final content = [
    text.name,
    text.address,
    if (text.description?.trim().isNotEmpty == true) text.description!,
    '${_savedAt(text)} JST',
  ].join('\n\n');
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n(ko: '저장한 텍스트', en: 'Saved text', ja: '保存テキスト'),
          ),
          leading: IconButton(
            tooltip: context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n(
                    ko: '저장한 이름·주소·설명만 오프라인에서 볼 수 있어요. 지도는 포함하지 않습니다. 주의·연락처는 설명에 제공된 범위만 확인할 수 있어요.',
                    en: 'Only saved name, address and description are available offline. Maps are not included. Notices and contacts are available only where included in the description.',
                    ja: '保存した名前・住所・説明だけをオフラインで読めます。地図は含みません。注意事項・連絡先は説明に記載された範囲のみ確認できます。',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                SelectableText(content),
                const SizedBox(height: GBTSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: content)),
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(
                    context.l10n(
                      ko: '저장 텍스트 복사',
                      en: 'Copy saved text',
                      ja: '保存テキストをコピー',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

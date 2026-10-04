import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import '../application/private_trips_controller.dart';
import '../domain/private_trip.dart';

/// EN: Every public field starts unchecked; closing has no export side effect.
/// KO: 공개할 항목은 모두 선택 해제로 시작하며 닫기는 내보내기를 수행하지 않습니다.
class PublishSelectionSheet extends ConsumerStatefulWidget {
  const PublishSelectionSheet({super.key, required this.trip});
  final PrivateTrip trip;
  @override
  ConsumerState<PublishSelectionSheet> createState() =>
      _PublishSelectionSheetState();
}

class _PublishSelectionSheetState extends ConsumerState<PublishSelectionSheet> {
  final _entries = <String>{};
  final _photos = <String>{};
  bool _dates = false;
  bool _busy = false;
  String? _error;
  late final PrivateTripsController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ref.read(privateTripsControllerProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(privateTripsControllerProvider);
    final ownerMatches = identical(
      _controller,
      ref.read(privateTripsControllerProvider.notifier),
    );
    final hasPlace = widget.trip.entries.any(
      (e) => e.place != null && _entries.contains(e.id),
    );
    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '공개할 항목 선택',
          en: 'Choose what to share',
          ja: '公開する項目を選択',
        ),
      ),
      body: !ownerMatches || current.hasError
          ? Center(
              child: Text(
                context.l10n(
                  ko: '계정이 바뀌었어요. 앨범을 다시 열어주세요.',
                  en: 'Account changed. Reopen your album.',
                  ja: 'アカウントが変わりました。アルバムを開き直してください。',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(GBTSpacing.md),
              children: [
                Text(
                  context.l10n(
                    ko: '지금은 공개하지 않습니다. 다음 작성 화면에서 최종 공개합니다. 비공개 제목과 메모는 전달하지 않아요.',
                    en: 'Nothing is published now. Publish from the next editor. Your private title and memo stay here.',
                    ja: 'ここでは公開されません。次の作成画面で最終公開します。非公開のタイトルとメモは引き継ぎません。',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  context.l10n(
                    ko: '장소 1–20개 · 공연 최대 10개 (선택)',
                    en: '1–20 places · up to 10 optional events',
                    ja: '場所1〜20件・公演は任意で10件まで',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final entry in widget.trip.entries)
                  CheckboxListTile(
                    key: ValueKey('publish-entry-${entry.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.title),
                    subtitle: entry.place == null && entry.event == null
                        ? Text(
                            context.l10n(
                              ko: '공개에 필요한 정보가 없어요',
                              en: 'Missing information for sharing',
                              ja: '公開に必要な情報がありません',
                            ),
                          )
                        : null,
                    value: _entries.contains(entry.id),
                    onChanged:
                        _busy || (entry.place == null && entry.event == null)
                        ? null
                        : (value) => setState(() {
                            value == true
                                ? _entries.add(entry.id)
                                : _entries.remove(entry.id);
                          }),
                  ),
                const Divider(),
                CheckboxListTile(
                  key: const ValueKey('publish-dates'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n(
                      ko: '확인한 여행 날짜 포함',
                      en: 'Include confirmed travel dates',
                      ja: '確認済みの旅行日を含める',
                    ),
                  ),
                  subtitle: Text(
                    widget.trip.datesConfirmed
                        ? '${widget.trip.startedOn!.toIso8601String().split('T').first} – ${widget.trip.endedOn!.toIso8601String().split('T').first}'
                        : context.l10n(
                            ko: '앨범에서 날짜를 먼저 확인하세요',
                            en: 'Confirm dates in your album first',
                            ja: 'アルバムで先に日付を確認してください',
                          ),
                  ),
                  value: _dates,
                  onChanged: _busy || !widget.trip.datesConfirmed
                      ? null
                      : (value) => setState(() => _dates = value ?? false),
                ),
                const Divider(),
                Text(
                  context.l10n(
                    ko: '사진 최대 10장 · 위치정보를 지운 복사본만 전달',
                    en: 'Up to 10 photos · copies without location metadata',
                    ja: '写真10枚まで・位置情報を除いたコピーのみ渡します',
                  ),
                ),
                for (final photo in widget.trip.photos)
                  CheckboxListTile(
                    key: ValueKey('publish-photo-${photo.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Image.file(
                      File(photo.path),
                      height: 120,
                      cacheWidth: 320,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                    subtitle: Text(
                      context.l10n(
                        ko: '사진 포함',
                        en: 'Include photo',
                        ja: '写真を含める',
                      ),
                    ),
                    value: _photos.contains(photo.id),
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            value == true
                                ? _photos.add(photo.id)
                                : _photos.remove(photo.id);
                          }),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GBTSpacing.md,
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: GBTSpacing.md),
                FilledButton(
                  key: const ValueKey('publish-continue'),
                  onPressed: _busy || !hasPlace
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _error = null;
                          });
                          try {
                            final seed = await _controller.prepareSelection(
                              trip: widget.trip,
                              entryIds: _entries,
                              photoIds: _photos,
                              includeDates: _dates,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(seed);
                            } else {
                              await _controller.deleteExports(seed);
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => _error = context.l10n(
                                  ko: '항목과 계정을 확인해주세요. 장소 1–20개, 공연 10개, 사진 10장까지 선택할 수 있어요.',
                                  en: 'Check your selection and account. Select 1–20 places, up to 10 events and 10 photos.',
                                  ja: '選択内容とアカウントを確認してください。場所1〜20件、公演10件、写真10枚まで選べます。',
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(
                    context.l10n(
                      ko: '선택한 항목으로 공개 글 작성',
                      en: 'Write a public review with selected items',
                      ja: '選択した項目で公開レポを作成',
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('publish-decline'),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    context.l10n(
                      ko: '비공개로 유지',
                      en: 'Keep private',
                      ja: '非公開のままにする',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

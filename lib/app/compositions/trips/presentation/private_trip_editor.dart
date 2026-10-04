import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review_selection_seed.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import '../application/private_trips_controller.dart';
import '../application/trip_candidates.dart';
import '../domain/private_trip.dart';
import 'publish_selection_sheet.dart';

class PrivateTripEditor extends ConsumerStatefulWidget {
  const PrivateTripEditor({super.key, required this.trip});
  final PrivateTrip trip;
  @override
  ConsumerState<PrivateTripEditor> createState() => _PrivateTripEditorState();
}

class _PrivateTripEditorState extends ConsumerState<PrivateTripEditor> {
  late PrivateTrip _trip;
  late final TextEditingController _title;
  late final TextEditingController _memo;
  late final PrivateTripsController _controller;
  final _splitEntries = <String>{};
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _title = TextEditingController(text: _trip.title);
    _memo = TextEditingController(text: _trip.memo);
    _controller = ref.read(privateTripsControllerProvider.notifier);
  }

  @override
  void dispose() {
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = context.l10n(
            ko: '저장하지 못했어요. 계정과 입력을 확인하고 다시 시도해주세요. 사진은 32MB까지 가능합니다.',
            en: 'Could not save. Check your account and entries, then retry. Photos must be under 32 MB.',
            ja: '保存できませんでした。アカウントと入力を確認して再試行してください。写真は32MBまでです。',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) throw ArgumentError('Title required');
    _trip = _trip.copyWith(title: _title.text.trim(), memo: _memo.text);
    await _controller.upsert(_trip);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privateTripsControllerProvider);
    final ownerMatches = identical(
      _controller,
      ref.read(privateTripsControllerProvider.notifier),
    );
    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '비공개 여행 편집',
          en: 'Edit private trip',
          ja: '非公開の旅を編集',
        ),
      ),
      body: !ownerMatches || state.hasError
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
                    ko: '이 기기에만 저장 · ${_trip.projectKey}',
                    en: 'Saved on this device · ${_trip.projectKey}',
                    ja: 'この端末だけに保存・${_trip.projectKey}',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                TextField(
                  key: const ValueKey('private-trip-title'),
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: context.l10n(
                      ko: '비공개 제목',
                      en: 'Private title',
                      ja: '非公開タイトル',
                    ),
                  ),
                ),
                TextField(
                  key: const ValueKey('private-trip-memo'),
                  controller: _memo,
                  enabled: !_busy,
                  maxLength: 10000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: context.l10n(
                      ko: '나만 보는 메모',
                      en: 'Private memo',
                      ja: '自分だけのメモ',
                    ),
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  _trip.datesConfirmed
                      ? '${_trip.startedOn!.toIso8601String().split('T').first} – ${_trip.endedOn!.toIso8601String().split('T').first}'
                      : context.l10n(
                          ko: '여행 날짜 확인 필요 · 인증 시각은 여행 날짜가 아니에요.',
                          en: 'Confirm travel dates. Check-in timestamps are not travel dates.',
                          ja: '旅行日を確認してください。認証時刻は旅行日ではありません。',
                        ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('private-trip-dates'),
                  onPressed: _busy
                      ? null
                      : () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                            initialDateRange: _trip.datesConfirmed
                                ? DateTimeRange(
                                    start: _trip.startedOn!,
                                    end: _trip.endedOn!,
                                  )
                                : null,
                          );
                          if (range != null && mounted) {
                            setState(
                              () => _trip = _trip.copyWith(
                                startedOn: range.start,
                                endedOn: range.end,
                                datesConfirmed: true,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    context.l10n(
                      ko: '여행 날짜 직접 확인',
                      en: 'Confirm travel dates',
                      ja: '旅行日を自分で確認',
                    ),
                  ),
                ),
                const Divider(),
                for (final entry in _trip.entries)
                  CheckboxListTile(
                    key: ValueKey('split-entry-${entry.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.title),
                    subtitle: Text(
                      entry.verified
                          ? context.l10n(
                              ko: '위치 인증 기록',
                              en: 'Location-verified record',
                              ja: '位置認証済みの記録',
                            )
                          : context.l10n(
                              ko: '참고 기록 · 위치 인증 아님',
                              en: 'Reference record · not location verified',
                              ja: '参考記録・位置認証ではありません',
                            ),
                    ),
                    value: _splitEntries.contains(entry.id),
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            value == true
                                ? _splitEntries.add(entry.id)
                                : _splitEntries.remove(entry.id);
                          }),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final place =
                              await showModalBottomSheet<PlaceSummary>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) =>
                                    _TripPlacePicker(project: _trip.projectKey),
                              );
                          if (place == null || !mounted) return;
                          await _run(() async {
                            await _controller.assertSession();
                            if (_trip.entries.any(
                              (e) =>
                                  e.kind == TripEntryKind.place &&
                                  e.resourceId == place.id,
                            )) {
                              return;
                            }
                            setState(
                              () => _trip = _trip.copyWith(
                                entries: [
                                  ..._trip.entries,
                                  PrivateTripEntry(
                                    id: 'manual:${const Uuid().v4()}',
                                    resourceId: place.id,
                                    title: place.name,
                                    kind: TripEntryKind.place,
                                    projectKey: _trip.projectKey,
                                    place: place,
                                  ),
                                ],
                              ),
                            );
                          });
                        },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(
                    context.l10n(ko: '장소 추가', en: 'Add place', ja: '場所を追加'),
                  ),
                ),
                if (_trip.entries.length > 1)
                  OutlinedButton(
                    key: const ValueKey('private-trip-split'),
                    onPressed:
                        _busy ||
                            _splitEntries.isEmpty ||
                            _splitEntries.length == _trip.entries.length
                        ? null
                        : () => _run(() async {
                            await _save();
                            final split = _trip.split(
                              _splitEntries,
                              newId: const Uuid().v4(),
                            );
                            await _controller.replace([
                              for (final t
                                  in ref
                                      .read(privateTripsControllerProvider)
                                      .requireValue)
                                if (t.id == _trip.id) split.$1 else t,
                              split.$2,
                            ]);
                            if (mounted) {
                              setState(() {
                                _trip = split.$1;
                                _splitEntries.clear();
                              });
                            }
                          }),
                    child: Text(
                      context.l10n(
                        ko: '선택한 기록을 새 여행으로 분리',
                        en: 'Split selected records into a new trip',
                        ja: '選択した記録を新しい旅に分割',
                      ),
                    ),
                  ),
                Text(
                  context.l10n(
                    ko: '분리할 기록만 체크하세요. 메모와 사진은 원래 여행에 남아요.',
                    en: 'Check only records to split. Memo and photos stay in the original trip.',
                    ja: '分割する記録だけを選んでください。メモと写真は元の旅に残ります。',
                  ),
                ),
                const Divider(),
                for (final photo in _trip.photos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
                    child: Image.file(
                      File(photo.path),
                      height: 160,
                      cacheWidth: 640,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Text(
                        context.l10n(
                          ko: '사진을 읽지 못했어요',
                          en: 'Photo unavailable',
                          ja: '写真を読み込めませんでした',
                        ),
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('private-trip-photo'),
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked == null || !mounted) return;
                          final updated = await _controller.addPhoto(
                            _trip.copyWith(
                              title: _title.text.trim(),
                              memo: _memo.text,
                            ),
                            picked.path,
                          );
                          if (mounted) setState(() => _trip = updated);
                        }),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    context.l10n(
                      ko: '비공개 사진 추가',
                      en: 'Add private photo',
                      ja: '非公開写真を追加',
                    ),
                  ),
                ),
                if (_busy) const LinearProgressIndicator(),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GBTSpacing.md,
                    ),
                    child: Text(_message!),
                  ),
                const SizedBox(height: GBTSpacing.md),
                FilledButton(
                  key: const ValueKey('private-trip-save'),
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await _save();
                          if (mounted) {
                            setState(
                              () => _message = context.l10n(
                                ko: '이 기기에 비공개로 저장했어요',
                                en: 'Saved privately on this device',
                                ja: 'この端末に非公開で保存しました',
                              ),
                            );
                          }
                        }),
                  child: Text(
                    context.l10n(
                      ko: '비공개로 저장',
                      en: 'Save privately',
                      ja: '非公開で保存',
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey('private-trip-publish'),
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await _save();
                          if (!context.mounted) return;
                          final seed = await Navigator.of(context)
                              .push<TravelReviewSelectionSeed>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PublishSelectionSheet(trip: _trip),
                                ),
                              );
                          if (seed != null) {
                            try {
                              await _controller.assertSession();
                              if (context.mounted) {
                                await context.pushNamed(
                                  AppRoutes.travelReviewCreate,
                                  extra: seed,
                                );
                              }
                            } finally {
                              await _controller.deleteExports(seed);
                            }
                          }
                        }),
                  child: Text(
                    context.l10n(
                      ko: '공개할 항목 고르기',
                      en: 'Choose what to publish',
                      ja: '公開する項目を選ぶ',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TripPlacePicker extends ConsumerStatefulWidget {
  const _TripPlacePicker({required this.project});
  final String project;
  @override
  ConsumerState<_TripPlacePicker> createState() => _TripPlacePickerState();
}

class _TripPlacePickerState extends ConsumerState<_TripPlacePicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final places = ref.watch(tripPlacesProvider(widget.project));
    return FractionallySizedBox(
      heightFactor: .85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: context.l10n(
                  ko: '장소 검색',
                  en: 'Search places',
                  ja: '場所を検索',
                ),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase().trim()),
            ),
            Expanded(
              child: places.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(tripPlacesProvider(widget.project)),
                    child: Text(
                      context.l10n(ko: '다시 불러오기', en: 'Retry', ja: '再読み込み'),
                    ),
                  ),
                ),
                data: (items) {
                  final filtered = items
                      .where((p) => p.name.toLowerCase().contains(_query))
                      .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n(
                          ko: '해당 장소가 없어요',
                          en: 'No places found',
                          ja: '場所が見つかりません',
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final place = filtered[index];
                      return ListTile(
                        title: Text(place.name),
                        subtitle: Text(place.address),
                        onTap: () => Navigator.of(context).pop(place),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/design_system/theme/gbt_map_styles.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/design_system/widgets/layout/gbt_page_header.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/fan_subject.dart';
import 'package:oshi_log/features/place/visits/application/visits_controller.dart';
import 'package:oshi_log/features/place/visits/domain/entities/visit_entities.dart';
import 'package:oshi_log/features/community/reviews/application/travel_reviews_controller.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review_selection_seed.dart';
import 'package:oshi_log/features/shared/uploads/application/uploads_controller.dart';
import 'package:oshi_log/design_system/widgets/compose/post_compose_document_editor.dart';
import 'package:oshi_log/features/community/reviews/presentation/widgets/travel_review_compose_sections.dart';
import 'package:oshi_log/features/community/reviews/presentation/widgets/travel_review_place_picker_sheet.dart';

/// EN: Returns a reordered copy using Flutter's legacy onReorder indices.
/// KO: Flutter의 기존 onReorder 인덱스 규칙으로 재정렬한 복사본을 반환합니다.
List<T> reorderTravelReviewItems<T>(List<T> items, int oldIndex, int newIndex) {
  final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
  final reordered = List<T>.of(items);
  final item = reordered.removeAt(oldIndex);
  reordered.insert(adjustedNewIndex, item);
  return List<T>.unmodifiable(reordered);
}

/// EN: Returns an immutable copy with one item appended.
/// KO: 항목 하나를 뒤에 추가한 불변 복사본을 반환합니다.
List<T> appendTravelReviewItem<T>(List<T> items, T item) {
  return List<T>.unmodifiable([...items, item]);
}

/// EN: Returns an immutable copy without the item at [index].
/// KO: [index]의 항목을 제외한 불변 복사본을 반환합니다.
List<T> removeTravelReviewItem<T>(List<T> items, int index) {
  return List<T>.unmodifiable([...items.take(index), ...items.skip(index + 1)]);
}

/// EN: Travel Review creation page.
/// KO: 여행 후기 작성 페이지.
class TravelReviewCreatePage extends ConsumerStatefulWidget {
  const TravelReviewCreatePage({super.key, this.selectionSeed});

  final TravelReviewSelectionSeed? selectionSeed;

  @override
  ConsumerState<TravelReviewCreatePage> createState() =>
      _TravelReviewCreatePageState();
}

class _TravelReviewCreatePageState
    extends ConsumerState<TravelReviewCreatePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _routeNoteController = TextEditingController();

  // EN: Selected places for the review
  // KO: 후기에 선택된 장소들
  List<PlaceSummary> _selectedPlaces = [];
  final List<LiveEventSummary> _selectedEvents = [];
  final List<FanSubject> _selectedSubjects = [];

  DateTime? _tripStartedOn;
  DateTime? _tripEndedOn;

  bool _isSubmitting = false;
  bool _seedReady = false;
  bool _seedRejected = false;
  int? _seedSessionGeneration;
  final List<String> _selectedPhotoPaths = [];
  final Map<String, String> _uploadedPhotoIds = {};

  bool get _isAppleMap => !kIsWeb && Platform.isIOS;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _selectedPlaces.isNotEmpty &&
      _seedReady &&
      !_seedRejected &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateState);
    _contentController.addListener(_updateState);
    _seedReady = widget.selectionSeed == null;
    if (!_seedReady) unawaited(_applySelectionSeed());
  }

  Future<bool> _seedMatchesSession() async {
    if (!mounted) return false;
    final seed = widget.selectionSeed;
    if (seed == null) return true;
    final generation = ref.read(apiSessionGenerationProvider)();
    final owner = await ref.read(secureStorageProvider).getUserId();
    if (!mounted) return false;
    return seed.ownerUserId.trim().isNotEmpty &&
        owner == seed.ownerUserId &&
        ref.read(isAuthenticatedProvider) &&
        ref.read(selectedProjectKeyProvider)?.trim() ==
            seed.projectCode.trim() &&
        ref.read(apiSessionGenerationProvider)() == generation &&
        (_seedSessionGeneration == null ||
            _seedSessionGeneration == generation);
  }

  Future<void> _applySelectionSeed() async {
    final seed = widget.selectionSeed!;
    try {
      if (!await _seedMatchesSession()) {
        if (mounted) setState(() => _seedRejected = true);
        return;
      }
      if (!mounted) return;
      setState(() {
        _seedSessionGeneration = ref.read(apiSessionGenerationProvider)();
        _selectedPlaces = seed.places.toList();
        _selectedEvents.addAll(seed.events);
        _tripStartedOn = seed.tripStartedOn;
        _tripEndedOn = seed.tripEndedOn;
        _selectedPhotoPaths.addAll(seed.photoPaths.toSet());
        _seedReady = true;
      });
    } catch (_) {
      if (mounted) setState(() => _seedRejected = true);
    }
  }

  Future<bool> _checkSeedBeforePublishing() async {
    if (_seedRejected) return false;
    if (await _seedMatchesSession()) return true;
    if (mounted) setState(() => _seedRejected = true);
    return false;
  }

  Future<List<String>?> _uploadSelectedPhotos() async {
    final ids = <String>[];
    for (final path in _selectedPhotoPaths) {
      if (!await _checkSeedBeforePublishing()) return null;
      var uploadId = _uploadedPhotoIds[path];
      if (uploadId == null) {
        final bytes = await File(path).readAsBytes();
        if (!await _checkSeedBeforePublishing()) return null;
        final result = await ref
            .read(uploadsControllerProvider.notifier)
            .uploadImageBytes(
              bytes: bytes,
              filename: 'travel-review-photo-${ids.length + 1}.png',
              contentType: 'image/png',
              isCurrentOperation: () =>
                  mounted &&
                  !_seedRejected &&
                  ref.read(isAuthenticatedProvider) &&
                  ref.read(selectedProjectKeyProvider)?.trim() ==
                      widget.selectionSeed?.projectCode.trim() &&
                  ref.read(apiSessionGenerationProvider)() ==
                      _seedSessionGeneration,
            );
        if (!mounted || !await _checkSeedBeforePublishing()) return null;
        switch (result) {
          case Success(:final data):
            uploadId = data.uploadId.trim();
            if (uploadId.isEmpty) throw StateError('Missing upload ID');
            _uploadedPhotoIds[path] = uploadId;
          case Err():
            throw StateError('Photo upload failed');
        }
      }
      ids.add(uploadId);
    }
    return ids;
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_updateState);
    _contentController.removeListener(_updateState);
    _titleController.dispose();
    _contentController.dispose();
    _routeNoteController.dispose();
    super.dispose();
  }

  void _addPlace(PlaceSummary place) {
    if (_selectedPlaces.length >= 20 &&
        !_selectedPlaces.any((selected) => selected.id == place.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '방문 장소는 최대 20곳까지 추가할 수 있어요.',
              en: 'You can add up to 20 places.',
              ja: '訪問場所は最大20件まで追加できます。',
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      if (!_selectedPlaces.any((p) => p.id == place.id)) {
        _selectedPlaces = appendTravelReviewItem(_selectedPlaces, place);
      }
    });
    if (ref.read(userVisitsControllerProvider).valueOrNull == null) {
      unawaited(ref.read(userVisitsControllerProvider.notifier).load());
    }
  }

  void _removePlace(int index) {
    setState(() {
      _selectedPlaces = removeTravelReviewItem(_selectedPlaces, index);
    });
  }

  void _reorderPlaces(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPlaces = reorderTravelReviewItems(
        _selectedPlaces,
        oldIndex,
        newIndex,
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_seedReady || _seedRejected) return;
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '제목과 내용을 입력해주세요',
              en: 'Please enter a title and content.',
              ja: 'タイトルと内容を入力してください。',
            ),
          ),
        ),
      );
      return;
    }
    if (_selectedPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '최소 1개 이상의 장소를 추가해주세요',
              en: 'Please add at least one place.',
              ja: '場所を1件以上追加してください。',
            ),
          ),
        ),
      );
      return;
    }

    final projectCode = ref.read(selectedProjectKeyProvider)?.trim();
    if (projectCode == null || projectCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '여행을 기록할 프로젝트를 먼저 선택해주세요.',
              en: 'Please select a project to record this trip.',
              ja: '旅の記録先プロジェクトを先に選択してください。',
            ),
          ),
        ),
      );
      return;
    }
    if (_tripStartedOn != null &&
        _tripEndedOn != null &&
        _tripEndedOn!.isBefore(_tripStartedOn!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '종료일은 시작일보다 빠를 수 없어요.',
              en: 'The end date cannot be before the start date.',
              ja: '終了日は開始日より前にできません。',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (!await _checkSeedBeforePublishing()) return;
      if (ref.read(userVisitsControllerProvider).valueOrNull == null) {
        await ref.read(userVisitsControllerProvider.notifier).load();
        if (!mounted) return;
      }
      final visits =
          ref.read(userVisitsControllerProvider).valueOrNull ??
          const <VisitEvent>[];
      final attendanceRecords = await _loadAttendanceProofRecords();
      if (!mounted) return;
      if (!await _checkSeedBeforePublishing()) return;
      final imageUploadIds = await _uploadSelectedPhotos();
      if (imageUploadIds == null || !mounted) return;
      if (!await _checkSeedBeforePublishing()) return;
      final result = await ref
          .read(travelReviewMutationControllerProvider.notifier)
          .create(
            projectCode: projectCode,
            draft: TravelReviewDraft(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              stops: _selectedPlaces
                  .map(
                    (place) => TravelReviewStopDraft(
                      placeId: place.id,
                      verifiedVisitId: verifiedVisitProofId(visits, place.id),
                    ),
                  )
                  .toList(growable: false),
              events: _selectedEvents
                  .map(
                    (event) => TravelReviewEventDraft(
                      liveEventId: event.id,
                      verifiedAttendanceId: verifiedAttendanceProofId(
                        attendanceRecords,
                        event.id,
                      ),
                    ),
                  )
                  .toList(growable: false),
              fanSubjectIds: _selectedSubjects
                  .map((subject) => subject.id)
                  .toList(growable: false),
              tripStartedOn: _tripStartedOn,
              tripEndedOn: _tripEndedOn,
              imageUploadIds: imageUploadIds,
              routeNote: _routeNoteController.text.trim(),
            ),
          );
      if (!await _checkSeedBeforePublishing()) return;
      if (!mounted) return;
      switch (result) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n(
                  ko: '여행 후기가 등록되었습니다.',
                  en: 'Your travel review has been posted.',
                  ja: '旅の記録を投稿しました。',
                ),
              ),
            ),
          );
          context.pop();
        case Err():
          _showSubmitFailure();
      }
    } catch (_) {
      if (mounted) _showSubmitFailure();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSubmitFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '저장하지 못했어요. 입력한 내용은 유지됩니다. 다시 시도해주세요.',
            en: 'Could not save. Your input is still here. Please try again.',
            ja: '保存できませんでした。入力内容は残っています。もう一度お試しください。',
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionNotice() {
    return Padding(
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_seedRejected)
            Text(
              context.l10n(
                ko: '여행 기록의 계정과 프로젝트를 확인할 수 없어요. 이전 화면으로 돌아가 같은 계정과 프로젝트에서 다시 선택해주세요.',
                en: 'The account or project changed. Go back and select this trip again with its original account and project.',
                ja: 'アカウントまたはプロジェクトが旅の記録と一致しません。前の画面に戻り、同じアカウントとプロジェクトで選び直してください。',
              ),
            )
          else if (!_seedReady)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text(
              context.l10n(
                ko: '선택한 항목만 가져왔어요. 비공개 제목과 메모는 포함되지 않습니다. 공개할 제목과 내용을 직접 작성해주세요.',
                en: 'Only your selections were copied. Your private title and notes stay private. Write a title and content for this public review.',
                ja: '選んだ項目だけをコピーしました。非公開のタイトルとメモは含まれません。公開するタイトルと本文を入力してください。',
              ),
            ),
            if (_selectedPhotoPaths.isNotEmpty) ...[
              const SizedBox(height: GBTSpacing.sm),
              Text(
                context.l10n(
                  ko: '선택한 사진 ${_selectedPhotoPaths.length}장 · 등록할 때 업로드됩니다.',
                  en: '${_selectedPhotoPaths.length} selected photos · Uploaded when you post.',
                  ja: '選択した写真${_selectedPhotoPaths.length}枚・投稿時にアップロードします。',
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Wrap(
                spacing: GBTSpacing.sm,
                runSpacing: GBTSpacing.sm,
                children: [
                  for (final (index, path) in _selectedPhotoPaths.indexed)
                    SizedBox(
                      width: 104,
                      child: Column(
                        children: [
                          Image.file(
                            File(path),
                            width: 104,
                            height: 80,
                            fit: BoxFit.cover,
                            cacheWidth: 208,
                            excludeFromSemantics: true,
                            errorBuilder: (_, error, stackTrace) =>
                                const SizedBox(
                                  height: 80,
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                          ),
                          IconButton(
                            key: ValueKey('travel-review-remove-photo-$index'),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: context.l10n(
                              ko: '사진 ${index + 1} 제외',
                              en: 'Remove photo ${index + 1}',
                              ja: '写真${index + 1}を除外',
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _selectedPhotoPaths.remove(path);
                                  }),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectionSeed != null) {
      ref.listen<bool>(isAuthenticatedProvider, (previous, authenticated) {
        if (!authenticated && mounted) {
          setState(() => _seedRejected = true);
        }
      });
      ref.listen<String?>(selectedProjectKeyProvider, (previous, project) {
        if (project?.trim() != widget.selectionSeed!.projectCode.trim() &&
            mounted) {
          setState(() => _seedRejected = true);
        }
      });
    }
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visits =
        ref.watch(userVisitsControllerProvider).valueOrNull ??
        const <VisitEvent>[];
    final attendanceRecords = _seedRejected || _selectedEvents.isEmpty
        ? const <LiveAttendanceHistoryRecord>[]
        : ref.watch(liveAttendanceHistoryControllerProvider).items;
    final verifiedEventIds = attendanceRecords
        .where(
          (record) =>
              record.isVerified &&
              record.attendanceId?.trim().isNotEmpty == true,
        )
        .map((record) => record.eventId)
        .toSet();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '후기 작성', en: 'Write Review', ja: 'レビュー作成'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: GBTSpacing.xs),
            child: FilledButton(
              key: const ValueKey('travel-review-submit'),
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 48),
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                ),
              ),
              child: Text(context.l10n(ko: '등록', en: 'Post', ja: '投稿する')),
            ),
          ),
        ],
      ),
      body: _seedRejected
          ? SingleChildScrollView(child: _buildSelectionNotice())
          : Stack(
              children: [
                CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: GBTPageHeader(
                        title: context.l10n(
                          ko: '오늘의 순례를 기록하세요',
                          en: 'Record today’s pilgrimage',
                          ja: '今日の聖地巡礼を記録しましょう',
                        ),
                        description: context.l10n(
                          ko: '장소를 1곳 이상 연결해주세요. 공연도 함께 기록할 수 있어요. 게시하면 즉시 공개됩니다.',
                          en: 'Connect at least one place. You can also include live events. Your review is published immediately.',
                          ja: '場所を1件以上つなげてください。ライブも一緒に記録できます。投稿するとすぐに公開されます。',
                        ),
                      ),
                    ),
                    if (widget.selectionSeed != null)
                      SliverToBoxAdapter(child: _buildSelectionNotice()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        GBTSpacing.md,
                        GBTSpacing.lg,
                        GBTSpacing.md,
                        0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          PostComposeDocumentEditor(
                            titleController: _titleController,
                            contentController: _contentController,
                            enabled: !_isSubmitting,
                            titleHintText: context.l10n(
                              ko: '이번 여행은 어떠셨나요?',
                              en: 'How was this trip?',
                              ja: '今回の旅はいかがでしたか？',
                            ),
                            contentHintText: context.l10n(
                              ko: '자세한 후기를 남겨주세요.',
                              en: 'Share the details of your trip.',
                              ja: '詳しいレビューを書いてください。',
                            ),
                            maxTitleLines: 2,
                            minContentLines: 5,
                            maxTitleLength: 255,
                            maxContentLength: 20000,
                          ),
                          const SizedBox(height: GBTSpacing.xl2),
                          TravelReviewComposeMetadata(
                            routeNoteController: _routeNoteController,
                            tripStartedOn: _tripStartedOn,
                            tripEndedOn: _tripEndedOn,
                            selectedEvents: _selectedEvents,
                            verifiedEventIds: verifiedEventIds,
                            selectedSubjects: _selectedSubjects,
                            onPickStartDate: () => _pickDate(isStart: true),
                            onPickEndDate: () => _pickDate(isStart: false),
                            onPickEvents: _showEventPicker,
                            onPickSubjects: _showFanSubjectPicker,
                            onRemoveEvent: (eventId) => setState(
                              () => _selectedEvents.removeWhere(
                                (event) => event.id == eventId,
                              ),
                            ),
                            onRemoveSubject: (subjectId) => setState(
                              () => _selectedSubjects.removeWhere(
                                (subject) => subject.id == subjectId,
                              ),
                            ),
                          ),
                          const SizedBox(height: GBTSpacing.xl2),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n(
                                  ko: '방문 순서',
                                  en: 'Visit Order',
                                  ja: '訪問順',
                                ),
                                style: GBTTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: GBTSpacing.xs),
                              Text(
                                _selectedPlaces.isEmpty
                                    ? context.l10n(
                                        ko: '장소를 추가하면 이동 순서를 지도에 그려드려요.',
                                        en: 'Add places to draw your route on the map.',
                                        ja: '場所を追加すると移動順を地図に描画します。',
                                      )
                                    : context.l10n(
                                        ko: '총 ${_selectedPlaces.length}곳 · 길게 눌러 순서를 바꿀 수 있어요.',
                                        en: '${_selectedPlaces.length} places total · Long-press to reorder.',
                                        ja: '合計${_selectedPlaces.length}件・長押しで順番を変更できます。',
                                      ),
                                style: GBTTypography.bodyMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: GBTSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: _showPlacePicker,
                                icon: const Icon(Icons.add),
                                label: Text(
                                  context.l10n(
                                    ko: '장소 추가',
                                    en: 'Add Place',
                                    ja: '場所を追加',
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      GBTSpacing.radiusSm,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: GBTSpacing.md),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GBTSpacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildMapSection(colorScheme, isDark),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.only(top: GBTSpacing.sm),
                    ),
                    SliverReorderableList(
                      itemCount: _selectedPlaces.length,
                      // EN: Flutter 3.41 stable requires the legacy callback.
                      // KO: Flutter 3.41 stable은 기존 콜백을 필수로 요구합니다.
                      // ignore: deprecated_member_use
                      onReorder: _reorderPlaces,
                      itemBuilder: (context, index) {
                        final place = _selectedPlaces[index];
                        return DecoratedBox(
                          key: ValueKey(place.id),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GBTSpacing.md,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              minVerticalPadding: GBTSpacing.sm,
                              leading: SizedBox(
                                width: 32,
                                child: Text(
                                  '${index + 1}'.padLeft(2, '0'),
                                  style: GBTTypography.labelLarge.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                place.name,
                                style: GBTTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.address,
                                    style: GBTTypography.bodySmall,
                                  ),
                                  if (verifiedVisitProofId(visits, place.id) !=
                                      null)
                                    Text(
                                      context.l10n(
                                        ko: '인증된 방문 기록 연결',
                                        en: 'Linked to verified visit',
                                        ja: '認証済み訪問記録にリンク',
                                      ),
                                      style: GBTTypography.labelSmall.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => _removePlace(index),
                                    tooltip: context.l10n(
                                      ko: '${place.name} 제거',
                                      en: 'Remove ${place.name}',
                                      ja: '${place.name}を削除',
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildMapSection(ColorScheme colorScheme, bool isDark) {
    if (_selectedPlaces.isEmpty) {
      return SizedBox(
        height: 168,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 36,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                context.l10n(
                  ko: '아직 표시할 여정이 없어요',
                  en: 'No route to show yet',
                  ja: 'まだ表示する経路がありません',
                ),
                textAlign: TextAlign.center,
                style: GBTTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAppleMap) {
      final amaps.Polyline polyline = amaps.Polyline(
        polylineId: amaps.PolylineId('route'),
        points: _selectedPlaces
            .map((p) => amaps.LatLng(p.latitude, p.longitude))
            .toList(),
        color: colorScheme.primary,
        width: 4,
        jointType: amaps.JointType.round,
      );

      final Set<amaps.Annotation> markers = {};
      for (int i = 0; i < _selectedPlaces.length; i++) {
        final place = _selectedPlaces[i];
        markers.add(
          amaps.Annotation(
            annotationId: amaps.AnnotationId(place.id),
            position: amaps.LatLng(place.latitude, place.longitude),
            infoWindow: amaps.InfoWindow(title: '${i + 1}. ${place.name}'),
          ),
        );
      }

      return SizedBox(
        height: 184,
        child: Stack(
          fit: StackFit.expand,
          children: [
            amaps.AppleMap(
              initialCameraPosition: amaps.CameraPosition(
                target: amaps.LatLng(
                  _selectedPlaces.first.latitude,
                  _selectedPlaces.first.longitude,
                ),
                zoom: 12,
              ),
              polylines: {polyline},
              annotations: markers,
            ),
            IgnorePointer(
              child: ColoredBox(
                color: gbtAppleMapOverlayColorForDarkMode(isDark),
              ),
            ),
          ],
        ),
      );
    } else {
      final gmaps.Polyline polyline = gmaps.Polyline(
        polylineId: const gmaps.PolylineId('route'),
        points: _selectedPlaces
            .map((p) => gmaps.LatLng(p.latitude, p.longitude))
            .toList(),
        color: colorScheme.primary,
        width: 4,
        jointType: gmaps.JointType.round,
      );

      final Set<gmaps.Marker> markers = {};
      for (int i = 0; i < _selectedPlaces.length; i++) {
        final place = _selectedPlaces[i];
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(place.id),
            position: gmaps.LatLng(place.latitude, place.longitude),
            infoWindow: gmaps.InfoWindow(title: '${i + 1}. ${place.name}'),
          ),
        );
      }

      return SizedBox(
        height: 184,
        child: gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: gmaps.LatLng(
              _selectedPlaces.first.latitude,
              _selectedPlaces.first.longitude,
            ),
            zoom: 12,
          ),
          style: gbtGoogleMapStyleForDarkMode(isDark),
          polylines: {polyline},
          markers: markers,
        ),
      );
    }
  }

  Future<List<LiveAttendanceHistoryRecord>>
  _loadAttendanceProofRecords() async {
    if (_selectedEvents.isEmpty) return const [];

    final provider = liveAttendanceHistoryControllerProvider;
    final notifier = ref.read(provider.notifier);
    var history = ref.read(provider);
    if (history.isInitialLoading) {
      await notifier.load(forceRefresh: true);
      if (!mounted) return const [];
      history = ref.read(provider);
    }

    final selectedEventIds = _selectedEvents
        .map((event) => event.id.trim())
        .where((eventId) => eventId.isNotEmpty)
        .toSet();
    while (history.hasNext &&
        !history.items
            .map((record) => record.eventId.trim())
            .toSet()
            .containsAll(selectedEventIds)) {
      final previousPage = history.nextPage;
      await notifier.loadMore();
      if (!mounted) return const [];
      history = ref.read(provider);
      if (history.nextPage <= previousPage) break;
    }
    return history.items;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_tripStartedOn ?? DateTime.now())
        : (_tripEndedOn ?? _tripStartedOn ?? DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (isStart) {
        _tripStartedOn = selected;
        if (_tripEndedOn != null && _tripEndedOn!.isBefore(selected)) {
          _tripEndedOn = selected;
        }
      } else {
        _tripEndedOn = selected;
      }
    });
  }

  Future<void> _showEventPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return TravelEventPickerSheet(
            selectedIds: _selectedEvents.map((event) => event.id).toSet(),
            onToggle: (event) {
              setState(() {
                final index = _selectedEvents.indexWhere(
                  (selected) => selected.id == event.id,
                );
                if (index >= 0) {
                  _selectedEvents.removeAt(index);
                } else if (_selectedEvents.length < 10) {
                  _selectedEvents.add(event);
                }
              });
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  Future<void> _showFanSubjectPicker() async {
    final projectCode = ref.read(selectedProjectKeyProvider)?.trim();
    if (projectCode == null || projectCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '프로젝트를 먼저 선택해주세요.',
              en: 'Please select a project first.',
              ja: 'プロジェクトを先に選択してください。',
            ),
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return TravelFanSubjectPickerSheet(
            projectCode: projectCode,
            selectedIds: _selectedSubjects.map((subject) => subject.id).toSet(),
            onToggle: (subject) {
              setState(() {
                final index = _selectedSubjects.indexWhere(
                  (selected) => selected.id == subject.id,
                );
                if (index >= 0) {
                  _selectedSubjects.removeAt(index);
                } else if (_selectedSubjects.length < 20) {
                  _selectedSubjects.add(subject);
                }
              });
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  // EN: Open the real place picker sheet backed by placesListControllerProvider.
  // KO: placesListControllerProvider를 사용한 실제 장소 선택 시트를 엽니다.
  Future<void> _showPlacePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusLg),
        ),
      ),
      builder: (_) => TravelReviewPlacePickerSheet(
        selectedIds: _selectedPlaces.map((p) => p.id).toSet(),
        onAdd: _addPlace,
      ),
    );
  }
}

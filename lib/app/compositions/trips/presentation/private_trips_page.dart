import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/widgets/layout/gbt_page_header.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import '../application/private_trips_controller.dart';
import '../application/trip_candidates.dart';
import '../domain/private_trip.dart';
import 'private_trip_editor.dart';

class PrivateTripsPage extends ConsumerStatefulWidget {
  const PrivateTripsPage({super.key});
  @override
  ConsumerState<PrivateTripsPage> createState() => _PrivateTripsPageState();
}

class _PrivateTripsPageState extends ConsumerState<PrivateTripsPage> {
  final _selected = <String>{};
  PrivateTripsController? _selectionOwner;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '저장하거나 불러오지 못했어요. 다시 시도해주세요.',
                en: 'Could not save or load. Please try again.',
                ja: '保存・読み込みに失敗しました。再試行してください。',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(PrivateTrip trip) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => PrivateTripEditor(trip: trip)),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privateTripsControllerProvider);
    final controller = ref.read(privateTripsControllerProvider.notifier);
    if (!identical(_selectionOwner, controller)) {
      _selected.clear();
      _selectionOwner = controller;
    }
    final project = ref.watch(selectedProjectKeyProvider);
    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '旅 · 비공개 앨범',
          en: 'Trips · Private albums',
          ja: '旅・非公開アルバム',
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(privateTripsControllerProvider),
            child: Text(
              context.l10n(
                ko: '계정을 확인하고 다시 불러오기',
                en: 'Check account and reload',
                ja: 'アカウントを確認して再読み込み',
              ),
            ),
          ),
        ),
        data: (trips) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  GBTPageHeader(
                    eyebrow: 'PRIVATE · LOCAL',
                    title: context.l10n(
                      ko: '내 여행을 모아두기',
                      en: 'Keep your journeys',
                      ja: '旅の記録をまとめる',
                    ),
                    description: context.l10n(
                      ko: '이 기기의 계정별 앨범입니다. 앱 삭제 시 사라질 수 있어요. 공개할 항목은 나중에 직접 선택하세요.',
                      en: 'Albums stay on this device for your account and may be lost if the app is removed. Choose what to publish later.',
                      ja: 'この端末のアカウント別アルバムです。アプリを削除すると失われる場合があります。公開する項目は後で選べます。',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(GBTSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (project == null)
                          Text(
                            context.l10n(
                              ko: '여행을 만들려면 먼저 프로젝트를 선택하세요.',
                              en: 'Choose a project before creating a trip.',
                              ja: '旅を作る前にプロジェクトを選んでください。',
                            ),
                          ),
                        FilledButton.icon(
                          key: const ValueKey('private-trip-new'),
                          onPressed: _busy || project == null
                              ? null
                              : () => _edit(
                                  PrivateTrip(
                                    id: const Uuid().v4(),
                                    projectKey: project,
                                    title: context.l10n(
                                      ko: '새 여행',
                                      en: 'New trip',
                                      ja: '新しい旅',
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.add),
                          label: Text(
                            context.l10n(
                              ko: '새 비공개 여행',
                              en: 'New private trip',
                              ja: '非公開の旅を作成',
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey('private-trip-import'),
                          onPressed: _busy || project == null
                              ? null
                              : () => _run(() async {
                                  await controller.assertSession();
                                  ref.invalidate(
                                    tripCandidatesProvider(project),
                                  );
                                  final candidates = await ref.read(
                                    tripCandidatesProvider(project).future,
                                  );
                                  await controller.assertSession();
                                  final existing = ref
                                      .read(privateTripsControllerProvider)
                                      .requireValue;
                                  final sources = existing
                                      .expand((t) => t.entries)
                                      .map((e) => e.id)
                                      .toSet();
                                  await controller.replace([
                                    ...existing,
                                    ...candidates.where(
                                      (t) => t.entries.any(
                                        (e) => !sources.contains(e.id),
                                      ),
                                    ),
                                  ]);
                                }),
                          icon: const Icon(Icons.history),
                          label: Text(
                            context.l10n(
                              ko: '방문·참가 기록에서 후보 가져오기',
                              en: 'Import visit and attendance candidates',
                              ja: '訪問・参加記録から候補を作成',
                            ),
                          ),
                        ),
                        Text(
                          context.l10n(
                            ko: '기록별 후보를 선택해 합칠 수 있어요. 여행 날짜는 직접 확인합니다.',
                            en: 'Select candidates to merge. Confirm travel dates yourself.',
                            ja: '記録ごとの候補を選んでまとめられます。旅行日は自分で確認します。',
                          ),
                        ),
                        if (_busy) const LinearProgressIndicator(),
                        if (_selected.length > 1)
                          OutlinedButton(
                            key: const ValueKey('private-trip-merge'),
                            onPressed: _busy
                                ? null
                                : () => _run(() async {
                                    final chosen = trips
                                        .where((t) => _selected.contains(t.id))
                                        .toList();
                                    if (chosen
                                            .map((t) => t.projectKey)
                                            .toSet()
                                            .length !=
                                        1) {
                                      throw ArgumentError('Project mismatch');
                                    }
                                    final merged = chosen
                                        .skip(1)
                                        .fold(
                                          chosen.first,
                                          (a, b) => a.merge(b),
                                        );
                                    await controller.replace([
                                      for (final t in trips)
                                        if (!_selected.contains(t.id)) t,
                                      merged,
                                    ]);
                                    if (mounted) setState(_selected.clear);
                                  }),
                            child: Text(
                              context.l10n(
                                ko: '선택한 여행 합치기 · 날짜 다시 확인',
                                en: 'Merge selected · reconfirm dates',
                                ja: '選択した旅を統合・日付を再確認',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(GBTSpacing.md),
                      child: Text(
                        context.l10n(
                          ko: '아직 여행이 없어요. 직접 만들거나 기록에서 후보를 가져오세요.',
                          en: 'No trips yet. Create one or import candidates from your records.',
                          ja: 'まだ旅がありません。作成するか、記録から候補を読み込んでください。',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SliverList.builder(
              itemCount: trips.length,
              itemBuilder: (_, index) {
                final trip = trips[index];
                return TripCandidateCard(
                  trip: trip,
                  selected: _selected.contains(trip.id),
                  onSelected: (value) => setState(() {
                    value ? _selected.add(trip.id) : _selected.remove(trip.id);
                  }),
                  onOpen: () => _edit(trip),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: GBTSpacing.xl)),
          ],
        ),
      ),
    );
  }
}

class TripCandidateCard extends StatelessWidget {
  const TripCandidateCard({
    super.key,
    required this.trip,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  });
  final PrivateTrip trip;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
    child: Column(
      children: [
        const Divider(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              semanticLabel: context.l10n(
                ko: '${trip.title} 합치기 선택',
                en: 'Select ${trip.title} for merging',
                ja: '${trip.title}を統合対象に選択',
              ),
              onChanged: (value) => onSelected(value ?? false),
            ),
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: onOpen,
                title: Text(trip.title),
                subtitle: Text(
                  '${trip.projectKey} · ${trip.entries.length}\n${trip.datesConfirmed ? '${trip.startedOn!.toIso8601String().split('T').first} – ${trip.endedOn!.toIso8601String().split('T').first}' : context.l10n(ko: '여행 날짜 확인 필요', en: 'Confirm travel dates', ja: '旅行日の確認が必要')}',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

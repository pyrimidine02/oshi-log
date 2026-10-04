/// EN: Clean-sheet Field Desk home for travel, events, and dispatches.
/// KO: 여행, 일정, 디스패치를 위한 새 Field Desk 홈.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../platform/error/failure.dart';
import '../../../../../design_system/localization/locale_text.dart';
import '../../../../../platform/providers/core_providers.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import '../../../../../platform/router/app_router.dart';
import '../../../../../design_system/theme/theme.dart';
import '../../../../../design_system/widgets/feedback/gbt_empty_state.dart';
import '../../../../../design_system/widgets/feedback/gbt_loading.dart'
    hide GBTEmptyState;
import '../../../../../design_system/widgets/navigation/gbt_profile_action.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/field_project_lens.dart';
import 'package:oshi_log/features/identity/account/application/settings_controller.dart';
import '../../../../../features/shared/home/application/home_controller.dart';
import '../../../../../features/shared/home/domain/entities/home_summary.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/fan_subjects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/fan_subject_preference_sheet.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/event_time_policy.dart';
import './field_home_view_data.dart';
import './widgets/home_entry_sections.dart';
import './widgets/field_home_components.dart';

/// EN: Home answers one question: where should the fan go next?
/// KO: 팬이 다음에 어디로 가야 하는지 한 가지 질문에 답하는 홈입니다.
class FieldHomePage extends ConsumerWidget {
  const FieldHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(projectSelectionControllerProvider);
    final authenticated = ref.watch(isAuthenticatedProvider);
    final state = authenticated ? ref.watch(homeControllerProvider) : null;
    final projects = ref.watch(projectsControllerProvider);
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final profile = authenticated
        ? ref.watch(userProfileControllerProvider).valueOrNull
        : null;
    final subjects = authenticated
        ? ref.watch(myFanSubjectsControllerProvider)
        : null;
    final projectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            if (authenticated) {
              await ref
                  .read(homeControllerProvider.notifier)
                  .load(forceRefresh: true);
            } else {
              await ref
                  .read(projectsControllerProvider.notifier)
                  .load(forceRefresh: true);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _FieldHomeHeader(avatarUrl: profile?.avatarUrl),
              ),
              if (!authenticated)
                const SliverToBoxAdapter(
                  child: _ResponsivePage(child: HomeGuestSections()),
                )
              else ...[
                if (subjects?.hasValue == true &&
                    subjects!.value!.isEmpty &&
                    projectId != null)
                  SliverToBoxAdapter(
                    child: _ResponsivePage(
                      child: HomeEntryPrompt(
                        title: context.l10n(
                          ko: '좋아하는 대상을 골라보세요',
                          en: 'Choose your favorites',
                          ja: '推しを選んでみましょう',
                        ),
                        message: context.l10n(
                          ko: '나중에 골라도 괜찮아요. 지금은 선택한 프로젝트를 둘러보세요.',
                          en: 'You can choose later. Explore the selected project now.',
                          ja: 'あとで選んでも大丈夫。まずは選択中のプロジェクトを見てみましょう。',
                        ),
                        actionLabel: context.l10n(
                          ko: '관심 대상 선택',
                          en: 'Choose interests',
                          ja: '推しを選ぶ',
                        ),
                        onAction: () => showFanSubjectPreferenceSheet(
                          context: context,
                          projectId: projectId,
                        ),
                        dismissible: true,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _ResponsivePage(
                    child: Text(
                      context.l10n(
                        ko: '선택한 프로젝트의 공연·장소·뉴스',
                        en: 'Shows, places and news in the selected project',
                        ja: '選択中プロジェクトの公演・場所・ニュース',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                if (projectKey == null || projectKey.isEmpty)
                  _projectGate(context, ref, projects)
                else
                  ...state!.when(
                    loading: () => const [_HomeLoadingSliver()],
                    error: (error, _) => [_HomeErrorSliver(error: error)],
                    data: (summary) => _buildSummary(context, ref, summary),
                  ),
              ],
              const SliverToBoxAdapter(
                child: _ResponsivePage(
                  top: GBTSpacing.lg,
                  child: HomeMusicShortcut(),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: GBTSpacing.bottomNavClearanceOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectGate(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Project>> projects,
  ) {
    return projects.when(
      loading: () => const _HomeLoadingSliver(),
      error: (error, _) => _HomeErrorSliver(error: error),
      data: (items) {
        if (items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: GBTEmptyState(
              icon: Icons.layers_clear_outlined,
              title: context.l10n(
                ko: '여행할 프로젝트가 아직 없어요',
                en: 'No projects are ready yet',
                ja: '旅するプロジェクトがまだありません',
              ),
            ),
          );
        }
        return SliverToBoxAdapter(
          child: _ResponsivePage(
            child: HomeEntryPrompt(
              title: context.l10n(
                ko: '프로젝트를 선택해주세요',
                en: 'Choose a project',
                ja: 'プロジェクトを選んでください',
              ),
              message: context.l10n(
                ko: '위의 프로젝트 이름을 눌러 둘러볼 작품을 선택할 수 있어요.',
                en: 'Use the project selector above to choose what to explore.',
                ja: '上のプロジェクト名から、見たい作品を選べます。',
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSummary(
    BuildContext context,
    WidgetRef ref,
    HomeSummary summary,
  ) {
    final now = DateTime.now();
    final contentState = resolveFieldHomeContentState(summary, now: now);
    if (contentState != FieldHomeContentState.content) {
      return [_homeEmptySliver(context, contentState)];
    }

    final composition = composeFieldHome(summary, now: now);
    final news = summary.latestNews;
    final heroEvent = composition.leadEvent;
    final heroPlace = composition.leadPlace;

    return [
      if (heroEvent != null || heroPlace != null)
        SliverToBoxAdapter(
          child: _ResponsivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldSectionHeader(
                  eyebrow: '',
                  title: context.l10n(
                    ko: '가까운 공연과 장소',
                    en: 'Shows and places to explore',
                    ja: '近日開催のライブと場所',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                if (heroEvent != null)
                  JourneyBriefCard(
                    markerLabel: _eventMarker(heroEvent, now: now),
                    eyebrow: context.l10n(
                      ko: '선택한 프로젝트의 공연',
                      en: 'Show in this project',
                      ja: 'このプロジェクトの公演',
                    ),
                    title: heroEvent.title,
                    meta: _eventDateTime(context, heroEvent),
                    primaryActionLabel: context.l10n(
                      ko: '상세 보기',
                      en: 'View details',
                      ja: '詳細を見る',
                    ),
                    onPrimaryAction: () => _openEvent(context, ref, heroEvent),
                    secondaryActionLabel: context.l10n(
                      ko: '전체 일정',
                      en: 'Full calendar',
                      ja: 'すべての予定',
                    ),
                    onSecondaryAction: () =>
                        context.pushNamed(AppRoutes.calendar),
                    imageUrl: heroEvent.posterUrl,
                    imageFit: BoxFit.contain,
                  )
                else if (heroPlace != null)
                  JourneyBriefCard(
                    markerLabel: context.l10n(ko: '추천', en: 'SPOT', ja: '推し'),
                    eyebrow: context.l10n(
                      ko: '오늘의 첫 목적지',
                      en: 'First stop for today',
                      ja: '今日の最初の目的地',
                    ),
                    title: heroPlace.name,
                    meta: _placeMeta(context, heroPlace),
                    primaryActionLabel: context.l10n(
                      ko: '장소 보기',
                      en: 'View place',
                      ja: '場所を見る',
                    ),
                    onPrimaryAction: () =>
                        context.goToPlaceDetail(heroPlace.id),
                    secondaryActionLabel: context.l10n(
                      ko: '지도 열기',
                      en: 'Open map',
                      ja: '地図を開く',
                    ),
                    onSecondaryAction: () => context.go('/explore?tab=0'),
                    imageUrl: heroPlace.imageUrl,
                  ),
              ],
            ),
          ),
        ),
      if (composition.agendaEvents.isNotEmpty)
        SliverToBoxAdapter(
          child: _ResponsivePage(
            top: GBTSpacing.xl,
            child: _EventsSection(events: composition.agendaEvents),
          ),
        ),
      if (composition.pilgrimagePlaces.isNotEmpty)
        SliverToBoxAdapter(
          child: _ResponsivePage(
            top: GBTSpacing.xl,
            child: _PlacesSection(places: composition.pilgrimagePlaces),
          ),
        ),
      if (news.isNotEmpty)
        SliverToBoxAdapter(
          child: _ResponsivePage(
            top: heroEvent == null && heroPlace == null
                ? GBTSpacing.sm
                : GBTSpacing.xl,
            child: _DispatchSection(news: news),
          ),
        ),
    ];
  }

  Widget _homeEmptySliver(BuildContext context, FieldHomeContentState state) {
    final isHardEmpty = state == FieldHomeContentState.hardEmpty;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: GBTEmptyState(
        icon: isHardEmpty
            ? Icons.route_outlined
            : Icons.filter_alt_off_outlined,
        title: isHardEmpty
            ? context.l10n(
                ko: '아직 등록된 여행 정보가 없어요',
                en: 'No travel information yet',
                ja: 'まだ旅行情報が登録されていません',
              )
            : context.l10n(
                ko: '지금 보여드릴 추천이 없어요',
                en: 'No recommendations to show right now',
                ja: '現在表示できるおすすめはありません',
              ),
        subtitle: isHardEmpty
            ? context.l10n(
                ko: '이 프로젝트에 장소, 이벤트, 소식이 등록되면 여기에 모아드릴게요.',
                en: 'Places, events, and updates will appear here once added.',
                ja: '場所・イベント・ニュースが登録されるとここに表示されます。',
              )
            : context.l10n(
                ko: '탐방에서 장소와 일정을 둘러보며 다음 여행을 준비해보세요.',
                en: 'Explore places and schedules to plan your next trip.',
                ja: '探索で場所や予定を探して、次の旅を準備しましょう。',
              ),
        actionLabel: isHardEmpty
            ? null
            : context.l10n(
                ko: '탐방에서 전체 보기',
                en: 'View all in Explore',
                ja: '探索ですべて見る',
              ),
        onAction: isHardEmpty ? null : () => context.go('/explore'),
      ),
    );
  }

  void _openEvent(BuildContext context, WidgetRef ref, HomeEventItem event) {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logLiveEventView(event.id, eventName: event.title),
    );
    context.goToEventDetail(event.id);
  }
}

class _FieldHomeHeader extends StatelessWidget {
  const _FieldHomeHeader({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return _ResponsivePage(
      top: GBTSpacing.sm,
      bottom: GBTSpacing.md,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Oshi@log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => context.goToSearch(),
                tooltip: context.l10n(ko: '검색', en: 'Search', ja: '検索'),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                onPressed: () => context.push('/notifications'),
                tooltip: context.l10n(ko: '알림', en: 'Notifications', ja: '通知'),
                icon: const Icon(Icons.notifications_outlined),
              ),
              GBTProfileAction(avatarUrl: avatarUrl),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          const FieldProjectLens(),
        ],
      ),
    );
  }
}

class _PlacesSection extends StatelessWidget {
  const _PlacesSection({required this.places});

  final List<HomePlaceItem> places;

  @override
  Widget build(BuildContext context) {
    final featured = places.first;
    return Column(
      children: [
        FieldSectionHeader(
          eyebrow: '',
          title: context.l10n(
            ko: '이 프로젝트의 성지',
            en: 'Places in this project',
            ja: 'このプロジェクトの聖地',
          ),
          actionLabel: context.l10n(ko: '지도 열기', en: 'Open map', ja: '地図を開く'),
          onAction: () => context.go('/explore?tab=0'),
        ),
        const SizedBox(height: GBTSpacing.md),
        FieldPlaceFeature(
          title: featured.name,
          meta: _placeMeta(context, featured),
          imageUrl: featured.imageUrl,
          onTap: () => context.goToPlaceDetail(featured.id),
        ),
        for (final place in places.skip(1).take(2))
          FieldPlaceRow(
            title: place.name,
            meta: _placeMeta(context, place),
            imageUrl: place.imageUrl,
            onTap: () => context.goToPlaceDetail(place.id),
          ),
      ],
    );
  }
}

class _EventsSection extends ConsumerWidget {
  const _EventsSection({required this.events});

  final List<HomeEventItem> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        FieldSectionHeader(
          eyebrow: '',
          title: context.l10n(ko: '다가오는 공연', en: 'Upcoming shows', ja: '今後の公演'),
          actionLabel: context.l10n(ko: '캘린더', en: 'Calendar', ja: 'カレンダー'),
          onAction: () => context.pushNamed(AppRoutes.calendar),
        ),
        const SizedBox(height: GBTSpacing.sm),
        for (final event in events.take(4))
          FieldAgendaTile(
            dateLabel: _eventDate(context, event),
            title: event.title,
            typeLabel: context.l10n(
              ko: '라이브 이벤트',
              en: 'Live event',
              ja: 'ライブイベント',
            ),
            onTap: () {
              unawaited(
                ref
                    .read(analyticsServiceProvider)
                    .logLiveEventView(event.id, eventName: event.title),
              );
              context.goToEventDetail(event.id);
            },
          ),
      ],
    );
  }
}

String _eventDate(BuildContext context, HomeEventItem event) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.MMMd(locale).format(EventTimePolicy.inJst(event.startsAt));
}

String _eventDateTime(BuildContext context, HomeEventItem event) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final jst = DateFormat.MMMEd(
    locale,
  ).add_Hm().format(EventTimePolicy.inJst(event.startsAt));
  final local = event.startsAt.toLocal();
  if (local.timeZoneOffset == EventTimePolicy.jstOffset) return '$jst JST';
  final localLabel = DateFormat.MMMEd(locale).add_Hm().format(local);
  final device = context.l10n(ko: '기기 시간', en: 'device time', ja: '端末時間');
  return '$jst JST · $localLabel ($device)';
}

String _eventMarker(HomeEventItem event, {required DateTime now}) {
  final eventDay = EventTimePolicy.dateInJst(event.startsAt);
  final today = EventTimePolicy.dateInJst(now);
  final days = eventDay.difference(today).inDays;
  return days == 0 ? 'D-DAY' : 'D-$days';
}

String _placeMeta(BuildContext context, HomePlaceItem place) {
  final location = place.location?.trim();
  final visits = context.l10n(
    ko: '방문 ${place.visitCount}회',
    en: '${place.visitCount} visits',
    ja: '訪問 ${place.visitCount}回',
  );
  return location == null || location.isEmpty ? visits : '$location · $visits';
}

class _DispatchSection extends StatelessWidget {
  const _DispatchSection({required this.news});

  final List<HomeNewsItem> news;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: [
        FieldSectionHeader(
          eyebrow: '',
          title: context.l10n(
            ko: '프로젝트 소식',
            en: 'Project updates',
            ja: 'プロジェクトニュース',
          ),
          actionLabel: context.l10n(ko: '모두 보기', en: 'See all', ja: 'すべて見る'),
          onAction: () => context.go('/information'),
        ),
        for (final item in news.take(4))
          FieldDispatchRow(
            title: item.title,
            summary: item.summary,
            imageUrl: item.imageUrl,
            meta: item.publishedAt == null
                ? context.l10n(ko: '업데이트', en: 'Update', ja: '更新')
                : DateFormat.yMMMd(locale).format(item.publishedAt!.toLocal()),
            onTap: () => context.goToNewsDetail(item.id),
          ),
      ],
    );
  }
}

class _ResponsivePage extends StatelessWidget {
  const _ResponsivePage({required this.child, this.top = 0, this.bottom = 0});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final gutter = MediaQuery.sizeOf(context).width <= 340 ? 16.0 : 20.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, bottom),
          child: child,
        ),
      ),
    );
  }
}

class _HomeLoadingSliver extends StatelessWidget {
  const _HomeLoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _ResponsivePage(
        child: Column(
          children: [
            GBTShimmer(
              child: Container(
                height: 208,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
                ),
              ),
            ),
            const SizedBox(height: GBTSpacing.xl),
            for (var index = 0; index < 3; index++) ...[
              GBTShimmer(
                child: Container(
                  height: 72,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeErrorSliver extends ConsumerWidget {
  const _HomeErrorSliver({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = error is Failure
        ? (error as Failure).userMessage
        : context.l10n(
            ko: '홈 정보를 불러오지 못했어요',
            en: 'Could not load the field desk',
            ja: 'ホーム情報を読み込めませんでした',
          );
    return SliverToBoxAdapter(
      child: _ResponsivePage(
        child: GBTErrorState(
          message: message,
          onRetry: () => ref
              .read(homeControllerProvider.notifier)
              .load(forceRefresh: true),
        ),
      ),
    );
  }
}

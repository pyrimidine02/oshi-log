/// EN: Clean-sheet travel specimen archive for pilgrimage collections.
/// KO: 성지순례 컬렉션을 위한 클린시트 여행 표본 아카이브입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/presentation/widgets/field_project_picker_sheet.dart';
import '../../application/zukan_controller.dart';
import '../../domain/entities/zukan_collection.dart';
import 'field_zukan_archive_sections.dart';
import 'field_zukan_archive_view_data.dart';

/// EN: Presents real project-scoped collections as an indexed field archive.
/// KO: 실제 프로젝트 범위 컬렉션을 색인형 필드 아카이브로 표시합니다.
class FieldZukanArchivePage extends ConsumerWidget {
  const FieldZukanArchivePage({super.key, this.embedded = false});

  /// EN: Omits standalone chrome when hosted by the Explore workspace.
  /// KO: 탐방 워크스페이스에 포함될 때 독립 화면 크롬을 생략합니다.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerProjectKey = ref.watch(selectedProjectKeyProvider)?.trim();
    final providerProjectId = ref.watch(selectedProjectIdProvider)?.trim();
    // EN: A direct deep link can open this tab before Home or Map has created
    //     the selection controller. Bootstrap it only while raw context is
    //     absent, then remain scoped to the resolved project.
    // KO: 딥링크로 바로 진입하면 홈이나 지도가 선택 컨트롤러를
    //     만들기 전일 수 있습니다. 원시 컨텍스트가 없을 때만 복원을 시작하고,
    //     해결된 프로젝트 범위를 유지합니다.
    final restoredSelection =
        providerProjectKey?.isNotEmpty != true &&
            providerProjectId?.isNotEmpty != true
        ? ref.watch(projectSelectionControllerProvider)
        : null;
    final projectKey = providerProjectKey?.isNotEmpty == true
        ? providerProjectKey
        : restoredSelection?.projectKey?.trim();
    final projectId = providerProjectId;
    final projectScope = projectKey?.isNotEmpty == true
        ? projectKey
        : (projectId?.isNotEmpty == true ? projectId : null);

    // EN: Do not issue an unscoped archive request while persisted project
    //     selection is still being restored.
    // KO: 저장된 프로젝트 선택을 복원하는 동안 범위 없는 아카이브 요청을
    //     보내지 않습니다.
    if (projectScope == null) {
      final projects = ref.watch(projectsControllerProvider);
      return Scaffold(
        appBar: embedded
            ? null
            : gbtStandardAppBar(
                context,
                title: context.l10n(
                  ko: '여행 표본 아카이브',
                  en: 'Travel specimen archive',
                  ja: '旅の標本アーカイブ',
                ),
              ),
        body: projects.when(
          loading: () => GBTLoading(
            message: context.l10n(
              ko: '표본 색인을 열고 있어요',
              en: 'Opening the specimen index',
              ja: '標本索引を開いています',
            ),
          ),
          error: (_, __) => GBTEmptyState(
            icon: Icons.layers_clear_outlined,
            title: context.l10n(
              ko: '프로젝트를 불러오지 못했어요',
              en: 'Could not load projects',
              ja: 'プロジェクトを読み込めませんでした',
            ),
            subtitle: context.l10n(
              ko: '도감을 열려면 여행 프로젝트가 필요해요.',
              en: 'A travel project is required to open the archive.',
              ja: 'アーカイブを開くには旅のプロジェクトが必要です。',
            ),
            actionLabel: context.l10n(ko: '다시 시도', en: 'Try again', ja: '再試行'),
            onAction: () => ref
                .read(projectsControllerProvider.notifier)
                .load(forceRefresh: true),
          ),
          data: (items) {
            if (items.isEmpty) {
              return GBTEmptyState(
                icon: Icons.layers_clear_outlined,
                title: context.l10n(
                  ko: '선택할 프로젝트가 없어요',
                  en: 'No projects available',
                  ja: '選択できるプロジェクトがありません',
                ),
                subtitle: context.l10n(
                  ko: '프로젝트가 추가된 뒤 표본 아카이브를 다시 열어 주세요.',
                  en: 'Open the specimen archive again after adding a project.',
                  ja: 'プロジェクトを追加してから標本アーカイブを再度開いてください。',
                ),
                actionLabel: context.l10n(
                  ko: '다시 불러오기',
                  en: 'Reload',
                  ja: '再読み込み',
                ),
                onAction: () => ref
                    .read(projectsControllerProvider.notifier)
                    .load(forceRefresh: true),
              );
            }
            return GBTEmptyState(
              icon: Icons.travel_explore_outlined,
              title: context.l10n(
                ko: '도감을 열 프로젝트를 선택해 주세요',
                en: 'Choose a project for the archive',
                ja: 'アーカイブを開くプロジェクトを選択してください',
              ),
              subtitle: context.l10n(
                ko: '선택한 여행을 기준으로 표본과 방문 기록을 정리해요.',
                en: 'Specimens and visits are organized by your chosen journey.',
                ja: '選んだ旅を基準に標本と訪問記録を整理します。',
              ),
              actionLabel: context.l10n(
                ko: '프로젝트 선택',
                en: 'Choose project',
                ja: 'プロジェクト選択',
              ),
              onAction: () async {
                final picked = await showFieldProjectPicker(
                  context: context,
                  projects: items,
                  selectedProject: items.first,
                );
                if (picked == null || !context.mounted) {
                  return;
                }
                final pickedKey = picked.code.trim().isNotEmpty
                    ? picked.code.trim()
                    : picked.id;
                await ref
                    .read(projectSelectionControllerProvider.notifier)
                    .selectProject(pickedKey, projectId: picked.id);
              },
            );
          },
        ),
      );
    }

    final collections = ref.watch(zukanCollectionsProvider(projectScope));

    return Scaffold(
      appBar: embedded
          ? null
          : gbtStandardAppBar(
              context,
              title: context.l10n(
                ko: '여행 표본 아카이브',
                en: 'Travel specimen archive',
                ja: '旅の標本アーカイブ',
              ),
            ),
      body: collections.when(
        loading: () => GBTLoading(
          message: context.l10n(
            ko: '표본 색인을 열고 있어요',
            en: 'Opening the specimen index',
            ja: '標本索引を開いています',
          ),
        ),
        error: (_, __) => GBTEmptyState(
          icon: Icons.inventory_2_outlined,
          title: context.l10n(
            ko: '아카이브를 열지 못했어요',
            en: 'Could not open the archive',
            ja: 'アーカイブを開けませんでした',
          ),
          subtitle: context.l10n(
            ko: '잠시 후 다시 표본 색인을 불러와 주세요.',
            en: 'Try loading the specimen index again in a moment.',
            ja: 'しばらくしてから標本索引を再読み込みしてください。',
          ),
          actionLabel: context.l10n(ko: '다시 열기', en: 'Try again', ja: '再試行'),
          onAction: () =>
              ref.invalidate(zukanCollectionsProvider(projectScope)),
        ),
        data: (items) => items.isEmpty
            ? GBTEmptyState(
                icon: Icons.bookmark_add_outlined,
                title: context.l10n(
                  ko: '아직 보관된 표본이 없어요',
                  en: 'No specimens archived yet',
                  ja: 'まだ保管された標本はありません',
                ),
                subtitle: context.l10n(
                  ko: '성지를 방문하면 이 곳에 작품별 여행 기록이 쌓여요.',
                  en: 'Pilgrimage visits will build a project travel record here.',
                  ja: '聖地を訪れると、作品ごとの旅の記録がここに蓄積されます。',
                ),
              )
            : _ArchiveScrollBody(
                embedded: embedded,
                data: FieldZukanArchiveData.from(items),
                onOpen: (collection) => context.pushNamed(
                  AppRoutes.zukanDetail,
                  pathParameters: {'collectionId': collection.id},
                ),
                onRefresh: () async {
                  ref.invalidate(zukanCollectionsProvider(projectScope));
                  await ref.read(zukanCollectionsProvider(projectScope).future);
                },
              ),
      ),
    );
  }
}

class _ArchiveScrollBody extends StatelessWidget {
  const _ArchiveScrollBody({
    required this.embedded,
    required this.data,
    required this.onOpen,
    required this.onRefresh,
  });

  final bool embedded;
  final FieldZukanArchiveData data;
  final ValueChanged<ZukanCollectionSummary> onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final featured = data.featured!;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const PageStorageKey('field-zukan-archive-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              GBTSpacing.pageHorizontal,
              GBTSpacing.md,
              GBTSpacing.pageHorizontal,
              embedded
                  ? GBTSpacing.lg
                  : GBTSpacing.bottomNavClearanceOf(context),
            ),
            sliver: SliverList.list(
              children: [
                FieldArchiveMasthead(data: data),
                const SizedBox(height: GBTSpacing.lg),
                FieldFeaturedSpecimen(
                  collection: featured,
                  archiveNumber: 1,
                  onTap: () => onOpen(featured),
                ),
                if (data.indexedCollections.isNotEmpty) ...[
                  const SizedBox(height: GBTSpacing.xl),
                  const FieldArchiveIndexHeading(),
                  const SizedBox(height: GBTSpacing.sm),
                  ...data.indexedCollections.indexed.map((entry) {
                    final (index, collection) = entry;
                    return FieldArchiveIndexRow(
                      collection: collection,
                      archiveNumber: index + 2,
                      onTap: () => onOpen(collection),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Voice actor directory/search tab content.
/// KO: 성우 디렉토리/검색 탭 콘텐츠.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_image.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import '../../application/projects_controller.dart';
import '../../domain/entities/project_entities.dart';

class VoiceActorDirectoryTab extends ConsumerStatefulWidget {
  const VoiceActorDirectoryTab({
    super.key,
    required this.isActive,
    required this.projectId,
  });

  final bool isActive;
  final String projectId;

  @override
  ConsumerState<VoiceActorDirectoryTab> createState() =>
      _VoiceActorDirectoryTabState();
}

class _VoiceActorDirectoryTabState
    extends ConsumerState<VoiceActorDirectoryTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant VoiceActorDirectoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive &&
        oldWidget.projectId != widget.projectId &&
        widget.projectId.trim().isNotEmpty) {
      final state = ref.read(
        voiceActorsCatalogControllerProvider(widget.projectId),
      );
      if (state.items.isEmpty && !state.isLoading) {
        unawaited(
          ref
              .read(
                voiceActorsCatalogControllerProvider(widget.projectId).notifier,
              )
              .refresh(),
        );
      }
    }
    if (!oldWidget.isActive && widget.isActive) {
      final state = ref.read(
        voiceActorsCatalogControllerProvider(widget.projectId),
      );
      if (state.items.isEmpty && !state.isLoading) {
        unawaited(
          ref
              .read(
                voiceActorsCatalogControllerProvider(widget.projectId).notifier,
              )
              .refresh(),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.extentAfter < 300) {
      unawaited(
        ref
            .read(
              voiceActorsCatalogControllerProvider(widget.projectId).notifier,
            )
            .loadMore(),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(
        ref
            .read(
              voiceActorsCatalogControllerProvider(widget.projectId).notifier,
            )
            .search(value),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }
    if (widget.projectId.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: GBTSpacing.paddingPage,
          child: Text(
            context.l10n(
              ko: '프로젝트를 선택하면 성우 목록을 볼 수 있어요',
              en: 'Select a project to view voice actors',
              ja: 'プロジェクトを選択すると声優一覧を表示できます',
            ),
            textAlign: TextAlign.center,
            style: GBTTypography.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          ),
        ),
      );
    }
    final state = ref.watch(
      voiceActorsCatalogControllerProvider(widget.projectId),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.pageHorizontal,
            GBTSpacing.md,
            GBTSpacing.pageHorizontal,
            GBTSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _onSearchChanged(value);
              setState(() {});
            },
            onSubmitted: (value) => unawaited(
              ref
                  .read(
                    voiceActorsCatalogControllerProvider(
                      widget.projectId,
                    ).notifier,
                  )
                  .search(value),
            ),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n(
                ko: '성우 이름 검색',
                en: 'Search voice actors',
                ja: '声優名で検索',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        unawaited(
                          ref
                              .read(
                                voiceActorsCatalogControllerProvider(
                                  widget.projectId,
                                ).notifier,
                              )
                              .search(''),
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(child: _buildBody(context, state)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, VoiceActorsCatalogState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: GBTLoading());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: GBTSpacing.paddingPage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!.userMessage,
                style: GBTTypography.bodySmall.copyWith(
                  color: GBTColors.errorDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GBTSpacing.sm),
              FilledButton.tonal(
                onPressed: () => unawaited(
                  ref
                      .read(
                        voiceActorsCatalogControllerProvider(
                          widget.projectId,
                        ).notifier,
                      )
                      .refresh(),
                ),
                child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: GBTSpacing.paddingPage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_none_rounded, size: 30),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                context.l10n(
                  ko: '검색 결과가 없습니다',
                  en: 'No voice actors found',
                  ja: '検索結果がありません',
                ),
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: GBTSpacing.paddingPage,
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: GBTSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: GBTSpacing.sm),
            child: Center(child: GBTLoading()),
          );
        }
        final item = state.items[index];
        return _VoiceActorCard(item: item, projectId: widget.projectId);
      },
    );
  }
}

class _VoiceActorCard extends StatelessWidget {
  const _VoiceActorCard({required this.item, required this.projectId});

  final VoiceActorListItem item;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      onTap: () => context.goToVoiceActorDetail(
        item.id,
        projectId: projectId,
        fallbackName: item.displayName,
      ),
      child: Container(
        padding: const EdgeInsets.all(GBTSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? GBTColors.darkSurface : GBTColors.surface,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          border: Border.all(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
              child:
                  item.profileImageUrl != null &&
                      item.profileImageUrl!.isNotEmpty
                  ? GBTImage(
                      imageUrl: item.profileImageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: isDark
                          ? GBTColors.darkSurfaceVariant
                          : GBTColors.surfaceVariant,
                      child: const Icon(Icons.mic_rounded),
                    ),
            ),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: GBTTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.stageName != null &&
                      item.stageName!.isNotEmpty &&
                      item.stageName != item.displayName)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        item.stageName!,
                        style: GBTTypography.labelSmall.copyWith(
                          color: isDark
                              ? GBTColors.darkTextSecondary
                              : GBTColors.textSecondary,
                        ),
                      ),
                    ),
                  if (item.agency != null && item.agency!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.agency!,
                        style: GBTTypography.labelSmall.copyWith(
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? GBTColors.darkTextTertiary
                  : GBTColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

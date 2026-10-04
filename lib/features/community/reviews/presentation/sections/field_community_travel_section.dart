/// EN: Recent public reviews using the existing place-based review contract.
/// KO: 기존 장소 기반 레포 계약으로 최근 공개 레포를 표시합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/features/community/reviews/application/travel_reviews_controller.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review.dart';

class FieldCommunityTravelSection extends ConsumerWidget {
  const FieldCommunityTravelSection({
    super.key,
    required this.projectCode,
    required this.onWriteReview,
    required this.onOpenReview,
  });

  final String? projectCode;
  final VoidCallback onWriteReview;
  final ValueChanged<String> onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = projectCode?.trim() ?? '';
    final reviews = project.isEmpty
        ? null
        : ref.watch(travelReviewsProvider(project));
    return RefreshIndicator(
      onRefresh: () async {
        if (project.isNotEmpty) {
          ref.invalidate(travelReviewsProvider(project));
          await ref
              .read(travelReviewsProvider(project).future)
              .catchError((Object _) => <TravelReviewSummary>[]);
        }
      },
      child: CustomScrollView(
        key: const Key('field-community-travel-reviews'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(GBTSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n(ko: '여행 레포', en: 'Travel reviews', ja: '旅のレポ'),
                    style: GBTTypography.titleLarge,
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Text(
                    context.l10n(
                      ko: '방문 장소를 1곳 이상 연결해 여행과 공연의 기억을 나눠요. 게시하면 즉시 공개됩니다.',
                      en: 'Connect at least one place to share your trip and live memories. Reviews are published immediately.',
                      ja: '訪問場所を1件以上つなげて、旅やライブの思い出を共有しましょう。投稿するとすぐに公開されます。',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.md),
                  FilledButton.icon(
                    key: const Key('travel-review-create-entry'),
                    onPressed: project.isEmpty ? null : onWriteReview,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(
                      context.l10n(
                        ko: '레포 작성',
                        en: 'Write a travel review',
                        ja: 'レポを書く',
                      ),
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xl),
                  Text(
                    context.l10n(
                      ko: '최근 공개 레포',
                      en: 'Recent public reviews',
                      ja: '最近の公開レポ',
                    ),
                    style: GBTTypography.titleMedium,
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  if (project.isEmpty)
                    Text(
                      context.l10n(
                        ko: '프로젝트를 선택하면 레포를 볼 수 있어요.',
                        en: 'Select a project to read reviews.',
                        ja: 'プロジェクトを選ぶとレポを読めます。',
                      ),
                    ),
                  if (reviews != null)
                    reviews.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(GBTSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n(
                              ko: '레포를 불러오지 못했어요',
                              en: 'Reviews could not be loaded.',
                              ja: 'レポを読み込めませんでした。',
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () =>
                                ref.invalidate(travelReviewsProvider(project)),
                            child: Text(
                              context.l10n(
                                ko: '다시 시도',
                                en: 'Try again',
                                ja: '再試行',
                              ),
                            ),
                          ),
                        ],
                      ),
                      data: (items) => items.isEmpty
                          ? Text(
                              context.l10n(
                                ko: '아직 공개된 레포가 없어요',
                                en: 'No public reviews yet.',
                                ja: '公開レポはまだありません。',
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
          if (reviews?.hasError != true)
            SliverList.builder(
              itemCount: reviews?.valueOrNull?.length ?? 0,
              itemBuilder: (context, index) {
                final review = reviews!.valueOrNull![index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.md,
                    vertical: GBTSpacing.sm,
                  ),
                  title: Text(
                    review.post.title,
                    style: GBTTypography.titleMedium,
                  ),
                  subtitle: Text(
                    context.l10n(
                      ko: '장소 ${review.stops.length}곳 · 공연 ${review.events.length}개',
                      en: '${review.stops.length} places · ${review.events.length} events',
                      ja: '場所${review.stops.length}件・ライブ${review.events.length}件',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenReview(review.id),
                );
              },
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: GBTSpacing.bottomNavClearanceOf(context)),
          ),
        ],
      ),
    );
  }
}

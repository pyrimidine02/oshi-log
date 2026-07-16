import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_map_styles.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/travel_reviews_controller.dart';
import '../../domain/entities/travel_review.dart';
import '../widgets/travel_review_edit_sheet.dart';

/// EN: Server-backed pilgrimage travel-review detail page.
/// KO: 서버와 연동된 성지순례 여행 후기 상세 페이지입니다.
class TravelReviewDetailPage extends ConsumerStatefulWidget {
  const TravelReviewDetailPage({
    super.key,
    required this.projectCode,
    required this.reviewId,
  });

  final String projectCode;
  final String reviewId;

  @override
  ConsumerState<TravelReviewDetailPage> createState() =>
      _TravelReviewDetailPageState();
}

class _TravelReviewDetailPageState
    extends ConsumerState<TravelReviewDetailPage> {
  bool get _isAppleMap => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final projectCode = widget.projectCode.trim();
    if (projectCode.isEmpty) {
      return _MissingProjectScaffold(onBack: () => context.pop());
    }
    final args = (projectCode: projectCode, reviewId: widget.reviewId);
    final detail = ref.watch(travelReviewDetailProvider(args));
    final currentUserId = ref
        .watch(userProfileControllerProvider)
        .valueOrNull
        ?.id;
    final loadedReview = detail.valueOrNull;
    final canManage =
        loadedReview != null && loadedReview.post.authorId == currentUserId;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(
        context,
        title: '여행 후기',
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _showMoreOptions(projectCode, loadedReview),
              tooltip: '후기 관리',
            ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TravelReviewError(
          onRetry: () => ref.invalidate(travelReviewDetailProvider(args)),
        ),
        data: (review) => _TravelReviewContent(
          review: review,
          isAppleMap: _isAppleMap,
          projectCode: projectCode,
        ),
      ),
    );
  }

  Future<void> _showMoreOptions(
    String projectCode,
    TravelReviewDetail review,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('수정'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showEditSheet(projectCode, review);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '삭제',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(projectCode, review.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditSheet(
    String projectCode,
    TravelReviewDetail review,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          TravelReviewEditSheet(projectCode: projectCode, review: review),
    );
    if (updated == true && mounted) {
      ref.invalidate(
        travelReviewDetailProvider((
          projectCode: projectCode,
          reviewId: review.id,
        )),
      );
    }
  }

  Future<void> _confirmDelete(String projectCode, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('여행 후기를 삭제할까요?'),
        content: const Text('연결된 게시글과 여행 경로도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(travelReviewMutationControllerProvider.notifier)
        .delete(projectCode: projectCode, reviewId: reviewId);
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행 후기를 삭제했어요.')));
        context.pop();
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }
}

class _TravelReviewContent extends StatelessWidget {
  const _TravelReviewContent({
    required this.review,
    required this.isAppleMap,
    required this.projectCode,
  });

  final TravelReviewDetail review;
  final bool isAppleMap;
  final String projectCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GBTPageHeader(
            eyebrow: 'PILGRIMAGE LOG',
            title: review.post.title,
            description: _description,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.lg,
            GBTSpacing.md,
            0,
          ),
          sliver: SliverList.list(
            children: [
              _AuthorRow(review: review),
              if (review.post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: GBTSpacing.lg),
                _ReviewImages(
                  imageUrls: review.post.imageUrls,
                  semanticLabel: review.post.title,
                ),
              ],
              const SizedBox(height: GBTSpacing.lg),
              Text(
                review.post.content ?? '',
                style: GBTTypography.bodyLarge.copyWith(height: 1.6),
              ),
              if (review.routeNote?.isNotEmpty == true) ...[
                const SizedBox(height: GBTSpacing.lg),
                _RouteNote(note: review.routeNote!),
              ],
              if (review.fanSubjects.isNotEmpty) ...[
                const SizedBox(height: GBTSpacing.md),
                Wrap(
                  spacing: GBTSpacing.xs,
                  runSpacing: GBTSpacing.xs,
                  children: review.fanSubjects
                      .map(
                        (subject) => Chip(
                          avatar: Icon(_subjectIcon(subject.type), size: 18),
                          label: Text(subject.name),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: GBTSpacing.xl),
              Divider(color: colorScheme.outlineVariant),
              Wrap(
                spacing: GBTSpacing.sm,
                runSpacing: GBTSpacing.xs,
                children: [
                  TextButton.icon(
                    onPressed: () => _openPost(context),
                    icon: const Icon(Icons.favorite_border),
                    label: Text('좋아요 ${review.post.likeCount ?? 0}'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openPost(context),
                    icon: const Icon(Icons.comment_outlined),
                    label: Text('댓글 ${review.post.commentCount ?? 0}'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              ),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: GBTSpacing.xl),
              _SectionHeading(
                eyebrow: 'ROUTE NOTE',
                title: '방문한 순서',
                description: '이동한 흐름을 지도와 인증 상태로 함께 확인해보세요.',
              ),
              const SizedBox(height: GBTSpacing.md),
              _TravelRouteMap(
                reviewId: review.id,
                stops: review.stops,
                isAppleMap: isAppleMap,
                isDark: isDark,
              ),
              const SizedBox(height: GBTSpacing.sm),
              for (final stop in review.stops)
                _StopRow(stop: stop, colorScheme: colorScheme),
              if (review.events.isNotEmpty) ...[
                const SizedBox(height: GBTSpacing.xl),
                const _SectionHeading(
                  eyebrow: 'LIVE MOMENTS',
                  title: '함께한 라이브',
                  description: '여행 기록과 연결된 라이브 일정입니다.',
                ),
                const SizedBox(height: GBTSpacing.sm),
                for (final event in review.events)
                  _EventRow(event: event, colorScheme: colorScheme),
              ],
              const SizedBox(height: GBTSpacing.xl2),
            ],
          ),
        ),
      ],
    );
  }

  String get _description {
    final date = review.tripDateLabel;
    final route = '총 ${review.stops.length}곳을 이은 성지순례 기록';
    return date.isEmpty ? route : '$date · $route';
  }

  void _openPost(BuildContext context) {
    context.pushNamed(
      AppRoutes.postDetail,
      pathParameters: {'postId': review.postId},
      queryParameters: {'projectCode': projectCode},
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.review});

  final TravelReviewDetail review;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarUrl = review.post.authorAvatarUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage: avatarUrl?.isNotEmpty == true
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl?.isNotEmpty == true
              ? null
              : Icon(Icons.person, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: GBTSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                review.post.authorName?.trim().isNotEmpty == true
                    ? review.post.authorName!
                    : '여행자',
                style: GBTTypography.labelLarge,
              ),
              Text(
                review.post.timeAgoLabel,
                style: GBTTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewImages extends StatelessWidget {
  const _ReviewImages({required this.imageUrls, required this.semanticLabel});

  final List<String> imageUrls;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          child: GBTImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            semanticLabel: '$semanticLabel ${index + 1}',
          ),
        ),
      ),
    );
  }
}

class _RouteNote extends StatelessWidget {
  const _RouteNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.route_outlined, color: colorScheme.primary),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(child: Text(note, style: GBTTypography.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GBTTypography.labelSmall.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          title,
          style: GBTTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          description,
          style: GBTTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop, required this.colorScheme});

  final TravelReviewStop stop;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: GBTSpacing.sm,
        leading: SizedBox(
          width: 32,
          child: Text(
            '${stop.order + 1}'.padLeft(2, '0'),
            style: GBTTypography.labelLarge.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          stop.place.name,
          style: GBTTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stop.place.address?.isNotEmpty == true)
              Text(stop.place.address!),
            if (stop.note?.isNotEmpty == true) Text(stop.note!),
          ],
        ),
        trailing: stop.verified
            ? Icon(Icons.verified_rounded, color: colorScheme.primary)
            : const Icon(Icons.location_on_outlined),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.colorScheme});

  final TravelReviewEvent event;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: event.event.posterUrl?.isNotEmpty == true
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: GBTImage(
                    imageUrl: event.event.posterUrl!,
                    fit: BoxFit.cover,
                    semanticLabel: event.event.title,
                  ),
                ),
              )
            : const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.music_note_rounded),
              ),
        title: Text(event.event.title),
        subtitle: Text(event.event.dateLabel),
        trailing: event.verified
            ? Icon(Icons.verified_rounded, color: colorScheme.primary)
            : null,
      ),
    );
  }
}

class _TravelRouteMap extends StatelessWidget {
  const _TravelRouteMap({
    required this.reviewId,
    required this.stops,
    required this.isAppleMap,
    required this.isDark,
  });

  final String reviewId;
  final List<TravelReviewStop> stops;
  final bool isAppleMap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    if (isAppleMap) {
      final polyline = amaps.Polyline(
        polylineId: amaps.PolylineId('route_$reviewId'),
        points: stops
            .map(
              (stop) => amaps.LatLng(stop.place.latitude, stop.place.longitude),
            )
            .toList(growable: false),
        color: colorScheme.primary,
        width: 4,
        jointType: amaps.JointType.round,
      );
      final annotations = <amaps.Annotation>{
        for (final stop in stops)
          amaps.Annotation(
            annotationId: amaps.AnnotationId(stop.place.id),
            position: amaps.LatLng(stop.place.latitude, stop.place.longitude),
            infoWindow: amaps.InfoWindow(
              title: '${stop.order + 1}. ${stop.place.name}',
            ),
          ),
      };
      return SizedBox(
        height: 184,
        child: Stack(
          fit: StackFit.expand,
          children: [
            amaps.AppleMap(
              initialCameraPosition: amaps.CameraPosition(
                target: amaps.LatLng(
                  stops.first.place.latitude,
                  stops.first.place.longitude,
                ),
                zoom: 12,
              ),
              polylines: {polyline},
              annotations: annotations,
              scrollGesturesEnabled: false,
            ),
            IgnorePointer(
              child: ColoredBox(
                color: gbtAppleMapOverlayColorForDarkMode(isDark),
              ),
            ),
          ],
        ),
      );
    }

    final polyline = gmaps.Polyline(
      polylineId: const gmaps.PolylineId('route'),
      points: stops
          .map(
            (stop) => gmaps.LatLng(stop.place.latitude, stop.place.longitude),
          )
          .toList(growable: false),
      color: colorScheme.primary,
      width: 4,
      jointType: gmaps.JointType.round,
    );
    final markers = <gmaps.Marker>{
      for (final stop in stops)
        gmaps.Marker(
          markerId: gmaps.MarkerId(stop.place.id),
          position: gmaps.LatLng(stop.place.latitude, stop.place.longitude),
          infoWindow: gmaps.InfoWindow(
            title: '${stop.order + 1}. ${stop.place.name}',
          ),
        ),
    };
    return SizedBox(
      height: 184,
      child: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(
            stops.first.place.latitude,
            stops.first.place.longitude,
          ),
          zoom: 12,
        ),
        style: gbtGoogleMapStyleForDarkMode(isDark),
        polylines: {polyline},
        markers: markers,
        scrollGesturesEnabled: false,
      ),
    );
  }
}

class _TravelReviewError extends StatelessWidget {
  const _TravelReviewError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44),
            const SizedBox(height: GBTSpacing.sm),
            const Text('여행 후기를 불러오지 못했어요.'),
            const SizedBox(height: GBTSpacing.sm),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _MissingProjectScaffold extends StatelessWidget {
  const _MissingProjectScaffold({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gbtStandardAppBar(context, title: '여행 후기'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_off_outlined, size: 44),
              const SizedBox(height: GBTSpacing.sm),
              const Text('프로젝트를 먼저 선택해주세요.'),
              const SizedBox(height: GBTSpacing.sm),
              OutlinedButton(onPressed: onBack, child: const Text('돌아가기')),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _subjectIcon(String type) => switch (type.toUpperCase()) {
  'PROJECT' => Icons.folder_outlined,
  'UNIT' => Icons.groups_outlined,
  'VOICE_ACTOR' => Icons.person_outline_rounded,
  'ARTIST' => Icons.mic_external_on_outlined,
  'ANIME' => Icons.movie_filter_outlined,
  _ => Icons.auto_awesome_outlined,
};

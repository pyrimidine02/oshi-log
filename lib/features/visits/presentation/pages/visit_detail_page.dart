/// EN: Visit detail rendered as an Urban Travel Field Notes record.
/// KO: Urban Travel Field Notes 기록 형식으로 표현하는 방문 상세 화면입니다.
library;

import 'dart:math' show log;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_map_styles.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../places/domain/entities/place_entities.dart';
import '../../application/visits_controller.dart';
import '../../domain/entities/visit_entities.dart';

/// EN: Shows one immutable visit record and its supporting evidence.
/// KO: 하나의 불변 방문 기록과 그 근거 정보를 표시합니다.
class VisitDetailPage extends ConsumerWidget {
  const VisitDetailPage({
    super.key,
    required this.visitId,
    required this.placeId,
    this.visitedAt,
  });

  final String visitId;
  final String placeId;
  final String? visitedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesMapState = ref.watch(visitPlacesMapProvider);
    final summaryState = ref.watch(visitSummaryProvider(placeId));
    final detailState = ref.watch(visitDetailProvider(visitId));
    final place = placesMapState.valueOrNull?[placeId];
    final detail = detailState.valueOrNull;
    final isVerified = detail?.isVerified ?? false;
    final distanceM = detail?.distanceM;
    final visitedAtLabel = _formatVisitedAt(
      detail?.visitedAt?.toIso8601String() ?? visitedAt,
    );
    final latitude = place?.latitude;
    final longitude = place?.longitude;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '방문 기록', en: 'Visit record', ja: '訪問記録'),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: VisitDetailDocumentHeader(
              placeName:
                  place?.name ??
                  context.l10n(
                    ko: '장소를 확인하는 중',
                    en: 'Loading place',
                    ja: '場所を確認中',
                  ),
              visitedAt: visitedAtLabel,
              verificationLabel: _verificationLabel(
                context,
                isVerified: isVerified,
                distanceM: distanceM,
              ),
              isVerified: isVerified,
            ),
          ),
          SliverToBoxAdapter(
            child: _PlaceInfoSection(
              place: place,
              isLoading: placesMapState.isLoading,
              onViewPlace: () => context.goToPlaceDetail(placeId),
            ),
          ),
          if (latitude != null && longitude != null)
            SliverToBoxAdapter(
              child: _MapSection(
                latitude: latitude,
                longitude: longitude,
                isVerificationLocation: isVerified,
                distanceM: distanceM,
              ),
            ),
          SliverToBoxAdapter(
            child: _VisitStatsSection(summaryState: summaryState),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.lg,
                GBTSpacing.md,
                GBTSpacing.md,
              ),
              child: FilledButton.icon(
                onPressed: () => context.goToPlaceDetail(placeId),
                icon: const Icon(Icons.arrow_outward_rounded),
                label: Text(
                  context.l10n(
                    ko: '장소 상세 보기',
                    en: 'View place details',
                    ja: '場所詳細を見る',
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).bottom + GBTSpacing.lg,
            ),
          ),
        ],
      ),
    );
  }

  String _formatVisitedAt(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('yyyy.MM.dd HH:mm').format(date.toLocal());
  }

  String _verificationLabel(
    BuildContext context, {
    required bool isVerified,
    required double? distanceM,
  }) {
    if (!isVerified) {
      return context.l10n(ko: 'GPS 미인증', en: 'GPS not verified', ja: 'GPS未認証');
    }
    if (distanceM == null) {
      return context.l10n(ko: 'GPS 인증 완료', en: 'GPS verified', ja: 'GPS認証済み');
    }
    final distance = distanceM < 1000
        ? '${distanceM.toStringAsFixed(1)}m'
        : '${(distanceM / 1000).toStringAsFixed(2)}km';
    return context.l10n(
      ko: 'GPS 인증 · $distance',
      en: 'GPS verified · $distance',
      ja: 'GPS認証済み · $distance',
    );
  }
}

/// EN: Compact document identity for one visit record.
/// KO: 하나의 방문 기록을 식별하는 컴팩트 문서 헤더입니다.
class VisitDetailDocumentHeader extends StatelessWidget {
  const VisitDetailDocumentHeader({
    super.key,
    required this.placeName,
    required this.visitedAt,
    required this.verificationLabel,
    required this.isVerified,
  });

  final String placeName;
  final String visitedAt;
  final String verificationLabel;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const ValueKey('visit-detail-document-header'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.lg,
        GBTSpacing.md,
        GBTSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.primary, width: 3),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VISIT LOG',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            placeName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
          _RecordDatum(
            label: context.l10n(ko: '방문 일시', en: 'Visited at', ja: '訪問日時'),
            value: visitedAt.isEmpty ? '-' : visitedAt,
          ),
          const Divider(height: GBTSpacing.lg),
          _RecordDatum(
            label: context.l10n(ko: '위치 확인', en: 'Location check', ja: '位置確認'),
            value: verificationLabel,
            icon: isVerified
                ? Icons.check_circle_outline_rounded
                : Icons.gps_off_rounded,
          ),
        ],
      ),
    );
  }
}

class _RecordDatum extends StatelessWidget {
  const _RecordDatum({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: GBTSpacing.xs),
              ],
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceInfoSection extends StatelessWidget {
  const _PlaceInfoSection({
    required this.place,
    required this.isLoading,
    required this.onViewPlace,
  });

  final PlaceSummary? place;
  final bool isLoading;
  final VoidCallback onViewPlace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.xl,
        GBTSpacing.md,
        GBTSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldSectionHeader(
            indexLabel: '01',
            title: context.l10n(ko: '장소 정보', en: 'Place', ja: '場所情報'),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: GBTSpacing.md),
              child: GBTShimmer(
                child: GBTShimmerContainer(height: 72, width: double.infinity),
              ),
            )
          else if (place != null)
            _PlaceRecordRow(place: place!, onTap: onViewPlace)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
              child: Text(
                context.l10n(
                  ko: '장소 정보를 불러올 수 없습니다.',
                  en: 'Could not load place information.',
                  ja: '場所情報を読み込めません。',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceRecordRow extends StatelessWidget {
  const _PlaceRecordRow({required this.place, required this.onTap});

  final PlaceSummary place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          Clipboard.setData(
            ClipboardData(text: '${place.name}\n${place.address}'),
          );
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n(
                  ko: '장소 정보가 복사되었습니다',
                  en: 'Place info copied',
                  ja: '場所情報がコピーされました',
                ),
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: place.imageUrl != null && place.imageUrl!.isNotEmpty
                    ? GBTImage(
                        imageUrl: place.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        semanticLabel: place.name,
                      )
                    : ColoredBox(
                        color: colors.surfaceContainer,
                        child: Icon(
                          Icons.place_outlined,
                          color: colors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (place.address.isNotEmpty) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        place.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Icon(Icons.arrow_outward_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.latitude,
    required this.longitude,
    required this.isVerificationLocation,
    this.distanceM,
  });

  final double latitude;
  final double longitude;
  final bool isVerificationLocation;
  final double? distanceM;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = isVerificationLocation
        ? context.l10n(ko: '인증 위치', en: 'Verified location', ja: '認証位置')
        : context.l10n(ko: '장소 위치', en: 'Place location', ja: '場所位置');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.xl,
        GBTSpacing.md,
        GBTSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldSectionHeader(indexLabel: '02', title: title),
          if (!isVerificationLocation) ...[
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: '장소 좌표를 기준으로 표시한 추정 위치입니다.',
                en: 'Approximate position based on the place coordinates.',
                ja: '場所座標を基準にした推定位置です。',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: GBTSpacing.md),
          Container(
            height: 184,
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: kIsWeb ? _mapPlaceholder(context) : _buildMap(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = isVerificationLocation
        ? context.l10n(ko: '인증 위치', en: 'Verified location', ja: '認証位置')
        : context.l10n(ko: '장소 위치', en: 'Place location', ja: '場所位置');
    final zoom = _zoomForRadius(distanceM);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Stack(
        fit: StackFit.expand,
        children: [
          amaps.AppleMap(
            initialCameraPosition: amaps.CameraPosition(
              target: amaps.LatLng(latitude, longitude),
              zoom: zoom,
            ),
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            annotations: {
              amaps.Annotation(
                annotationId: amaps.AnnotationId('visit_pin'),
                position: amaps.LatLng(latitude, longitude),
                infoWindow: amaps.InfoWindow(title: label),
              ),
            },
            circles: {
              if (distanceM != null)
                amaps.Circle(
                  circleId: amaps.CircleId('verification_radius'),
                  center: amaps.LatLng(latitude, longitude),
                  radius: distanceM!,
                  strokeColor: GBTColors.primary.withValues(alpha: 0.8),
                  strokeWidth: 2,
                  fillColor: GBTColors.primary.withValues(alpha: 0.12),
                ),
            },
          ),
          IgnorePointer(
            child: ColoredBox(
              color: gbtAppleMapOverlayColorForDarkMode(isDark),
            ),
          ),
        ],
      );
    }
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(latitude, longitude),
        zoom: zoom,
      ),
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      style: gbtGoogleMapStyleForDarkMode(isDark),
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('visit_pin'),
          position: gmaps.LatLng(latitude, longitude),
          infoWindow: gmaps.InfoWindow(title: label),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
      },
      circles: {
        if (distanceM != null)
          gmaps.Circle(
            circleId: const gmaps.CircleId('verification_radius'),
            center: gmaps.LatLng(latitude, longitude),
            radius: distanceM!,
            strokeColor: GBTColors.primary.withValues(alpha: 0.8),
            strokeWidth: 2,
            fillColor: GBTColors.primary.withValues(alpha: 0.12),
          ),
      },
    );
  }

  double _zoomForRadius(double? radius) {
    if (radius == null || radius <= 0) return 16;
    final diameter = radius * 6;
    final zoom = 16 - (log(diameter / 500) / log(2));
    return zoom.clamp(10, 18).toDouble();
  }

  Widget _mapPlaceholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainer,
      child: Center(
        child: Text(
          context.l10n(
            ko: '웹에서는 지도를 지원하지 않습니다',
            en: 'Map is not supported on web',
            ja: 'Webでは地図をサポートしていません',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _VisitStatsSection extends StatelessWidget {
  const _VisitStatsSection({required this.summaryState});

  final AsyncValue<VisitSummary?> summaryState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.xl,
        GBTSpacing.md,
        GBTSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldSectionHeader(
            indexLabel: '03',
            title: context.l10n(
              ko: '이 장소의 방문 이력',
              en: 'History at this place',
              ja: 'この場所の訪問履歴',
            ),
          ),
          summaryState.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: GBTSpacing.md),
              child: GBTShimmer(
                child: GBTShimmerContainer(height: 96, width: double.infinity),
              ),
            ),
            error: (_, __) => _SectionMessage(
              message: context.l10n(
                ko: '통계를 불러올 수 없습니다.',
                en: 'Could not load stats.',
                ja: '統計を読み込めません。',
              ),
            ),
            data: (summary) => summary == null
                ? _SectionMessage(
                    message: context.l10n(
                      ko: '통계 정보가 없습니다.',
                      en: 'No stats available.',
                      ja: '統計情報がありません。',
                    ),
                  )
                : Column(
                    children: [
                      _LedgerRow(
                        label: context.l10n(
                          ko: '총 방문',
                          en: 'Total visits',
                          ja: '総訪問',
                        ),
                        value: context.l10n(
                          ko: '${summary.visitCount}회',
                          en: '${summary.visitCount}',
                          ja: '${summary.visitCount}回',
                        ),
                      ),
                      _LedgerRow(
                        label: context.l10n(
                          ko: '첫 방문',
                          en: 'First visit',
                          ja: '初回訪問',
                        ),
                        value: summary.firstVisitedLabel.isEmpty
                            ? '-'
                            : summary.firstVisitedLabel,
                      ),
                      _LedgerRow(
                        label: context.l10n(
                          ko: '최근 방문',
                          en: 'Latest visit',
                          ja: '最近の訪問',
                        ),
                        value: summary.lastVisitedLabel.isEmpty
                            ? '-'
                            : summary.lastVisitedLabel,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FieldSectionHeader extends StatelessWidget {
  const _FieldSectionHeader({required this.indexLabel, required this.title});

  final String indexLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              indexLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: GBTSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

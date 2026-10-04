/// EN: Supplies the catalog project lens to live feature pages, so live
/// presentation never imports catalog presentation directly.
/// KO: live feature 화면에 catalog project lens를 공급하여 live presentation이
/// catalog presentation을 직접 import하지 않도록 합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_events/field_live_event_detail_page.dart';

import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/field_project_lens.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_calendar/field_calendar_page.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_events/field_live_events_page.dart';

/// EN: Host-composed calendar page with the catalog lens slot filled.
/// KO: catalog lens 슬롯을 채운 host 조합 캘린더 화면입니다.
Widget buildFieldCalendarPage({Key? key}) {
  return FieldCalendarPage(key: key, projectLens: const FieldProjectLens());
}

/// EN: Host-composed live events page with the catalog lens slot filled.
/// KO: catalog lens 슬롯을 채운 host 조합 라이브 이벤트 화면입니다.
Widget buildFieldLiveEventsPage({Key? key, bool embedded = false}) {
  return FieldLiveEventsPage(
    key: key,
    embedded: embedded,
    projectLens: const FieldProjectLens(),
  );
}

/// EN: Composes venue preparation without live-to-place presentation coupling.
/// KO: 라이브와 장소 화면을 직접 결합하지 않고 회장 준비 정보를 조합합니다.
Widget buildFieldLiveEventDetailPage({Key? key, required String eventId}) {
  return FieldLiveEventDetailPage(
    key: key,
    eventId: eventId,
    preparationBuilder: (_, event) => _VenuePreparation(event: event),
  );
}

final _eventNearbyPlacesProvider = FutureProvider.autoDispose
    .family<
      List<({PlaceSummary place, double meters})>?,
      ({String projectId, String placeId})
    >((ref, query) async {
      final repository = await ref.watch(placesRepositoryProvider.future);
      final result = await repository.getAllPlaces(projectId: query.projectId);
      final places = result.when(
        success: (items) => items,
        failure: (failure) => throw failure,
      );
      final venue = places
          .where((place) => place.id == query.placeId)
          .firstOrNull;
      if (venue == null || !_hasCoordinates(venue)) return null;
      final nearby =
          places
              .where((place) => place.id != venue.id && _hasCoordinates(place))
              .map(
                (place) => (
                  place: place,
                  meters: Geolocator.distanceBetween(
                    venue.latitude,
                    venue.longitude,
                    place.latitude,
                    place.longitude,
                  ),
                ),
              )
              .where((item) => item.meters.isFinite && item.meters <= 3000)
              .toList()
            ..sort((a, b) => a.meters.compareTo(b.meters));
      return nearby.take(5).toList(growable: false);
    });

bool _hasCoordinates(PlaceSummary place) =>
    place.latitude.isFinite &&
    place.longitude.isFinite &&
    place.latitude.abs() <= 90 &&
    place.longitude.abs() <= 180;

class _VenuePreparation extends ConsumerWidget {
  const _VenuePreparation({required this.event});
  final LiveEventDetail event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeId = event.placeId?.trim() ?? '';
    final projectId = resolveLiveEventProjectContext(
      eventProjectIds: event.projectIds,
      selectedProjectKey: ref.watch(selectedProjectKeyProvider),
      selectedProjectId: ref.watch(selectedProjectIdProvider),
    );
    if (placeId.isEmpty) return const SizedBox.shrink();
    final guides = ref.watch(placeGuidesControllerProvider(placeId));
    final query = projectId == null
        ? null
        : (projectId: projectId, placeId: placeId);
    final nearby = query == null
        ? const AsyncData<List<({PlaceSummary place, double meters})>?>(null)
        : ref.watch(_eventNearbyPlacesProvider(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n(ko: '회장 가이드', en: 'Venue guides', ja: '会場ガイド'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        guides.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref
                .read(placeGuidesControllerProvider(placeId).notifier)
                .load(forceRefresh: true),
            child: Text(
              context.l10n(
                ko: '가이드 다시 불러오기',
                en: 'Retry venue guides',
                ja: 'ガイドを再読み込み',
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? Text(
                  context.l10n(
                    ko: '등록된 회장 가이드가 없어요.',
                    en: 'No venue guide registered.',
                    ja: '会場ガイドは未登録です。',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final guide in items.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(guide.title),
                        subtitle: Text(guide.preview),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.goToPlaceDetail(placeId),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: GBTSpacing.lg),
        Text(
          context.l10n(
            ko: '개장 전 주변 장소 · 직선거리',
            en: 'Nearby before doors · straight-line distance',
            ja: '開場までの周辺スポット・直線距離',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        nearby.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: query == null
                ? null
                : () => ref.invalidate(_eventNearbyPlacesProvider(query)),
            child: Text(
              context.l10n(
                ko: '주변 장소 다시 불러오기',
                en: 'Retry nearby places',
                ja: '周辺スポットを再読み込み',
              ),
            ),
          ),
          data: (items) => items == null
              ? Text(
                  context.l10n(
                    ko: '회장 위치가 확인되면 주변 장소를 표시해요.',
                    en: 'Nearby places appear once the venue location is available.',
                    ja: '会場の位置を確認できると周辺スポットを表示します。',
                  ),
                )
              : items.isEmpty
              ? Text(
                  context.l10n(
                    ko: '회장 주변 3km 이내의 확인 가능한 장소가 없어요.',
                    en: 'No available places within 3 km of the venue.',
                    ja: '会場から3km以内の表示可能なスポットはありません。',
                  ),
                )
              : Column(
                  children: [
                    for (final item in items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.place.name),
                        subtitle: Text(
                          '${item.meters.round()} m · ${context.l10n(ko: '직선거리', en: 'straight-line', ja: '直線距離')}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.goToPlaceDetail(item.place.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

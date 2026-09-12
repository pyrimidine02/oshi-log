/// EN: Searchable place picker for building an ordered pilgrimage route.
/// KO: 정렬된 성지순례 경로를 만드는 검색형 장소 선택기입니다.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../places/application/places_controller.dart';
import '../../../places/domain/entities/place_entities.dart';

class TravelReviewPlacePickerSheet extends ConsumerStatefulWidget {
  const TravelReviewPlacePickerSheet({
    super.key,
    required this.selectedIds,
    required this.onAdd,
  });

  final Set<String> selectedIds;
  final ValueChanged<PlaceSummary> onAdd;

  @override
  ConsumerState<TravelReviewPlacePickerSheet> createState() =>
      _TravelReviewPlacePickerSheetState();
}

class _TravelReviewPlacePickerSheetState
    extends ConsumerState<TravelReviewPlacePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final places = ref.watch(placesListControllerProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              0,
              GBTSpacing.md,
              GBTSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '어디를 다녀왔나요?',
                        style: GBTTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, GBTSpacing.touchTarget),
                      ),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
                const SizedBox(height: GBTSpacing.sm),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GBTTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '장소명 또는 주소로 검색',
                    hintStyle: GBTTypography.bodyMedium.copyWith(
                      color: tertiaryColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: tertiaryColor,
                      size: 20,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clearSearch,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: tertiaryColor,
                            ),
                          ),
                    filled: false,
                    border: const UnderlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
          Expanded(
            child: places.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (error, _) => _PlacePickerMessage(
                icon: Icons.cloud_off_rounded,
                message: '장소를 불러오지 못했어요.',
                color: tertiaryColor,
              ),
              data: (all) {
                final filtered = _filtered(all);
                if (filtered.isEmpty) {
                  return _PlacePickerMessage(
                    icon: Icons.search_off_rounded,
                    message: _query.isEmpty
                        ? '등록된 장소가 없어요.'
                        : '"$_query" 검색 결과가 없어요.',
                    color: tertiaryColor,
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: GBTSpacing.md,
                    endIndent: GBTSpacing.md,
                    color: borderColor.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final place = filtered[index];
                    final added = widget.selectedIds.contains(place.id);
                    return _PlacePickerItem(
                      place: place,
                      isAdded: added,
                      primaryColor: primaryColor,
                      tertiaryColor: tertiaryColor,
                      onTap: added ? null : () => _select(place),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  List<PlaceSummary> _filtered(List<PlaceSummary> all) {
    if (_query.isEmpty) return all;
    final normalized = _query.toLowerCase();
    return all
        .where(
          (place) =>
              place.name.toLowerCase().contains(normalized) ||
              place.address.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  void _select(PlaceSummary place) {
    widget.onAdd(place);
    Navigator.of(context).pop();
  }
}

class _PlacePickerItem extends StatelessWidget {
  const _PlacePickerItem({
    required this.place,
    required this.isAdded,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.onTap,
  });

  final PlaceSummary place;
  final bool isAdded;
  final Color primaryColor;
  final Color tertiaryColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark
        ? (isAdded ? GBTColors.darkTextTertiary : GBTColors.darkTextPrimary)
        : (isAdded ? GBTColors.textTertiary : GBTColors.textPrimary);
    return Semantics(
      button: !isAdded,
      selected: isAdded,
      label: '${place.name}, ${place.address}',
      hint: isAdded ? '이미 여정에 추가됨' : '탭하면 여정에 추가합니다',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: [
              _PlaceThumbnail(place: place, color: tertiaryColor),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GBTTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: contentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address,
                      style: GBTTypography.labelSmall.copyWith(
                        color: tertiaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  isAdded ? Icons.check_rounded : Icons.add_rounded,
                  color: isAdded ? tertiaryColor : primaryColor,
                  semanticLabel: isAdded ? '추가됨' : '추가',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceThumbnail extends StatelessWidget {
  const _PlaceThumbnail({required this.place, required this.color});

  final PlaceSummary place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final imageUrl = place.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl?.isNotEmpty == true
          ? SizedBox(
              width: 48,
              height: 48,
              child: GBTImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                semanticLabel: '${place.name} 이미지',
              ),
            )
          : Container(
              width: 48,
              height: 48,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.place_rounded, size: 22, color: color),
            ),
    );
  }
}

class _PlacePickerMessage extends StatelessWidget {
  const _PlacePickerMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: GBTSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GBTTypography.bodyMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

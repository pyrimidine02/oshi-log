/// EN: Clean-sheet information root for travel and fandom field research.
/// KO: 여행과 팬덤 현장 탐색을 위해 새로 설계한 정보 루트.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../application/news_controller.dart';
import '../../domain/entities/feed_entities.dart';
import 'field_guide_music_page.dart';
import 'field_guide_providers.dart';
import 'sections/field_guide_artists_section.dart';
import 'sections/field_guide_kit_section.dart';
import 'sections/field_guide_updates_section.dart';
import 'widgets/field_guide_masthead.dart';
import 'widgets/field_guide_section_switcher.dart';

/// EN: Editorial information hub with updates, artists, and practical tools.
/// KO: 업데이트, 아티스트, 현장 도구를 묶은 에디토리얼 정보 허브.
class FieldGuidePage extends ConsumerStatefulWidget {
  const FieldGuidePage({super.key});

  @override
  ConsumerState<FieldGuidePage> createState() => _FieldGuidePageState();
}

class _FieldGuidePageState extends ConsumerState<FieldGuidePage> {
  FieldGuideSection _selectedSection = FieldGuideSection.updates;

  Future<void> _refreshUpdates() async {
    await ref
        .read(newsListControllerProvider.notifier)
        .load(forceRefresh: true);
  }

  Future<void> _refreshArtists() async {
    final projectKey = ref.read(fieldGuideProjectKeyProvider)?.trim();
    if (projectKey == null || projectKey.isEmpty) {
      return;
    }
    await ref
        .read(projectUnitsControllerProvider(projectKey).notifier)
        .load(forceRefresh: true);
  }

  void _openUpdate(NewsSummary update) {
    context.goToNewsDetail(update.id);
  }

  void _openArtist(Unit artist) {
    final projectKey = ref.read(fieldGuideProjectKeyProvider)?.trim();
    if (projectKey == null || projectKey.isEmpty) {
      return;
    }
    context.goToUnitDetail(unit: artist, projectId: projectKey);
  }

  void _openMusicArchive() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const FieldGuideMusicPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectKey = ref.watch(fieldGuideProjectKeyProvider);

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FieldGuideMasthead(
              projectKey: projectKey,
              onSearch: () => context.push('/search'),
            ),
            FieldGuideSectionSwitcher(
              selected: _selectedSection,
              onSelected: (section) {
                if (_selectedSection == section) {
                  return;
                }
                setState(() => _selectedSection = section);
              },
            ),
            Expanded(child: _buildSelectedSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSection() {
    return switch (_selectedSection) {
      FieldGuideSection.updates => FieldGuideUpdatesSection(
        onRefresh: _refreshUpdates,
        onUpdateTap: _openUpdate,
      ),
      FieldGuideSection.artists => FieldGuideArtistsSection(
        onRefresh: _refreshArtists,
        onArtistTap: _openArtist,
      ),
      FieldGuideSection.kit => FieldGuideKitSection(
        onMusicTap: _openMusicArchive,
        onCheerGuidesTap: () => context.push('/cheer-guides'),
        onCalendarTap: () => context.push('/calendar'),
        onQuotesTap: () => context.push('/quotes'),
        onCollectionTap: () => context.push('/zukan'),
      ),
    };
  }
}

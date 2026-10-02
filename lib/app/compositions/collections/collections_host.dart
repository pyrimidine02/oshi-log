/// EN: App-level host wiring the catalog project picker into the zukan
///     archive page so the zukan feature stays free of catalog imports.
/// KO: 도감 아카이브 페이지에 catalog 프로젝트 피커를 연결하는 app 레벨
///     호스트. zukan feature가 catalog에 직접 의존하지 않도록 합니다.
library;

import 'package:flutter/material.dart';

import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/field_project_picker_sheet.dart';
import 'package:oshi_log/features/zukan/presentation/field_archive/field_zukan_archive_page.dart';

/// EN: Hosts FieldZukanArchivePage with the catalog project picker supplied
///     from the app composition layer.
/// KO: app 조합 레이어에서 catalog 프로젝트 피커를 공급하여
///     FieldZukanArchivePage를 호스팅합니다.
class CollectionsHost extends StatelessWidget {
  const CollectionsHost({super.key, this.embedded = false});

  final bool embedded;

  Future<Project?> _pickProject(
    BuildContext context,
    List<Project> projects,
    Project selectedProject,
  ) {
    return showFieldProjectPicker(
      context: context,
      projects: projects,
      selectedProject: selectedProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FieldZukanArchivePage(
      embedded: embedded,
      onPickProject: _pickProject,
    );
  }
}

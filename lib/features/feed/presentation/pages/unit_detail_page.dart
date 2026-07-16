/// EN: Unit dossier page with a compact editorial roster.
/// KO: 컴팩트한 에디토리얼 로스터를 제공하는 유닛 기록 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';

/// EN: Loads the unit contract and keeps routed member navigation intact.
/// KO: 유닛 계약을 불러오고 기존 멤버 상세 이동을 그대로 유지합니다.
class UnitDetailPage extends ConsumerWidget {
  const UnitDetailPage({
    super.key,
    required this.projectId,
    required this.unitIdentifier,
    this.initialUnit,
  });

  final String projectId;
  final String unitIdentifier;
  final Unit? initialUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitState = ref.watch(
      unitDetailProvider((projectId, unitIdentifier)),
    );
    final unit =
        unitState.valueOrNull ??
        initialUnit ??
        Unit(id: unitIdentifier, code: unitIdentifier, displayName: '유닛');
    final resolvedUnitIdentifier = unit.code.isNotEmpty ? unit.code : unit.id;
    final membersState = ref.watch(
      unitMembersControllerProvider((projectId, resolvedUnitIdentifier)),
    );

    return Scaffold(
      appBar: gbtStandardAppBar(context, title: '유닛 기록'),
      body: UnitDossierView(
        unit: unit,
        membersState: membersState,
        onMemberTap: (member) => context.goToMemberDetail(
          unit: unit,
          member: member,
          projectId: projectId,
        ),
      ),
    );
  }
}

/// EN: Displays real unit metadata and a borderless indexed member roster.
/// KO: 실제 유닛 메타데이터와 테두리 없는 인덱스형 멤버 명부를 표시합니다.
class UnitDossierView extends StatelessWidget {
  const UnitDossierView({
    super.key,
    required this.unit,
    required this.membersState,
    required this.onMemberTap,
  });

  final Unit unit;
  final AsyncValue<List<UnitMember>> membersState;
  final ValueChanged<UnitMember> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final metadata = _unitMetadata(unit);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: GBTPageHeader(
              eyebrow: 'UNIT DOSSIER',
              title: unit.displayName,
              description: metadata.isEmpty ? null : metadata,
            ),
          ),
          if (unit.description?.trim().isNotEmpty == true)
            SliverToBoxAdapter(
              child: _EditorialNote(text: unit.description!.trim()),
            ),
          SliverToBoxAdapter(
            child: _DossierSectionHeader(
              index: '01',
              eyebrow: 'ROSTER',
              title: '멤버 · 성우',
              detail: membersState.valueOrNull == null
                  ? null
                  : '${membersState.valueOrNull!.length}명',
            ),
          ),
          membersState.when<Widget>(
            loading: () =>
                const SliverToBoxAdapter(child: _RosterLoadingState()),
            error: (_, __) => const SliverToBoxAdapter(
              child: GBTEmptyState(
                icon: Icons.sync_problem_outlined,
                title: '멤버 기록을 불러오지 못했어요',
                subtitle: '잠시 후 다시 확인해 주세요.',
              ),
            ),
            data: (members) {
              if (members.isEmpty) {
                return const SliverToBoxAdapter(
                  child: GBTEmptyState(
                    icon: Icons.groups_outlined,
                    title: '아직 등록된 멤버가 없어요',
                    subtitle: '멤버 정보가 추가되면 이 명부에 표시됩니다.',
                  ),
                );
              }

              final sortedMembers = List<UnitMember>.of(members)
                ..sort(_compareMembers);
              return SliverList.builder(
                itemCount: sortedMembers.length,
                itemBuilder: (context, index) {
                  final member = sortedMembers[index];
                  return _MemberIndexRow(
                    index: index + 1,
                    member: member,
                    onTap: () => onMemberTap(member),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: GBTSpacing.bottomNavClearance),
          ),
        ],
      ),
    );
  }
}

String _unitMetadata(Unit unit) {
  final values = <String>[
    if (unit.code.trim().isNotEmpty) unit.code.trim(),
    if (unit.status?.trim().isNotEmpty == true) unit.status!.trim(),
    if (unit.debutDate?.trim().isNotEmpty == true)
      '데뷔 ${unit.debutDate!.trim()}',
  ];
  return values.join('  ·  ');
}

int _compareMembers(UnitMember left, UnitMember right) {
  final leftOrder = left.order;
  final rightOrder = right.order;
  if (leftOrder != null && rightOrder != null) {
    final orderComparison = leftOrder.compareTo(rightOrder);
    if (orderComparison != 0) return orderComparison;
  } else if (leftOrder != null) {
    return -1;
  } else if (rightOrder != null) {
    return 1;
  }
  return left.name.compareTo(right.name);
}

/// EN: A left-rule note replaces the former elevated profile card.
/// KO: 왼쪽 규칙선 메모로 이전의 돌출형 프로필 카드를 대체합니다.
class _EditorialNote extends StatelessWidget {
  const _EditorialNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.lg,
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: GBTSpacing.md),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.65,
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Numbered editorial section marker shared within this dossier.
/// KO: 이 기록 화면 안에서 공유하는 번호형 에디토리얼 섹션 표식입니다.
class _DossierSectionHeader extends StatelessWidget {
  const _DossierSectionHeader({
    required this.index,
    required this.eyebrow,
    required this.title,
    this.detail,
  });

  final String index;
  final String eyebrow;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.xl,
        GBTResponsiveSpacing.pageHorizontal(context),
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant, width: 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: GBTSpacing.xl,
                child: Text(
                  index,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs2),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        detail!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Borderless roster row with a stable 48dp interaction target.
/// KO: 안정적인 48dp 상호작용 영역을 가진 테두리 없는 명부 행입니다.
class _MemberIndexRow extends StatelessWidget {
  const _MemberIndexRow({
    required this.index,
    required this.member,
    required this.onTap,
  });

  final int index;
  final UnitMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final metadata = <String>[
      if (member.instrument?.trim().isNotEmpty == true)
        member.instrument!.trim(),
      if (member.role?.trim().isNotEmpty == true &&
          member.role!.trim() != member.instrument?.trim())
        member.role!.trim(),
    ];
    final birthdayDays = daysUntilBirthday(member.birthdate);

    return Semantics(
      button: true,
      label: [
        member.name,
        if (member.voiceActorName?.trim().isNotEmpty == true)
          'CV ${member.voiceActorName!.trim()}',
        ...metadata,
      ].join('. '),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: GBTSpacing.touchTarget,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: GBTResponsiveSpacing.pageHorizontal(context),
            ),
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: GBTSpacing.xl,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (member.characterNameKana?.trim().isNotEmpty ==
                          true) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          member.characterNameKana!.trim(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (member.voiceActorName?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: GBTSpacing.sm),
                        Text(
                          'CV  ${member.voiceActorName!.trim()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          metadata.join('  ·  '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (birthdayDays != null && birthdayDays <= 7) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          birthdayDays == 0 ? '오늘 생일' : '생일까지 $birthdayDays일',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: GBTSpacing.touchTarget,
                  height: GBTSpacing.touchTarget,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.onSurfaceVariant,
                    size: GBTSpacing.iconSm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Loading rows preserve the dossier rhythm without card placeholders.
/// KO: 카드 플레이스홀더 없이 기록 화면의 리듬을 유지하는 로딩 행입니다.
class _RosterLoadingState extends StatelessWidget {
  const _RosterLoadingState();

  @override
  Widget build(BuildContext context) {
    final horizontal = GBTResponsiveSpacing.pageHorizontal(context);
    return GBTShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: GBTShimmerContainer(
                width: double.infinity,
                height: 64,
                borderRadius: GBTSpacing.radiusXs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

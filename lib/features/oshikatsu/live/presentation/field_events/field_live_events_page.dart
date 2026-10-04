/// EN: Live schedule reuses the month agenda and calendar provider.
/// KO: 라이브 일정은 월별 목록과 캘린더 데이터 공급자를 재사용합니다.
library;

import 'package:flutter/material.dart';
import '../field_calendar/field_calendar_page.dart';

class FieldLiveEventsPage extends StatelessWidget {
  const FieldLiveEventsPage({
    super.key,
    this.embedded = false,
    required this.projectLens,
  });
  final bool embedded;
  final Widget projectLens;
  @override
  Widget build(BuildContext context) =>
      FieldCalendarPage(embedded: embedded, projectLens: projectLens);
}

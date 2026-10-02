/// EN: Supplies the catalog project lens to live feature pages, so live
/// presentation never imports catalog presentation directly.
/// KO: live feature 화면에 catalog project lens를 공급하여 live presentation이
/// catalog presentation을 직접 import하지 않도록 합니다.
library;

import 'package:flutter/material.dart';

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

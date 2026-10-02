/// EN: Read-only provider adapters for the Field Guide presentation layer.
/// KO: Field Guide 프레젠테이션 계층을 위한 읽기 전용 프로바이더 어댑터.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'news_controller.dart';
import '../domain/entities/news_entities.dart';

/// EN: Updates exposed to the guide without duplicating repository state.
/// KO: 저장소 상태를 복제하지 않고 가이드에 노출하는 업데이트 목록입니다.
final fieldGuideUpdatesProvider =
    Provider.autoDispose<AsyncValue<List<NewsSummary>>>((ref) {
      return ref.watch(newsListControllerProvider);
    });

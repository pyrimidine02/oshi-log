/// EN: Bottom navigation (tab) state owned by the app shell.
/// KO: 앱 shell이 소유하는 하단 네비게이션(탭) 상태.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// EN: Current bottom navigation index.
/// KO: 현재 하단 네비게이션 인덱스.
final currentNavIndexProvider = StateProvider<int>((ref) {
  return 0;
});

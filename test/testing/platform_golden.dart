import 'dart:io';

/// EN: Keeps host font and rasterizer references separate without relaxing checks.
/// KO: 비교 기준을 완화하지 않고 호스트 폰트·래스터라이저 기준 이미지를 분리합니다.
String get platformGoldenDirectory =>
    Platform.isLinux ? 'goldens/linux' : 'goldens';

/// EN: Shared deterministic palette helpers for avatar/background accents.
/// KO: 아바타/배경 강조색에 사용하는 공통 결정적 팔레트 유틸.
library;

import 'package:flutter/material.dart';

/// EN: Shared avatar palette for unit/member surfaces.
/// KO: 유닛/멤버 표면에 사용하는 공통 아바타 팔레트.
const kAvatarPalette = <Color>[
  Color(0xFF6366F1),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF14B8A6),
];

/// EN: Returns a deterministic color for a given seed string.
/// KO: 주어진 시드 문자열에 대해 결정적인 색상을 반환합니다.
Color paletteColorFromSeed(String seed) {
  if (seed.isEmpty) {
    return kAvatarPalette.first;
  }
  return kAvatarPalette[seed.hashCode.abs() % kAvatarPalette.length];
}

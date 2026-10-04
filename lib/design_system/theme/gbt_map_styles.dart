/// EN: Shared Google Map styles that follow app theme mode.
/// KO: 앱 테마 모드를 따르는 공용 Google 지도 스타일입니다.
library;

import 'package:flutter/material.dart';

/// EN: Resolve Google Map style by app brightness.
/// KO: 앱 밝기 기준으로 Google 지도 스타일을 선택합니다.
String gbtGoogleMapStyleForBrightness(Brightness brightness) {
  return brightness == Brightness.dark
      ? gbtGoogleMapDarkStyle
      : gbtGoogleMapLightStyle;
}

/// EN: Resolve Google Map style by app dark-mode boolean.
/// KO: 앱 다크 모드 여부로 Google 지도 스타일을 선택합니다.
String gbtGoogleMapStyleForDarkMode(bool isDarkMode) {
  return isDarkMode ? gbtGoogleMapDarkStyle : gbtGoogleMapLightStyle;
}

/// EN: Overlay tint used to force Apple Map dark appearance in dark mode.
/// KO: 다크 모드에서 Apple 지도 다크 표현을 강제하는 오버레이 색상.
const Color gbtAppleMapDarkOverlayColor = Color(0x33000000);

/// EN: Overlay tint used to keep Apple Map in app-light appearance.
/// KO: Apple 지도를 앱 라이트 모드 톤으로 유지하기 위한 오버레이 색상.
const Color gbtAppleMapLightOverlayColor = Color(0x33FFFFFF);

/// EN: Resolve Apple Map overlay tint by app dark-mode boolean.
/// KO: 앱 다크 모드 여부로 Apple 지도 오버레이 색상을 선택합니다.
Color gbtAppleMapOverlayColorForDarkMode(bool isDarkMode) {
  return isDarkMode
      ? gbtAppleMapDarkOverlayColor
      : gbtAppleMapLightOverlayColor;
}

/// EN: Explicit light map style to avoid platform/system auto-theme mismatch.
/// KO: 플랫폼/시스템 자동 테마 불일치를 방지하기 위한 명시적 라이트 지도 스타일.
const String gbtGoogleMapLightStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f7f7f7"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5f6368"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#d9d9d9"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#efefef"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#dfeadf"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e5e5e5"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f1f1f1"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d9e7ff"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]}
]
''';

/// EN: Explicit dark map style.
/// KO: 명시적 다크 지도 스타일.
const String gbtGoogleMapDarkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1f1f1f"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1f1f1f"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2f2f2f"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#262626"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1e2b20"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2b2b2b"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1a1a1a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a3a3a"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1b2a"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]}
]
''';

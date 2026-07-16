/// EN: GBT theme configuration integrating colors, typography, and spacing
/// KO: 색상, 타이포그래피, 간격을 통합하는 GBT 테마 구성
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gbt_colors.dart';
import 'gbt_spacing.dart';
import 'gbt_typography.dart';

/// EN: Main theme class for the application
/// KO: 앱의 메인 테마 클래스
class GBTTheme {
  GBTTheme._();

  // ========================================
  // EN: Light Theme
  // KO: 라이트 테마
  // ========================================
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: _lightAppBarTheme,
      bottomNavigationBarTheme: _lightBottomNavTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      iconButtonTheme: _iconButtonTheme,
      listTileTheme: _listTileTheme,
      inputDecorationTheme: _inputDecorationTheme,
      progressIndicatorTheme: _progressIndicatorTheme,
      dividerTheme: _dividerTheme,
      chipTheme: _chipTheme,
      floatingActionButtonTheme: _fabTheme,
      bottomSheetTheme: _bottomSheetTheme,
      dialogTheme: _dialogTheme,
      popupMenuTheme: _popupMenuTheme,
      scrollbarTheme: _scrollbarTheme,
      tooltipTheme: _tooltipTheme,
      snackBarTheme: _snackBarTheme,
      switchTheme: _switchTheme,
      checkboxTheme: _checkboxTheme,
      radioTheme: _radioTheme,
      sliderTheme: _sliderTheme,
      segmentedButtonTheme: _segmentedButtonTheme,
      tabBarTheme: _tabBarTheme,
      scaffoldBackgroundColor: GBTColors.appBackground,
      splashColor: GBTColors.ripple,
      highlightColor: Colors.transparent,
    );
  }

  // ========================================
  // EN: Dark Theme
  // KO: 다크 테마
  // ========================================
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: _darkColorScheme,
      textTheme: _darkTextTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: _darkAppBarTheme,
      bottomNavigationBarTheme: _darkBottomNavTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _darkElevatedButtonTheme,
      filledButtonTheme: _darkFilledButtonTheme,
      outlinedButtonTheme: _darkOutlinedButtonTheme,
      textButtonTheme: _darkTextButtonTheme,
      iconButtonTheme: _darkIconButtonTheme,
      listTileTheme: _darkListTileTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      progressIndicatorTheme: _darkProgressIndicatorTheme,
      dividerTheme: _darkDividerTheme,
      chipTheme: _darkChipTheme,
      floatingActionButtonTheme: _darkFabTheme,
      bottomSheetTheme: _darkBottomSheetTheme,
      dialogTheme: _darkDialogTheme,
      popupMenuTheme: _darkPopupMenuTheme,
      scrollbarTheme: _darkScrollbarTheme,
      tooltipTheme: _darkTooltipTheme,
      snackBarTheme: _darkSnackBarTheme,
      switchTheme: _darkSwitchTheme,
      checkboxTheme: _darkCheckboxTheme,
      radioTheme: _darkRadioTheme,
      sliderTheme: _darkSliderTheme,
      segmentedButtonTheme: _darkSegmentedButtonTheme,
      tabBarTheme: _darkTabBarTheme,
      scaffoldBackgroundColor: GBTColors.darkAppBackground,
      splashColor: GBTColors.ripple,
      highlightColor: Colors.transparent,
    );
  }

  // ========================================
  // EN: Color Schemes
  // KO: 색상 스키마
  // ========================================
  static ColorScheme get _lightColorScheme => ColorScheme(
    brightness: Brightness.light,
    primary: GBTColors.primary,
    onPrimary: GBTColors.textInverse,
    primaryContainer: GBTColors.primaryLight,
    onPrimaryContainer: GBTColors.textPrimary,
    // EN: Harbor teal distinguishes places and travel metadata.
    // KO: 하버 틸로 장소와 여행 메타데이터를 구분합니다.
    secondary: GBTColors.secondary,
    onSecondary: GBTColors.textInverse,
    secondaryContainer: GBTColors.secondaryLight,
    onSecondaryContainer: GBTColors.textPrimary,
    tertiary: GBTColors.accent,
    onTertiary: GBTColors.textPrimary,
    error: GBTColors.error,
    onError: GBTColors.textInverse,
    surface: GBTColors.surface,
    onSurface: GBTColors.textPrimary,
    surfaceContainerHighest: GBTColors.surfaceVariant,
    onSurfaceVariant: GBTColors.textSecondary,
    outline: GBTColors.border,
    outlineVariant: GBTColors.divider,
    shadow: Colors.black,
    scrim: GBTColors.scrim,
  );

  static ColorScheme get _darkColorScheme => ColorScheme(
    brightness: Brightness.dark,
    primary: GBTColors.darkPrimary,
    onPrimary: GBTColors.darkBackground,
    primaryContainer: GBTColors.darkPrimaryContainer,
    onPrimaryContainer: GBTColors.darkTextPrimary,
    // EN: Night-travel teal remains distinct from the blue primary.
    // KO: 야간 여행 틸은 블루 기본색과 구분됩니다.
    secondary: GBTColors.darkSecondary,
    onSecondary: GBTColors.darkBackground,
    secondaryContainer: GBTColors.darkSurfaceElevated,
    onSecondaryContainer: GBTColors.darkTextPrimary,
    tertiary: GBTColors.darkAccent,
    onTertiary: GBTColors.darkBackground,
    error: GBTColors.error,
    onError: GBTColors.darkTextPrimary,
    surface: GBTColors.darkSurface,
    onSurface: GBTColors.darkTextPrimary,
    surfaceContainerHighest: GBTColors.darkSurfaceVariant,
    onSurfaceVariant: GBTColors.darkTextSecondary,
    outline: GBTColors.darkBorder,
    outlineVariant: GBTColors.darkBorderSubtle,
    shadow: Colors.black,
    scrim: GBTColors.scrim,
  );

  // ========================================
  // EN: Text Theme
  // KO: 텍스트 테마
  // ========================================
  static TextTheme get _textTheme => TextTheme(
    displayLarge: GBTTypography.displayLarge.copyWith(
      color: GBTColors.textPrimary,
    ),
    displayMedium: GBTTypography.displayMedium.copyWith(
      color: GBTColors.textPrimary,
    ),
    displaySmall: GBTTypography.displaySmall.copyWith(
      color: GBTColors.textPrimary,
    ),
    headlineLarge: GBTTypography.headlineLarge.copyWith(
      color: GBTColors.textPrimary,
    ),
    headlineMedium: GBTTypography.headlineMedium.copyWith(
      color: GBTColors.textPrimary,
    ),
    headlineSmall: GBTTypography.headlineSmall.copyWith(
      color: GBTColors.textPrimary,
    ),
    titleLarge: GBTTypography.titleLarge.copyWith(color: GBTColors.textPrimary),
    titleMedium: GBTTypography.titleMedium.copyWith(
      color: GBTColors.textPrimary,
    ),
    titleSmall: GBTTypography.titleSmall.copyWith(color: GBTColors.textPrimary),
    bodyLarge: GBTTypography.bodyLarge.copyWith(color: GBTColors.textPrimary),
    bodyMedium: GBTTypography.bodyMedium.copyWith(color: GBTColors.textPrimary),
    bodySmall: GBTTypography.bodySmall.copyWith(color: GBTColors.textSecondary),
    labelLarge: GBTTypography.labelLarge.copyWith(color: GBTColors.textPrimary),
    labelMedium: GBTTypography.labelMedium.copyWith(
      color: GBTColors.textSecondary,
    ),
    labelSmall: GBTTypography.labelSmall.copyWith(
      color: GBTColors.textTertiary,
    ),
  );

  static TextTheme get _darkTextTheme => TextTheme(
    displayLarge: GBTTypography.displayLarge.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    displayMedium: GBTTypography.displayMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    displaySmall: GBTTypography.displaySmall.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    headlineLarge: GBTTypography.headlineLarge.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    headlineMedium: GBTTypography.headlineMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    headlineSmall: GBTTypography.headlineSmall.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    titleLarge: GBTTypography.titleLarge.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    titleMedium: GBTTypography.titleMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    titleSmall: GBTTypography.titleSmall.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    bodyLarge: GBTTypography.bodyLarge.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    bodyMedium: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    bodySmall: GBTTypography.bodySmall.copyWith(
      color: GBTColors.darkTextSecondary,
    ),
    labelLarge: GBTTypography.labelLarge.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    labelMedium: GBTTypography.labelMedium.copyWith(
      color: GBTColors.darkTextSecondary,
    ),
    labelSmall: GBTTypography.labelSmall.copyWith(
      color: GBTColors.darkTextTertiary,
    ),
  );

  // ========================================
  // EN: AppBar Theme
  // KO: 앱바 테마
  // ========================================
  static AppBarTheme get _lightAppBarTheme => AppBarTheme(
    backgroundColor: GBTColors.appBackground,
    foregroundColor: GBTColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    toolbarHeight: GBTSpacing.appBarHeight,
    centerTitle: true,
    titleTextStyle: GBTTypography.titleMedium.copyWith(
      color: GBTColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: const IconThemeData(
      color: GBTColors.textPrimary,
      size: GBTSpacing.iconMd,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static AppBarTheme get _darkAppBarTheme => AppBarTheme(
    backgroundColor: GBTColors.darkAppBackground,
    foregroundColor: GBTColors.darkTextPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    toolbarHeight: GBTSpacing.appBarHeight,
    centerTitle: true,
    titleTextStyle: GBTTypography.titleMedium.copyWith(
      color: GBTColors.darkTextPrimary,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: const IconThemeData(
      color: GBTColors.darkTextPrimary,
      size: GBTSpacing.iconMd,
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  // ========================================
  // EN: Bottom Navigation Theme
  // KO: 하단 네비게이션 테마
  // ========================================
  static BottomNavigationBarThemeData get _lightBottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: GBTColors.surface,
        selectedItemColor: GBTColors.primary,
        unselectedItemColor: GBTColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GBTTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GBTTypography.labelSmall,
      );

  static BottomNavigationBarThemeData get _darkBottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: GBTColors.darkBackground,
        selectedItemColor: GBTColors.darkPrimary,
        unselectedItemColor: GBTColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GBTTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GBTTypography.labelSmall,
      );

  // ========================================
  // EN: Card Theme
  // KO: 카드 테마
  // ========================================
  static CardThemeData get _cardTheme => CardThemeData(
    color: GBTColors.surface,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
      side: BorderSide(color: GBTColors.border.withValues(alpha: 0.5)),
    ),
    margin: EdgeInsets.zero,
  );

  static CardThemeData get _darkCardTheme => CardThemeData(
    color: GBTColors.darkSurfaceVariant,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
      side: const BorderSide(color: GBTColors.darkBorderSubtle, width: 0.5),
    ),
    margin: EdgeInsets.zero,
  );

  // ========================================
  // EN: Button Themes
  // KO: 버튼 테마
  // ========================================
  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GBTColors.primary,
          foregroundColor: GBTColors.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.lg,
            vertical: GBTSpacing.md,
          ),
          minimumSize: const Size(120, GBTSpacing.touchTarget),
          shape: const StadiumBorder(),
          textStyle: GBTTypography.button,
        ),
      );

  static ElevatedButtonThemeData get _darkElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GBTColors.darkPrimary,
          foregroundColor: GBTColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.lg,
            vertical: GBTSpacing.md,
          ),
          minimumSize: const Size(120, GBTSpacing.touchTarget),
          shape: const StadiumBorder(),
          textStyle: GBTTypography.button,
        ),
      );

  static FilledButtonThemeData get _filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: GBTColors.primary,
      foregroundColor: GBTColors.textInverse,
      minimumSize: const Size(120, GBTSpacing.touchTarget),
      shape: const StadiumBorder(),
      textStyle: GBTTypography.button,
    ),
  );

  static FilledButtonThemeData get _darkFilledButtonTheme =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GBTColors.darkPrimary,
          foregroundColor: GBTColors.darkBackground,
          minimumSize: const Size(120, GBTSpacing.touchTarget),
          shape: const StadiumBorder(),
          textStyle: GBTTypography.button,
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GBTColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.lg,
            vertical: GBTSpacing.md,
          ),
          minimumSize: const Size(120, GBTSpacing.touchTarget),
          shape: const StadiumBorder(),
          side: const BorderSide(color: GBTColors.border),
          textStyle: GBTTypography.button,
        ),
      );

  static OutlinedButtonThemeData get _darkOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GBTColors.darkPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.lg,
            vertical: GBTSpacing.md,
          ),
          minimumSize: const Size(120, GBTSpacing.touchTarget),
          shape: const StadiumBorder(),
          side: const BorderSide(color: GBTColors.darkBorder),
          textStyle: GBTTypography.button,
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: GBTColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.sm,
      ),
      minimumSize: const Size(64, GBTSpacing.minTouchTarget),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      textStyle: GBTTypography.button,
    ),
  );

  static TextButtonThemeData get _darkTextButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: GBTColors.darkPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.sm,
      ),
      minimumSize: const Size(64, GBTSpacing.minTouchTarget),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      textStyle: GBTTypography.button,
    ),
  );

  static IconButtonThemeData get _iconButtonTheme => IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(
        GBTSpacing.minTouchTarget,
        GBTSpacing.minTouchTarget,
      ),
      padding: const EdgeInsets.all(GBTSpacing.sm),
      foregroundColor: GBTColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
    ),
  );

  static IconButtonThemeData get _darkIconButtonTheme => IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(
        GBTSpacing.minTouchTarget,
        GBTSpacing.minTouchTarget,
      ),
      padding: const EdgeInsets.all(GBTSpacing.sm),
      foregroundColor: GBTColors.darkTextPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
    ),
  );

  // ========================================
  // EN: Input Decoration Theme
  // KO: 입력 데코레이션 테마
  // ========================================
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: GBTColors.surfaceVariant,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: GBTSpacing.md,
      vertical: GBTSpacing.md2,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      borderSide: const BorderSide(color: GBTColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      borderSide: const BorderSide(color: GBTColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      borderSide: const BorderSide(color: GBTColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      borderSide: const BorderSide(color: GBTColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      borderSide: const BorderSide(color: GBTColors.error, width: 2),
    ),
    hintStyle: GBTTypography.bodyMedium.copyWith(color: GBTColors.textTertiary),
    labelStyle: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.textSecondary,
    ),
    errorStyle: GBTTypography.bodySmall.copyWith(color: GBTColors.error),
  );

  static InputDecorationTheme get _darkInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: GBTColors.darkSurfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.md2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          borderSide: const BorderSide(color: GBTColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          borderSide: const BorderSide(color: GBTColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          borderSide: const BorderSide(color: GBTColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          borderSide: const BorderSide(color: GBTColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          borderSide: const BorderSide(color: GBTColors.error, width: 2),
        ),
        hintStyle: GBTTypography.bodyMedium.copyWith(
          color: GBTColors.darkTextTertiary,
        ),
        labelStyle: GBTTypography.bodyMedium.copyWith(
          color: GBTColors.darkTextSecondary,
        ),
        errorStyle: GBTTypography.bodySmall.copyWith(color: GBTColors.error),
      );

  // ========================================
  // EN: List & Progress Theme
  // KO: 리스트 및 진행 상태 테마
  // ========================================
  static ListTileThemeData get _listTileTheme => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: GBTSpacing.md,
      vertical: GBTSpacing.xs,
    ),
    minLeadingWidth: GBTSpacing.lg,
    horizontalTitleGap: GBTSpacing.sm,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
    ),
    iconColor: GBTColors.textSecondary,
    textColor: GBTColors.textPrimary,
  );

  static ListTileThemeData get _darkListTileTheme => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: GBTSpacing.md,
      vertical: GBTSpacing.xs,
    ),
    minLeadingWidth: GBTSpacing.lg,
    horizontalTitleGap: GBTSpacing.sm,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
    ),
    iconColor: GBTColors.darkTextSecondary,
    textColor: GBTColors.darkTextPrimary,
  );

  static ProgressIndicatorThemeData get _progressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: GBTColors.primary,
        circularTrackColor: GBTColors.surfaceVariant,
      );

  static ProgressIndicatorThemeData get _darkProgressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: GBTColors.darkPrimary,
        circularTrackColor: GBTColors.darkSurfaceVariant,
      );

  // ========================================
  // EN: Divider Theme
  // KO: 구분선 테마
  // ========================================
  static DividerThemeData get _dividerTheme =>
      const DividerThemeData(color: GBTColors.divider, thickness: 1, space: 1);

  static DividerThemeData get _darkDividerTheme => const DividerThemeData(
    color: GBTColors.darkBorder,
    thickness: 1,
    space: 1,
  );

  // ========================================
  // EN: Chip Theme
  // KO: 칩 테마
  // ========================================
  static ChipThemeData get _chipTheme => ChipThemeData(
    backgroundColor: GBTColors.surfaceVariant,
    selectedColor: GBTColors.primaryLight,
    labelStyle: GBTTypography.labelMedium.copyWith(
      color: GBTColors.textSecondary,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: GBTSpacing.sm,
      vertical: GBTSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
    ),
  );

  static ChipThemeData get _darkChipTheme => ChipThemeData(
    backgroundColor: GBTColors.darkSurfaceVariant,
    selectedColor: GBTColors.darkSurfaceElevated,
    labelStyle: GBTTypography.labelMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: GBTSpacing.sm,
      vertical: GBTSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
    ),
  );

  // ========================================
  // EN: FAB Theme
  // KO: FAB 테마
  // ========================================
  static FloatingActionButtonThemeData get _fabTheme =>
      FloatingActionButtonThemeData(
        backgroundColor: GBTColors.primary,
        foregroundColor: GBTColors.textInverse,
        elevation: GBTSpacing.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        ),
      );

  static FloatingActionButtonThemeData get _darkFabTheme =>
      FloatingActionButtonThemeData(
        backgroundColor: GBTColors.darkPrimary,
        foregroundColor: GBTColors.darkBackground,
        elevation: GBTSpacing.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        ),
      );

  // ========================================
  // EN: Bottom Sheet Theme
  // KO: 바텀 시트 테마
  // ========================================
  static BottomSheetThemeData get _bottomSheetTheme => BottomSheetThemeData(
    backgroundColor: GBTColors.surface,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: GBTColors.textTertiary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GBTSpacing.radiusXl),
      ),
    ),
    elevation: GBTSpacing.elevationLg,
  );

  static BottomSheetThemeData get _darkBottomSheetTheme => BottomSheetThemeData(
    backgroundColor: GBTColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: GBTColors.darkTextTertiary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GBTSpacing.radiusXl),
      ),
    ),
    elevation: GBTSpacing.elevationLg,
  );

  // ========================================
  // EN: Dialog Theme
  // KO: 다이얼로그 테마
  // ========================================
  static DialogThemeData get _dialogTheme => DialogThemeData(
    backgroundColor: GBTColors.surface,
    elevation: GBTSpacing.elevationXl,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
    ),
    titleTextStyle: GBTTypography.titleLarge.copyWith(
      color: GBTColors.textPrimary,
    ),
    contentTextStyle: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.textSecondary,
    ),
  );

  static DialogThemeData get _darkDialogTheme => DialogThemeData(
    backgroundColor: GBTColors.darkSurfaceVariant,
    elevation: GBTSpacing.elevationXl,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
    ),
    titleTextStyle: GBTTypography.titleLarge.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    contentTextStyle: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.darkTextSecondary,
    ),
  );

  // ========================================
  // EN: SnackBar Theme
  // KO: 스낵바 테마
  // ========================================
  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
    backgroundColor: GBTColors.textPrimary,
    contentTextStyle: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.textInverse,
    ),
    behavior: SnackBarBehavior.floating,
    insetPadding: const EdgeInsets.fromLTRB(
      GBTSpacing.md,
      GBTSpacing.sm,
      GBTSpacing.md,
      GBTSpacing.md,
    ),
    actionTextColor: GBTColors.primaryLight,
    disabledActionTextColor: GBTColors.textDisabled,
    showCloseIcon: true,
    closeIconColor: GBTColors.textInverse,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
    ),
  );

  static SnackBarThemeData get _darkSnackBarTheme => SnackBarThemeData(
    backgroundColor: GBTColors.darkSurfaceElevated,
    contentTextStyle: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    behavior: SnackBarBehavior.floating,
    insetPadding: const EdgeInsets.fromLTRB(
      GBTSpacing.md,
      GBTSpacing.sm,
      GBTSpacing.md,
      GBTSpacing.md,
    ),
    actionTextColor: GBTColors.darkPrimary,
    disabledActionTextColor: GBTColors.darkTextTertiary,
    showCloseIcon: true,
    closeIconColor: GBTColors.darkTextPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
    ),
  );

  // ========================================
  // EN: Menus, Tooltips, Scrollbars
  // KO: 메뉴, 툴팁, 스크롤바
  // ========================================
  static PopupMenuThemeData get _popupMenuTheme => PopupMenuThemeData(
    color: GBTColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      side: const BorderSide(color: GBTColors.border),
    ),
    textStyle: GBTTypography.bodyMedium.copyWith(color: GBTColors.textPrimary),
  );

  static PopupMenuThemeData get _darkPopupMenuTheme => PopupMenuThemeData(
    color: GBTColors.darkSurfaceVariant,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      side: const BorderSide(color: GBTColors.darkBorder),
    ),
    textStyle: GBTTypography.bodyMedium.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
  );

  static ScrollbarThemeData get _scrollbarTheme => ScrollbarThemeData(
    radius: const Radius.circular(GBTSpacing.radiusFull),
    thickness: const WidgetStatePropertyAll<double>(6),
    thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.dragged)) {
        return GBTColors.textSecondary;
      }
      return GBTColors.textTertiary.withValues(alpha: 0.6);
    }),
    trackColor: WidgetStatePropertyAll(
      GBTColors.surfaceVariant.withValues(alpha: 0.4),
    ),
  );

  static ScrollbarThemeData get _darkScrollbarTheme => ScrollbarThemeData(
    radius: const Radius.circular(GBTSpacing.radiusFull),
    thickness: const WidgetStatePropertyAll<double>(6),
    thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.dragged)) {
        return GBTColors.darkTextSecondary;
      }
      return GBTColors.darkTextTertiary.withValues(alpha: 0.75);
    }),
    trackColor: WidgetStatePropertyAll(
      GBTColors.darkSurfaceVariant.withValues(alpha: 0.45),
    ),
  );

  static TooltipThemeData get _tooltipTheme => TooltipThemeData(
    decoration: BoxDecoration(
      color: GBTColors.textPrimary,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
    ),
    textStyle: GBTTypography.bodySmall.copyWith(color: GBTColors.textInverse),
    waitDuration: const Duration(milliseconds: 450),
    preferBelow: false,
  );

  static TooltipThemeData get _darkTooltipTheme => TooltipThemeData(
    decoration: BoxDecoration(
      color: GBTColors.darkSurfaceElevated,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
    ),
    textStyle: GBTTypography.bodySmall.copyWith(
      color: GBTColors.darkTextPrimary,
    ),
    waitDuration: const Duration(milliseconds: 450),
    preferBelow: false,
  );

  // ========================================
  // EN: Selection Controls
  // KO: 선택 컨트롤
  // ========================================
  static SwitchThemeData get _switchTheme => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.primary;
      }
      return GBTColors.surface;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.primary.withValues(alpha: 0.45);
      }
      return GBTColors.surfaceAlternate;
    }),
  );

  static SwitchThemeData get _darkSwitchTheme => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.darkPrimary;
      }
      return GBTColors.darkTextTertiary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.darkPrimary.withValues(alpha: 0.45);
      }
      return GBTColors.darkSurfaceElevated;
    }),
  );

  static CheckboxThemeData get _checkboxTheme => CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
    ),
    side: const BorderSide(color: GBTColors.border, width: 1.4),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.primary;
      }
      return GBTColors.surface;
    }),
    checkColor: const WidgetStatePropertyAll(GBTColors.textInverse),
  );

  static CheckboxThemeData get _darkCheckboxTheme => CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
    ),
    side: const BorderSide(color: GBTColors.darkBorder, width: 1.4),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.darkPrimary;
      }
      return GBTColors.darkSurface;
    }),
    checkColor: const WidgetStatePropertyAll(GBTColors.darkBackground),
  );

  static RadioThemeData get _radioTheme => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.primary;
      }
      return GBTColors.textTertiary;
    }),
  );

  static RadioThemeData get _darkRadioTheme => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GBTColors.darkPrimary;
      }
      return GBTColors.darkTextTertiary;
    }),
  );

  static SliderThemeData get _sliderTheme => SliderThemeData(
    activeTrackColor: GBTColors.primary,
    inactiveTrackColor: GBTColors.primaryMuted,
    thumbColor: GBTColors.primary,
    overlayColor: GBTColors.primary.withValues(alpha: 0.16),
    trackHeight: 4,
    valueIndicatorColor: GBTColors.primary,
    valueIndicatorTextStyle: GBTTypography.labelSmall.copyWith(
      color: GBTColors.textInverse,
    ),
  );

  static SliderThemeData get _darkSliderTheme => SliderThemeData(
    activeTrackColor: GBTColors.darkPrimary,
    inactiveTrackColor: GBTColors.darkSurfaceElevated,
    thumbColor: GBTColors.darkPrimary,
    overlayColor: GBTColors.darkPrimary.withValues(alpha: 0.2),
    trackHeight: 4,
    valueIndicatorColor: GBTColors.darkPrimary,
    valueIndicatorTextStyle: GBTTypography.labelSmall.copyWith(
      color: GBTColors.darkBackground,
    ),
  );

  static SegmentedButtonThemeData get _segmentedButtonTheme =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(GBTTypography.labelMedium),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            ),
          ),
        ),
      );

  static SegmentedButtonThemeData get _darkSegmentedButtonTheme =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(GBTTypography.labelMedium),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            ),
          ),
        ),
      );

  // ========================================
  // EN: Navigation Transitions
  // KO: 화면 전환
  // ========================================
  static PageTransitionsTheme get _pageTransitionsTheme =>
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      );

  // ========================================
  // EN: TabBar Theme
  // KO: 탭바 테마
  // ========================================
  static TabBarThemeData get _tabBarTheme => TabBarThemeData(
    labelColor: GBTColors.primary,
    unselectedLabelColor: GBTColors.textTertiary,
    labelStyle: GBTTypography.tabLabel,
    unselectedLabelStyle: GBTTypography.tabLabel,
    indicatorColor: GBTColors.primary,
    indicatorSize: TabBarIndicatorSize.label,
  );

  static TabBarThemeData get _darkTabBarTheme => TabBarThemeData(
    labelColor: GBTColors.darkPrimary,
    unselectedLabelColor: GBTColors.darkTextTertiary,
    labelStyle: GBTTypography.tabLabel,
    unselectedLabelStyle: GBTTypography.tabLabel,
    indicatorColor: GBTColors.darkPrimary,
    indicatorSize: TabBarIndicatorSize.label,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';

void main() {
  group('Urban Travel Field Notes palette', () {
    test('secondary reading text meets AA on every quiet surface', () {
      for (final background in [
        GBTColors.background,
        GBTColors.surface,
        GBTColors.surfaceVariant,
      ]) {
        expect(
          GBTColorValidator.calculateContrastRatio(
            GBTColors.textTertiary,
            background,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test(
      'Material surface levels belong to the same light and dark palette',
      () {
        for (final theme in [GBTTheme.light, GBTTheme.dark]) {
          final colors = theme.colorScheme;
          final levels = [
            colors.surfaceContainerLowest,
            colors.surfaceContainerLow,
            colors.surfaceContainer,
            colors.surfaceContainerHigh,
            colors.surfaceContainerHighest,
          ];
          expect(levels.toSet().length, greaterThan(2));
          for (final surface in levels) {
            expect(
              GBTColorValidator.hasValidContrast(colors.onSurface, surface),
              isTrue,
            );
          }
        }
      },
    );

    test('exposes the editorial paper, ink, brand blue, and teal anchors', () {
      expect(GBTColors.fieldPaper, const Color(0xFFF7F8FA));
      expect(GBTColors.fieldInk, const Color(0xFF17202A));
      expect(GBTColors.fieldBlue, const Color(0xFF0A66C2));
      expect(GBTColors.fieldTeal, const Color(0xFF2B7773));
      expect(GBTColors.primary, GBTColors.fieldBlue);
      expect(GBTColors.darkPrimary, const Color(0xFF8AB4FF));
      expect(GBTColors.darkPrimaryContainer, const Color(0xFF173A67));
    });

    test('keeps essential foreground and background pairs accessible', () {
      expect(
        GBTColorValidator.hasValidContrast(
          GBTColors.textInverse,
          GBTColors.primary,
        ),
        isTrue,
      );
      expect(
        GBTColorValidator.hasValidContrast(
          GBTColors.textPrimary,
          GBTColors.background,
        ),
        isTrue,
      );
      expect(
        GBTColorValidator.hasValidContrast(
          GBTColors.darkPrimary,
          GBTColors.darkBackground,
        ),
        isTrue,
      );
    });

    test('selects the higher-contrast icon color for bright accents', () {
      expect(
        GBTColorValidator.getContrastingTextColor(GBTColors.accent),
        GBTColors.textPrimary,
      );
      expect(
        GBTColorValidator.getContrastingTextColor(GBTColors.primary),
        GBTColors.textInverse,
      );
    });
  });

  group('route-wide chrome', () {
    test('native text and icon actions keep a 48dp target in both themes', () {
      for (final theme in [GBTTheme.light, GBTTheme.dark]) {
        for (final style in [
          theme.textButtonTheme.style!,
          theme.iconButtonTheme.style!,
        ]) {
          final size = style.minimumSize!.resolve({})!;
          expect(size.height, greaterThanOrEqualTo(48));
          expect(size.width, greaterThanOrEqualTo(48));
        }
      }
    });
    test('local selections keep legible labels in both themes', () {
      for (final theme in [GBTTheme.light, GBTTheme.dark]) {
        final style = theme.segmentedButtonTheme.style!;
        for (final selected in [false, true]) {
          final states = <WidgetState>{if (selected) WidgetState.selected};
          expect(
            GBTColorValidator.hasValidContrast(
              style.foregroundColor!.resolve(states)!,
              style.backgroundColor!.resolve(states)!,
            ),
            isTrue,
          );
        }
        expect(
          style.foregroundColor!.resolve({WidgetState.disabled}),
          isNotNull,
        );
      }
    });

    test('keeps raw app bars flat on the paper canvas', () {
      expect(
        GBTTheme.light.appBarTheme.backgroundColor,
        GBTColors.appBackground,
      );
      expect(GBTTheme.light.appBarTheme.elevation, 0);
      expect(GBTTheme.light.appBarTheme.scrolledUnderElevation, 0);
      expect(
        GBTTheme.dark.appBarTheme.backgroundColor,
        GBTColors.darkAppBackground,
      );
      expect(GBTTheme.dark.appBarTheme.scrolledUnderElevation, 0);
    });
  });
}

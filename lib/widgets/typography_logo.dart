import 'package:flutter/material.dart';

enum LogoVariant {
  driver,
  cargo,
  corporate,
}

enum LogoThemeMode {
  light,
  dark,
}

enum LogoStyle {
  velocity,
  architectural,
  clean,
}

enum LogoSize {
  small,
  medium,
  large,
  extraLarge,
}

/// A high-aesthetic, pure typography logo widget (100% icon-free).
/// Designed for PT Lautan Indah Express / LIE Driver & Cargo apps.
class TypographyLogo extends StatelessWidget {
  final LogoVariant variant;
  final LogoThemeMode themeMode;
  final LogoStyle style;
  final LogoSize size;
  final bool showSubtitle;
  final String? customSubtitle;
  final CrossAxisAlignment crossAxisAlignment;

  const TypographyLogo({
    super.key,
    this.variant = LogoVariant.driver,
    this.themeMode = LogoThemeMode.light,
    this.style = LogoStyle.velocity,
    this.size = LogoSize.medium,
    this.showSubtitle = true,
    this.customSubtitle,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == LogoThemeMode.dark;

    // Sizing scale
    final double fontSizeLie;
    final double fontSizeWord;
    final double fontSizeSlash;
    final double fontSizeSub;
    final double subSpacing;
    final double topMarginSub;

    switch (size) {
      case LogoSize.small:
        fontSizeLie = 20;
        fontSizeWord = 17;
        fontSizeSlash = 15;
        fontSizeSub = 8.5;
        subSpacing = 2.0;
        topMarginSub = 2;
        break;
      case LogoSize.medium:
        fontSizeLie = 26;
        fontSizeWord = 22;
        fontSizeSlash = 19;
        fontSizeSub = 10;
        subSpacing = 2.4;
        topMarginSub = 3;
        break;
      case LogoSize.large:
        fontSizeLie = 36;
        fontSizeWord = 30;
        fontSizeSlash = 26;
        fontSizeSub = 11;
        subSpacing = 2.8;
        topMarginSub = 5;
        break;
      case LogoSize.extraLarge:
        fontSizeLie = 46;
        fontSizeWord = 38;
        fontSizeSlash = 32;
        fontSizeSub = 12.5;
        subSpacing = 3.2;
        topMarginSub = 7;
        break;
    }

    // Secondary text
    final String secondaryWord = switch (variant) {
      LogoVariant.driver => 'DRIVER',
      LogoVariant.cargo => 'CARGO',
      LogoVariant.corporate => 'LOGISTICS',
    };

    // Subtitle text
    final String resolvedSubtitle = customSubtitle ??
        switch (variant) {
          LogoVariant.driver => 'APLIKASI TUGAS PENGEMUDI',
          LogoVariant.cargo => 'PT LAUTAN INDAH EXPRESS',
          LogoVariant.corporate => 'PT LAUTAN INDAH EXPRESS',
        };

    // Color tokens
    final Color wordColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color slashColor = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
        : const Color(0xFF0284C7).withValues(alpha: 0.5);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final Gradient gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (style == LogoStyle.velocity)
          // Velocity Style: Dynamic italics with brand gradient and forward slash
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  'LIE',
                  style: TextStyle(
                    fontSize: fontSizeLie,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.0,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '//',
                style: TextStyle(
                  fontSize: fontSizeSlash,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: slashColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                secondaryWord,
                style: TextStyle(
                  fontSize: fontSizeWord,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                  color: wordColor,
                  height: 1.0,
                ),
              ),
            ],
          )
        else if (style == LogoStyle.architectural)
          // Architectural Style: Clean geometric letterforms with vertical divider
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'LIE',
                style: TextStyle(
                  fontSize: fontSizeLie,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0284C7),
                  height: 1.0,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 2,
                height: fontSizeWord * 0.9,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Text(
                secondaryWord,
                style: TextStyle(
                  fontSize: fontSizeWord,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: wordColor,
                  height: 1.0,
                ),
              ),
            ],
          )
        else
          // Clean Minimal Wordmark
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'LIE',
                style: TextStyle(
                  fontSize: fontSizeLie,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0284C7),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                secondaryWord,
                style: TextStyle(
                  fontSize: fontSizeWord,
                  fontWeight: FontWeight.bold,
                  color: wordColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        if (showSubtitle) ...[
          SizedBox(height: topMarginSub),
          Text(
            resolvedSubtitle,
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: TextStyle(
              fontSize: fontSizeSub,
              fontWeight: FontWeight.w700,
              letterSpacing: subSpacing,
              color: subColor,
            ),
          ),
        ],
      ],
    );
  }
}

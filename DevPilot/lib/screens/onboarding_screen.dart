import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/phosphor_icon.dart';

/// Data model representing a slide in the Onboarding flow.
class OnboardingSlide {
  final String tag;
  final String title;
  final String description;
  final String icon;
  final Color accentColor;
  final String chipText;
  final String watermarkIcon;

  const OnboardingSlide({
    required this.tag,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.chipText,
    required this.watermarkIcon,
  });
}

/// Developer-first Onboarding screen matching Monochrome Editorial + Light Theme.
/// Features a 3-step dimensional blueprint carousel, interactive indicators,
/// skip action, and instant transition to Auth or Main app.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onNavigateToLogin;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
    required this.onNavigateToLogin,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      tag: 'AUTONOMOUS SWARM',
      title: 'Multi-Agent Mission Control',
      description:
          'Deploy specialized AI agents that navigate codebases, trace AST graphs, run test suites, and draft pull requests autonomously.',
      icon: 'sparkle',
      accentColor: T.accent,
      chipText: r'$ graphify . --code-only',
      watermarkIcon: 'sparkle',
    ),
    OnboardingSlide(
      tag: 'REAL-TIME TELEMETRY',
      title: 'Sub-Millisecond Vitals & Sandboxes',
      description:
          'Monitor hardware loads, memory footprints, and isolated container sandboxes with real-time WebSocket telemetry.',
      icon: 'gauge',
      accentColor: T.accentTeal,
      chipText: 'DOCKER ISOLATION • SANDBOX ACTIVE',
      watermarkIcon: 'cpu',
    ),
    OnboardingSlide(
      tag: 'HUMAN-IN-THE-LOOP',
      title: 'Precision Verification Gates',
      description:
          'Every destructive shell command or major code commit requires your direct sign-off. Review line-by-line diffs with confidence.',
      icon: 'shield-check',
      accentColor: T.accentPurple,
      chipText: 'BIOMETRIC SIGN-OFF • 0 ACCIDENTS',
      watermarkIcon: 'git-diff',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Brand Kicker & Skip Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: T.surface,
                          borderRadius: T.rSm,
                          border: Border.all(color: T.border, width: 1),
                        ),
                        child: const PhosphorIcon(
                          'rocket-launch',
                          size: 16,
                          color: T.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DEVPILOT',
                        style: T.labelUpSm.copyWith(
                          color: T.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: T.surfaceMuted,
                          borderRadius: T.badgeCircle,
                          border: Border.all(color: T.border, width: 0.8),
                        ),
                        child: Text(
                          'v2.4',
                          style: T.labelUpXs.copyWith(
                            fontSize: 9,
                            color: T.onSurfaceVar,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onNavigateToLogin();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'SKIP',
                      style: T.labelUpSm.copyWith(
                        color: T.onSurfaceVar,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dimensional Blueprint Card
                        _buildBlueprintCard(slide),
                        const SizedBox(height: 32),

                        // Tag Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.08),
                            borderRadius: T.badgeCircle,
                            border: Border.all(
                              color: slide.accentColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: slide.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                slide.tag,
                                style: T.labelUpXs.copyWith(
                                  color: slide.accentColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          slide.title,
                          style: T.displaySm.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: T.onSurface,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            slide.description,
                            style: T.bodyMd.copyWith(
                              color: T.onSurfaceVar,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Actions Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? currentSlide.accentColor : T.borderStrong,
                          borderRadius: T.badgeCircle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Primary Button (Continue or Get Started)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: T.primary,
                        foregroundColor: T.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: T.rMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1 ? 'GET STARTED' : 'CONTINUE',
                            style: T.labelUpSm.copyWith(
                              color: T.onPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PhosphorIcon(
                            _currentPage == _slides.length - 1 ? 'rocket-launch' : 'arrow-right',
                            size: 18,
                            color: T.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Action (Sign In link)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onNavigateToLogin();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already registered? ',
                            style: T.bodySm.copyWith(color: T.onSurfaceMuted),
                          ),
                          Text(
                            'Sign In',
                            style: T.bodySm.copyWith(
                              color: T.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a dimensional blueprint diagram container per slide.
  Widget _buildBlueprintCard(OnboardingSlide slide) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.rLg,
        border: Border.all(color: T.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Phosphor Background Watermark
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.04,
              child: PhosphorIcon(
                slide.watermarkIcon,
                size: 160,
                color: slide.accentColor,
              ),
            ),
          ),

          // Blueprint Graphic Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row with status badge and icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: slide.accentColor.withValues(alpha: 0.1),
                        borderRadius: T.rMd,
                        border: Border.all(
                          color: slide.accentColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          slide.icon,
                          size: 24,
                          color: slide.accentColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: T.surfaceMuted,
                        borderRadius: T.rSm,
                        border: Border.all(color: T.border, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: T.onSurfaceVar),
                          const SizedBox(width: 4),
                          Text(
                            'SECURE ENGINE',
                            style: T.labelUpXs.copyWith(
                              fontSize: 9,
                              color: T.onSurfaceVar,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Center visual depending on slide index
                _buildSlideVisual(_currentPage),

                // Bottom Monospace Interactive Chip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: T.surfaceMuted,
                    borderRadius: T.rSm,
                    border: Border.all(color: T.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        'terminal-window',
                        size: 14,
                        color: slide.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slide.chipText,
                          style: T.mono(11, color: T.onSurfaceVar),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideVisual(int index) {
    if (index == 0) {
      // Node Graph representation for Multi-Agent
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNodeItem('Plan', 'sparkle', T.accent),
          Container(width: 20, height: 1, color: T.borderStrong),
          _buildNodeItem('Execute', 'cpu', T.accentTeal),
          Container(width: 20, height: 1, color: T.borderStrong),
          _buildNodeItem('Verify', 'shield-check', T.accentPurple),
        ],
      );
    } else if (index == 1) {
      // Telemetry gauges preview
      return Row(
        children: [
          Expanded(child: _buildGaugeItem('CPU LOAD', '18.4%', 0.18, T.accentTeal)),
          const SizedBox(width: 12),
          Expanded(child: _buildGaugeItem('RAM USE', '2.4 GB', 0.45, T.accent)),
          const SizedBox(width: 12),
          Expanded(child: _buildGaugeItem('LATENCY', '14 ms', 0.14, T.success)),
        ],
      );
    } else {
      // Diff Gate preview
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: T.background,
          borderRadius: T.rSm,
          border: Border.all(color: T.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PhosphorIcon('git-diff', size: 12, color: T.accentPurple),
                const SizedBox(width: 6),
                Text(
                  'PATCH REVIEW #108 • 2 FILES',
                  style: T.labelUpXs.copyWith(fontSize: 9, color: T.onSurfaceVar),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '+ verifySafetyChecks(policy: STRICT);',
              style: T.mono(10, color: T.success),
            ),
            Text(
              '- executeUnverifiedScript();',
              style: T.mono(10, color: T.destructive),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNodeItem(String title, String icon, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Center(
            child: PhosphorIcon(icon, size: 16, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: T.labelUpXs.copyWith(
            fontSize: 9,
            color: T.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGaugeItem(String label, String value, double percent, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: T.background,
        borderRadius: T.rSm,
        border: Border.all(color: T.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.labelUpXs.copyWith(fontSize: 8, color: T.onSurfaceMuted)),
          const SizedBox(height: 2),
          Text(value, style: T.numeralSm.copyWith(fontSize: 12, color: T.onSurface)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 2.5,
              backgroundColor: T.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

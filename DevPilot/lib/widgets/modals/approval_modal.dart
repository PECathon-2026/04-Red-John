import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Interactive Biometric Approval Gate for AMBER security events.
///
/// Simulates biometric Face ID / Fingerprint verification before executing
/// high-privilege or destructive developer operations (e.g. Kill All, Drop DB).
class ApprovalModal extends StatefulWidget {
  final String actionTitle;
  final String details;
  final VoidCallback onApprove;
  final VoidCallback onDeny;
  final String riskLevel;

  const ApprovalModal({
    super.key,
    required this.actionTitle,
    required this.details,
    required this.onApprove,
    required this.onDeny,
    this.riskLevel = 'AMBER',
  });

  /// Static helper to display the modal as a centered alert dialog.
  static Future<bool?> show(
    BuildContext context, {
    required String actionTitle,
    required String details,
    String riskLevel = 'AMBER',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ApprovalModal(
          actionTitle: actionTitle,
          details: details,
          riskLevel: riskLevel,
          onApprove: () {
            Navigator.of(ctx).pop(true);
          },
          onDeny: () {
            Navigator.of(ctx).pop(false);
          },
        ),
      ),
    );
  }

  @override
  State<ApprovalModal> createState() => _ApprovalModalState();
}

class _ApprovalModalState extends State<ApprovalModal> {
  double _dragExtent = 0.0;
  static const double _maxDrag = 160.0;

  void _handleApprove() {
    HapticFeedback.heavyImpact();
    widget.onApprove();
  }

  void _handleDeny() {
    HapticFeedback.mediumImpact();
    widget.onDeny();
  }

  Color get _badgeColor {
    switch (widget.riskLevel.toUpperCase()) {
      case 'CRITICAL':
      case 'RED':
        return AppTheme.statusRed;
      case 'AMBER':
      default:
        return AppTheme.statusAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.floatingShadow,
        border: Border.all(
          color: _badgeColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppTheme.cardRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AMBER warning top accent strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _badgeColor.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _badgeColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SECURITY CLEARANCE GATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _badgeColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.riskLevel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Biometric Scanner Visual Simulation
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _badgeColor.withValues(alpha: 0.12),
                      border: Border.all(
                        color: _badgeColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _badgeColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fingerprint,
                        size: 42,
                        color: _badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Title
                  Text(
                    widget.actionTitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.displayMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Risk details description
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgWarm.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      widget.details,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tactile Slide or Tap Approval Track
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleApprove,
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragExtent = (_dragExtent + details.delta.dx).clamp(
                          0.0,
                          _maxDrag,
                        );
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragExtent >= _maxDrag * 0.75) {
                        _handleApprove();
                      }
                      setState(() => _dragExtent = 0.0);
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.darkPill,
                        borderRadius: AppTheme.pillRadius,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Slide or tap to authenticate',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Positioned(
                            left: _dragExtent,
                            top: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeColor,
                                borderRadius: AppTheme.pillRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: _badgeColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Approve Action',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Deny action button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _handleDeny,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.borderMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.pillRadius,
                        ),
                      ),
                      child: const Text(
                        'Deny',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
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
}

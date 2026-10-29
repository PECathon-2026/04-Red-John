import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/telemetry_service.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet for inspecting the mission's unified git diff patch and requesting apply.
///
/// Features syntax-colored diff line highlights and one-tap AMBER apply initiation.
class PatchReviewModal extends StatefulWidget {
  final TelemetryService service;
  final VoidCallback? onClose;

  const PatchReviewModal({
    super.key,
    required this.service,
    this.onClose,
  });

  static Future<void> show(BuildContext context, TelemetryService service) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PatchReviewModal(
          service: service,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<PatchReviewModal> createState() => _PatchReviewModalState();
}

class _PatchReviewModalState extends State<PatchReviewModal> {
  String? _patchText;
  bool _isLoading = true;
  bool _isApplying = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadPatch();
  }

  Future<void> _loadPatch() async {
    setState(() => _isLoading = true);
    try {
      final patch = await widget.service.fetchActivePatch();
      if (mounted) {
        setState(() {
          _patchText = patch.trim().isNotEmpty ? patch : 'No code modifications in this mission yet.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApply() async {
    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });
    HapticFeedback.heavyImpact();

    try {
      await widget.service.applyActivePatch();
      if (mounted) {
        setState(() {
          _isApplying = false;
          _successMessage = 'Apply requested! Check AMBER approval gate.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4,
              decoration: const BoxDecoration(
                color: T.border,
                borderRadius: T.badgeCircle,
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: T.surfaceAlt,
                    border: Border.all(color: T.border),
                  ),
                  child: const Icon(Icons.difference_rounded, size: 20, color: T.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unified Git Patch Diff',
                        style: T.headlineSm,
                      ),
                      Text(
                        'SANDBOXED CHANGES AWAITING HUMAN REVIEW',
                        style: T.labelUpXs,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: T.onSurfaceVar),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: T.border),

          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.statusGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.statusGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.statusGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: AppTheme.statusGreen, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.statusRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.statusRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.statusRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.statusRed, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

          // Code Diff Scroll Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.terminalBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: (_patchText ?? '').split('\n').map((line) {
                          Color lineCol = Colors.white70;
                          Color bgCol = Colors.transparent;

                          if (line.startsWith('+') && !line.startsWith('+++')) {
                            lineCol = const Color(0xFF68D391);
                            bgCol = const Color(0xFF22543D).withValues(alpha: 0.35);
                          } else if (line.startsWith('-') && !line.startsWith('---')) {
                            lineCol = const Color(0xFFFC8181);
                            bgCol = const Color(0xFF742A2A).withValues(alpha: 0.35);
                          } else if (line.startsWith('@@')) {
                            lineCol = const Color(0xFF63B3ED);
                          } else if (line.startsWith('diff --git')) {
                            lineCol = AppTheme.primary;
                          }

                          return Container(
                            color: bgCol,
                            padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
                            child: Text(
                              line.isEmpty ? ' ' : line,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: lineCol,
                                height: 1.35,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _patchText ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patch copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text('COPY PATCH', style: T.labelUpXs.copyWith(color: T.onSurface)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: T.onSurface,
                      side: const BorderSide(color: T.border),
                      shape: const RoundedRectangleBorder(borderRadius: T.zero),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isApplying ? null : _handleApply,
                    icon: _isApplying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: T.onPrimary),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(_isApplying ? 'APPLYING...' : 'Apply to Repo', style: T.labelUpXs.copyWith(color: T.onPrimary, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: T.primary,
                      foregroundColor: T.onPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: T.zero),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

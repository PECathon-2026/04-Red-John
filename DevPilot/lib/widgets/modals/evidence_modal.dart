import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet for viewing verifiable evidence output (test runs, scans, command results).
class EvidenceModal extends StatelessWidget {
  final EvidenceRecord evidence;
  final VoidCallback? onClose;

  const EvidenceModal({
    super.key,
    required this.evidence,
    this.onClose,
  });

  static Future<void> show(BuildContext context, EvidenceRecord evidence) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: EvidenceModal(
          evidence: evidence,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passed = evidence.passed;
    final passColor = passed == true
        ? AppTheme.statusGreen
        : (passed == false ? AppTheme.statusRed : AppTheme.textSecondary);

    final prettyData = evidence.data.isNotEmpty
        ? const JsonEncoder.withIndent('  ').convert(evidence.data)
        : '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                  child: Icon(
                    passed == true ? Icons.verified_rounded : Icons.terminal_rounded,
                    size: 20,
                    color: passColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifiable Evidence Artifact',
                        style: T.headlineSm,
                      ),
                      Text(
                        'ID: ${evidence.evidenceId} · AGENT: ${evidence.agent.toUpperCase()}',
                        style: T.labelUpXs,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: T.onSurfaceVar),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: T.border),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: T.surfaceAlt,
                    border: Border.all(color: T.border),
                  ),
                  child: Text(
                    evidence.kind.toUpperCase(),
                    style: T.labelUpXs.copyWith(color: passColor),
                  ),
                ),
                const SizedBox(width: 8),
                if (passed != null)
                  Text(
                    passed ? 'VERDICT: PASS' : 'VERDICT: FAIL',
                    style: T.labelUpXs.copyWith(color: passColor, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),

          // Raw Output Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: T.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  evidence.summary.isNotEmpty ? '${evidence.summary}\n\n$prettyData' : prettyData,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: T.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),

          // Copy Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${evidence.summary}\n\n$prettyData'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evidence copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text('COPY RAW EVIDENCE OUTPUT', style: T.labelUpXs.copyWith(color: T.onSurface)),
              style: OutlinedButton.styleFrom(
                foregroundColor: T.onSurface,
                side: const BorderSide(color: T.border),
                shape: const RoundedRectangleBorder(borderRadius: T.zero),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

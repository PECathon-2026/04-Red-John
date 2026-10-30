import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/telemetry_service.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet for answering human clarification questions and resolving disputes.
class IssueResolverModal extends StatefulWidget {
  final TelemetryService service;
  final OpenIssueItem issue;
  final VoidCallback? onClose;

  const IssueResolverModal({
    super.key,
    required this.service,
    required this.issue,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required TelemetryService service,
    required OpenIssueItem issue,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: IssueResolverModal(
          service: service,
          issue: issue,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<IssueResolverModal> createState() => _IssueResolverModalState();
}

class _IssueResolverModalState extends State<IssueResolverModal> {
  final TextEditingController _resolutionController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _handleResolve() async {
    final text = _resolutionController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please provide an answer or ruling.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await widget.service.resolveHumanIssue(widget.issue.id, text);
      if (mounted) {
        widget.onClose?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
        maxWidth: 500,
      ),
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  child: const Icon(Icons.help_outline_rounded, size: 20, color: T.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Human-in-the-Loop Clarification',
                        style: T.headlineSm,
                      ),
                      Text(
                        'RAISED BY ${widget.issue.raisedBy.toUpperCase()} (${widget.issue.kind.toUpperCase()})',
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

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: T.destructive.withValues(alpha: 0.1),
                        border: Border.all(color: T.destructive),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: T.destructive, fontSize: 12)),
                    ),

                  // Question card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: T.surfaceAlt,
                      border: Border.all(color: T.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_alt_rounded, size: 16, color: T.onSurface),
                            const SizedBox(width: 6),
                            Text(
                              'QUESTION FROM ${widget.issue.raisedBy.toUpperCase()}',
                              style: T.labelUpXs.copyWith(color: T.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.issue.text,
                          style: T.bodyMd.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Answer input
                  Text('YOUR INSTRUCTION / CLARIFICATION', style: T.labelUpXs),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _resolutionController,
                    maxLines: 4,
                    style: T.bodyMd,
                    decoration: InputDecoration(
                      hintText: 'e.g. Export as CSV format with standard comma delimiter...',
                      hintStyle: T.bodySm,
                      filled: true,
                      fillColor: T.surfaceAlt,
                      enabledBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.border)),
                      focusedBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.onSurface)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: T.primary,
                        foregroundColor: T.onPrimary,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: T.zero),
                      ),
                      child: Text(
                        _isSubmitting ? 'RESUMING GUILD...' : 'Submit Resolution & Resume',
                        style: T.labelUpMd.copyWith(color: T.onPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

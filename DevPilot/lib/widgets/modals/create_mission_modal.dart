import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/telemetry_service.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet for creating and launching real AI engineering missions.
///
/// Supports custom prompt intake and 1-tap launching of the 6 evaluation benchmark scenarios.
class CreateMissionModal extends StatefulWidget {
  final TelemetryService service;
  final VoidCallback? onClose;

  const CreateMissionModal({
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
        child: CreateMissionModal(
          service: service,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<CreateMissionModal> createState() => _CreateMissionModalState();
}

class _CreateMissionModalState extends State<CreateMissionModal> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _repoPathController = TextEditingController(
    text: 'missions/01-feature-discounts/repo',
  );
  final TextEditingController _titleController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    _repoPathController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleLaunchCustom() async {
    final prompt = _promptController.text.trim();
    final repoPath = _repoPathController.text.trim();
    final title = _titleController.text.trim();

    if (prompt.length < 3) {
      setState(() => _errorMessage = 'Please describe the task (min 3 characters).');
      return;
    }
    if (repoPath.isEmpty) {
      setState(() => _errorMessage = 'Please specify the target repository path.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await widget.service.createMission(
        request: prompt,
        repoPath: repoPath,
        title: title.isNotEmpty ? title : null,
        start: true,
      );
      widget.onClose?.call();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  Future<void> _handleLaunchScenario(DemoScenario scenario) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    HapticFeedback.heavyImpact();

    try {
      await widget.service.launchDemoScenario(scenario);
      widget.onClose?.call();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
        maxWidth: 550,
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
                  child: const Icon(Icons.rocket_launch_rounded, size: 20, color: T.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Launch AI Mission',
                        style: T.headlineSm,
                      ),
                      Text(
                        'ATLAS ORCHESTRATOR & MULTI-AGENT TASK FORCE',
                        style: T.labelUpXs,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Scrollable Form Content
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
                              style: const TextStyle(color: AppTheme.statusRed, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Benchmark Scenarios Section
                  Text('EVALUATION BENCHMARK SCENARIOS', style: AppTheme.labelUppercase),
                  const SizedBox(height: 8),
                  Text(
                    'Tap any pre-packaged mission scenario to test the full guild pipeline:',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DemoScenario.all.map((scenario) {
                      return InkWell(
                        onTap: _isSubmitting ? null : () => _handleLaunchScenario(scenario),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: T.surfaceAlt,
                            border: Border.all(color: T.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: T.surfaceMuted,
                                  border: Border.all(color: T.border),
                                ),
                                child: Text(
                                  scenario.category,
                                  style: T.labelUpXs.copyWith(color: T.onSurface),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  scenario.title,
                                  style: T.bodyMd.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: T.onSurfaceVar),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: T.border),
                  const SizedBox(height: 20),

                  // Custom Mission Section
                  Text('CUSTOM CODING MISSION', style: T.labelUpXs),
                  const SizedBox(height: 12),

                  // Title field
                  TextField(
                    controller: _titleController,
                    style: T.bodyMd,
                    decoration: InputDecoration(
                      labelText: 'Mission Title (Optional)',
                      labelStyle: T.labelUpXs,
                      hintText: 'e.g. Fix invoice billing calculator',
                      hintStyle: T.bodySm,
                      filled: true,
                      fillColor: T.surfaceAlt,
                      enabledBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.border)),
                      focusedBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.onSurface)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Repository Path field
                  TextField(
                    controller: _repoPathController,
                    style: T.bodyMd,
                    decoration: InputDecoration(
                      labelText: 'Target Repository Path',
                      labelStyle: T.labelUpXs,
                      hintText: 'missions/01-feature-discounts/repo',
                      hintStyle: T.bodySm,
                      filled: true,
                      fillColor: T.surfaceAlt,
                      enabledBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.border)),
                      focusedBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.onSurface)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Request Prompt field
                  TextField(
                    controller: _promptController,
                    maxLines: 4,
                    style: T.bodyMd,
                    decoration: InputDecoration(
                      labelText: 'Task Prompt / Bug Description',
                      labelStyle: T.labelUpXs,
                      hintText: 'Describe what should be built or fixed in plain language...',
                      hintStyle: T.bodySm,
                      filled: true,
                      fillColor: T.surfaceAlt,
                      enabledBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.border)),
                      focusedBorder: const OutlineInputBorder(borderRadius: T.zero, borderSide: BorderSide(color: T.onSurface)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleLaunchCustom,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: T.onPrimary),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _isSubmitting ? 'DISPATCHING GUILD...' : 'LAUNCH MISSION',
                        style: T.labelUpMd.copyWith(color: T.onPrimary, fontWeight: FontWeight.w700),
                      ),
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
          ),
        ],
      ),
    );
  }
}

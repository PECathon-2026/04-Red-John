import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/telemetry_service.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet for configuring runtime build parameters, worker thread counts,
/// compiler flags, and LAN gateway hosts.
class ParameterModal extends StatefulWidget {
  final TelemetryService service;
  final VoidCallback? onClose;

  const ParameterModal({
    super.key,
    required this.service,
    this.onClose,
  });

  /// Static helper to display the Parameter Modal as a bottom sheet.
  static Future<void> show(BuildContext context, TelemetryService service) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ParameterModal(
          service: service,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<ParameterModal> createState() => _ParameterModalState();
}

class _ParameterModalState extends State<ParameterModal> {
  late TextEditingController _hostController;
  bool _noCache = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: 'devpilot.lan');
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 500,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: AppTheme.accentOrange,
                ),
                const SizedBox(width: 10),
                Text(
                  'Runtime Parameters',
                  style: AppTheme.displayMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textDark),
                  onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Body controls
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ListenableBuilder(
                listenable: widget.service,
                builder: (context, _) {
                  final threads = widget.service.workerThreads;
                  final isVerbose = widget.service.isVerbose;
                  final isLan = widget.service.isLANConnected;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section: Worker Threads Slider
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgWarm.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.memory_rounded,
                                      size: 18,
                                      color: AppTheme.accentOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Worker Threads',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkPill,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$threads Threads',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppTheme.accentOrange,
                                inactiveTrackColor: AppTheme.borderMedium,
                                thumbColor: AppTheme.accentOrange,
                                overlayColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                                valueIndicatorColor: AppTheme.darkPill,
                              ),
                              child: Slider(
                                value: threads.toDouble(),
                                min: 1.0,
                                max: 16.0,
                                divisions: 15,
                                label: '$threads',
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  widget.service.updateThreads(val.round());
                                },
                              ),
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1 (Low power)', style: AppTheme.bodySmall),
                                Text('16 (Max parallel)', style: AppTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section: Compiler Flags & Toggles
                      Material(
                        color: AppTheme.bgMain,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            children: [
                              // Verbose Switch
                              SwitchListTile.adaptive(
                                key: const Key('verbose_switch'),
                                value: isVerbose,
                                activeTrackColor: AppTheme.accentOrange,
                                title: const Text(
                                  '--verbose',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Enable detailed AST parser and compiler output',
                                  style: AppTheme.bodySmall,
                                ),
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  widget.service.toggleVerbose(val);
                                },
                              ),
                              const Divider(height: 1, color: AppTheme.borderSubtle),

                              // No-Cache Switch
                              SwitchListTile.adaptive(
                                key: const Key('nocache_switch'),
                                value: _noCache,
                                activeTrackColor: AppTheme.accentOrange,
                                title: const Text(
                                  '--no-cache',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Bypass local symbol cache and force clean build',
                                  style: AppTheme.bodySmall,
                                ),
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _noCache = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section: LAN Host & Gateway
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgMain,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lan_rounded,
                                      size: 18,
                                      color: AppTheme.statusGreen,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'LAN Host Gateway',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLan ? AppTheme.cardMint : AppTheme.cardPeach,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLan ? 'CONNECTED' : 'DISCONNECTED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isLan ? AppTheme.textDark : AppTheme.statusRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _hostController,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.dns_rounded, size: 18, color: AppTheme.textSecondary),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderMedium),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.accentOrange, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Pinned Save & Apply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onClose != null
                      ? widget.onClose!()
                      : Navigator.of(context).maybePop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkPill,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.pillRadius,
                  ),
                ),
                child: const Text(
                  'Save & Apply',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

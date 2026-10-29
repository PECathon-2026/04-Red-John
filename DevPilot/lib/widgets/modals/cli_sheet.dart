import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/telemetry_service.dart';
import '../../theme/app_theme.dart';

/// Modal bottom sheet providing a tactile monospace terminal drawer for ad-hoc command entry.
///
/// Styled in deep dark console background (#0E0E14), featuring quick command pills
/// ('flutter doctor', 'docker ps', 'git status', 'npm test') and a live interactive prompt.
class CliSheet extends StatefulWidget {
  final TelemetryService service;
  final VoidCallback? onClose;

  const CliSheet({
    super.key,
    required this.service,
    this.onClose,
  });

  /// Static helper to display the CLI sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, TelemetryService service) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CliSheet(
          service: service,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<CliSheet> createState() => _CliSheetState();
}

class _CliSheetState extends State<CliSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _terminalScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const List<String> _quickCommands = [
    'flutter doctor',
    'docker ps',
    'git status',
    'npm test',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _terminalScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitCommand([String? overrideCmd]) {
    final cmd = overrideCmd ?? _controller.text;
    if (cmd.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    widget.service.sendCliCommand(cmd.trim());
    _controller.clear();

    // Auto-scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppTheme.terminalBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppTheme.floatingShadow,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill & header
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.statusGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'operator@devpilot',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LAN E2EE : 8000',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.terminalText,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                  onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(color: Color(0x22FFFFFF), height: 1),

          // Monospace Terminal Output Log Feed
          Expanded(
            child: ListenableBuilder(
              listenable: widget.service,
              builder: (context, _) {
                final logs = widget.service.logs;
                return ListView.builder(
                  controller: _terminalScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${log.formattedTimestamp} ',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            TextSpan(
                              text: log.message,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                fontWeight: log.type == LogType.command ? FontWeight.w700 : FontWeight.w400,
                                color: log.type.logColor,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Quick Command Suggestions Pills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF07070A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickCommands.map((cmd) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _submitCommand(cmd),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '\$ ',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              cmd,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Command Input Field with Prompt
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
            color: const Color(0xFF12121A),
            child: Row(
              children: [
                const Text(
                  'operator@devpilot:~\$ ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    cursorColor: AppTheme.terminalText,
                    cursorWidth: 8,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppTheme.terminalText,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'command...',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white30,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => _submitCommand(),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _submitCommand(),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

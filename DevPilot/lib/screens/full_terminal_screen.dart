import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';

/// Full-screen interactive terminal console.
class FullTerminalScreen extends StatefulWidget {
  final TelemetryService service;
  final VoidCallback? onBack;

  const FullTerminalScreen({
    super.key,
    required this.service,
    this.onBack,
  });

  @override
  State<FullTerminalScreen> createState() => _FullTerminalScreenState();
}

class _FullTerminalScreenState extends State<FullTerminalScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _cmdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _filter = 'ALL';
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChange);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChange);
    _scrollController.dispose();
    _cmdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onServiceChange() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleSendCommand() {
    final text = _cmdController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    widget.service.executeCliCommand(text);
    _cmdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Filter & Controls Bar
            _buildControlsBar(),

            // Terminal Logs Area
            Expanded(
              child: ListenableBuilder(
                listenable: widget.service,
                builder: (context, _) {
                  var logs = widget.service.logs;
                  if (_filter == 'ERROR') {
                    logs = logs
                        .where((l) =>
                            l.type == LogType.error ||
                            l.type == LogType.stderr)
                        .toList();
                  } else if (_filter == 'CMD') {
                    logs = logs
                        .where((l) => l.type == LogType.command)
                        .toList();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: logs.length,
                    itemBuilder: (context, i) {
                      final log = logs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _formatLog(log),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: log.logColor,
                            height: 1.45,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Command Prompt Input
            _buildCommandBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(bottom: BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: T.border),
                color: T.surfaceMuted,
                borderRadius: T.rSm,
              ),
              child: const Icon(Icons.arrow_back, color: T.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TERMINAL CONSOLE', style: T.headlineSm),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: T.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'LIVE STREAMING',
                      style: T.labelUpXs.copyWith(color: T.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clear Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.service.clearTerminalLogs();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: T.border),
                borderRadius: T.rSm,
                color: T.surfaceMuted,
              ),
              child: Text('CLEAR', style: T.labelUpXs.copyWith(color: T.onSurface)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    final filters = ['ALL', 'CMD', 'ERROR'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          for (final f in filters) ...[
            GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _filter == f
                      ? T.accent
                      : Colors.transparent,
                  border: Border.all(
                    color: _filter == f ? T.accent : const Color(0xFF475569),
                  ),
                  borderRadius: T.rFull,
                ),
                child: Text(
                  f,
                  style: T.labelUpXs.copyWith(
                    color: _filter == f
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          // Auto-scroll toggle
          GestureDetector(
            onTap: () => setState(() => _autoScroll = !_autoScroll),
            child: Row(
              children: [
                Icon(
                  _autoScroll
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text('AUTOSCROLL', style: T.labelUpXs.copyWith(color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          Text('>', style: T.labelUpMd.copyWith(color: T.accent, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _cmdController,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: T.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Enter command (e.g. status, agents, run)...',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: T.onSurfaceMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _handleSendCommand(),
            ),
          ),
          GestureDetector(
            onTap: _handleSendCommand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: T.primary,
                borderRadius: T.rSm,
              ),
              child: Text(
                'RUN',
                style: T.labelUpXs.copyWith(color: T.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLog(TerminalLog log) {
    final prefix = switch (log.type) {
      LogType.success => '✔ ',
      LogType.error => '✖ ',
      LogType.warning => '▲ ',
      LogType.command => r'$ ',
      LogType.stderr => '! ',
      _ => '• ',
    };
    return '${log.formattedTimestamp} $prefix ${log.message}';
  }
}

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
      backgroundColor: const Color(0xFF0A0A0A),
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
        color: T.background,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: T.border),
                color: T.background,
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
              decoration: BoxDecoration(border: Border.all(color: T.border)),
              child: Text('CLEAR', style: T.labelUpXs),
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
        color: Color(0xFF141414),
        border: Border(bottom: BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          for (final f in filters) ...[
            GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _filter == f ? T.onSurface : Colors.transparent,
                  border: Border.all(
                    color: _filter == f ? T.onSurface : T.border,
                  ),
                ),
                child: Text(
                  f,
                  style: T.labelUpXs.copyWith(
                    color: _filter == f ? T.background : T.onSurfaceVar,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _autoScroll = !_autoScroll),
            child: Row(
              children: [
                Icon(
                  _autoScroll
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: _autoScroll ? T.success : T.onSurfaceVar,
                ),
                const SizedBox(width: 4),
                Text('AUTOSCROLL', style: T.labelUpXs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: T.background,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: Row(
        children: [
          Text(
            '> ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              color: T.success,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                hintText: 'Enter command (e.g. pytest, build, sync)...',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: T.onSurfaceMuted,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 10),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSendCommand(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded,
                color: T.onSurface, size: 20),
            onPressed: _handleSendCommand,
          ),
        ],
      ),
    );
  }

  String _formatLog(TerminalLog log) {
    final ts =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
    final prefix = switch (log.type) {
      LogType.success => 'OK ',
      LogType.error => 'ERR',
      LogType.warning => '!! ',
      LogType.command => '>> ',
      LogType.stderr => 'ERR',
      _ => '>  ',
    };
    return '$ts  $prefix  ${log.message}';
  }
}

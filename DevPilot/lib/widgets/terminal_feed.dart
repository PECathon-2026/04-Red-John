import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Live scrolling terminal console displaying color-coded logs from the build daemon.
///
/// Implements Paper & Lime ink card styling:
/// - Dark ink card (`surfaceInverse` #0E0F0C) with 24px radius (`AppTheme.cardRadius`).
/// - Flat surface without drop shadows.
/// - Color-coded monospace logs (lime #D7FE47, yellow #EAB308, red #EF4444, cyan #38BDF8).
/// - Live indicator dot, entry counter, copy-to-clipboard, and clear actions.
/// - Smart auto-scroll with pause-on-touch when reading past logs.
class TerminalFeed extends StatefulWidget {
  final List<TerminalLog> logs;
  final VoidCallback? onClear;
  final VoidCallback? onCopy;
  final double height;
  final bool showHeader;

  const TerminalFeed({
    super.key,
    required this.logs,
    this.onClear,
    this.onCopy,
    this.height = 280,
    this.showHeader = true,
  });

  @override
  State<TerminalFeed> createState() => _TerminalFeedState();
}

class _TerminalFeedState extends State<TerminalFeed> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollListener);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: false),
    );
  }

  @override
  void didUpdateWidget(covariant TerminalFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != oldWidget.logs.length) {
      if (_autoScroll && !_isUserScrolling) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: true),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollListener() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isAtBottom = (maxScroll - currentScroll).abs() < 24.0;

    if (isAtBottom && !_autoScroll) {
      setState(() => _autoScroll = true);
    } else if (!isAtBottom && _autoScroll && _isUserScrolling) {
      setState(() => _autoScroll = false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
      );
    } else {
      _scrollController.jumpTo(maxScroll);
    }
  }

  Future<void> _copyAllLogs() async {
    HapticFeedback.lightImpact();
    if (widget.onCopy != null) {
      widget.onCopy!();
      return;
    }

    final buffer = StringBuffer();
    for (final log in widget.logs) {
      buffer.writeln('${log.formattedTimestamp} ${log.message}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${widget.logs.length} log lines to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _resolveLogColor(TerminalLog log) {
    switch (log.type) {
      case LogType.success:
        return const Color(0xFFD7FE47); // Electric Lime
      case LogType.warning:
        return const Color(0xFFEAB308); // Yellow
      case LogType.error:
      case LogType.stderr:
        return const Color(0xFFEF4444); // Red
      case LogType.command:
        return const Color(0xFF38BDF8); // Cyan
      case LogType.info:
      case LogType.stdout:
        return const Color(0xFFF4F2EC); // Paper on inverse
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('terminal_feed_card'),
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceInverse,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppTheme.cardRadius,
        child: Column(
          children: [
            if (widget.showHeader) _buildTerminalHeader(),
            Expanded(child: _buildLogView()),
            if (!_autoScroll) _buildPausedIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141512),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Live status dot (lime)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Title & line count
          Text(
            'CONSOLE',
            style: AppTheme.labelUppercase.copyWith(
              color: AppTheme.onInverse,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(${widget.logs.length} entries)',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppTheme.onInverse.withValues(alpha: 0.4),
            ),
          ),

          const Spacer(),

          // Copy button
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              size: 15,
              color: Colors.white70,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            tooltip: 'Copy all logs',
            onPressed: widget.logs.isEmpty ? null : _copyAllLogs,
          ),
          const SizedBox(width: 4),

          // Clear button
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Colors.white70,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            tooltip: 'Clear terminal',
            onPressed: widget.onClear,
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    if (widget.logs.isEmpty) {
      return Center(
        child: Text(
          '~ / devpilot daemon listening...\nNo logs generated yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.6,
            color: AppTheme.onInverse.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        _isUserScrolling = notification.direction != ScrollDirection.idle;
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: widget.logs.length,
        itemBuilder: (context, index) {
          final log = widget.logs[index];
          final color = _resolveLogColor(log);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp
                Text(
                  log.formattedTimestamp,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: AppTheme.onInverse.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 10),

                // Log Message
                Expanded(
                  child: Text(
                    log.message,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPausedIndicator() {
    return Container(
      width: double.infinity,
      color: AppTheme.accent.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pause_circle_outline,
            size: 13,
            color: AppTheme.accent,
          ),
          const SizedBox(width: 6),
          const Text(
            'Auto-scroll paused (reading history)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _autoScroll = true);
              _scrollToBottom(animated: true);
            },
            child: const Text(
              'Resume ↓',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primitives.dart';

/// GitHub-style code difference viewer with project structure file tree and line-by-line deltas.
class DiffScreen extends StatefulWidget {
  final TelemetryService service;
  final VoidCallback? onBack;

  const DiffScreen({
    super.key,
    required this.service,
    this.onBack,
  });

  @override
  State<DiffScreen> createState() => _DiffScreenState();
}

class _DiffScreenState extends State<DiffScreen> {
  late final List<DiffFile> _diffFiles;
  final Set<String> _expandedFiles = {};
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _diffFiles = _generateSampleDiffs();
    if (_diffFiles.isNotEmpty) {
      _expandedFiles.add(_diffFiles.first.path);
    }
  }

  List<DiffFile> _generateSampleDiffs() {
    return const [
      DiffFile(
        path: 'backend/services/discount_engine.py',
        status: 'modified',
        additions: 18,
        deletions: 4,
        lines: [
          DiffLine(text: '@@ -12,10 +12,24 @@ class DiscountService:', type: 'context', oldLineNumber: 12, newLineNumber: 12),
          DiffLine(text: '     def __init__(self, repo: CartRepository):', type: 'context', oldLineNumber: 13, newLineNumber: 13),
          DiffLine(text: '         self.repo = repo', type: 'context', oldLineNumber: 14, newLineNumber: 14),
          DiffLine(text: '-        self.default_discount_rate = 0.05', type: 'delete', oldLineNumber: 15),
          DiffLine(text: '+        self.default_discount_rate = 0.15', type: 'add', newLineNumber: 15),
          DiffLine(text: '+        self.min_item_threshold = 3', type: 'add', newLineNumber: 16),
          DiffLine(text: ' ', type: 'context', oldLineNumber: 16, newLineNumber: 17),
          DiffLine(text: '     def evaluate_cart_discount(self, cart: Cart) -> Decimal:', type: 'context', oldLineNumber: 17, newLineNumber: 18),
          DiffLine(text: '-        if len(cart.items) >= 5:', type: 'delete', oldLineNumber: 18),
          DiffLine(text: '-            return cart.subtotal * Decimal("0.10")', type: 'delete', oldLineNumber: 19),
          DiffLine(text: '-        return Decimal("0.00")', type: 'delete', oldLineNumber: 20),
          DiffLine(text: '+        total_units = sum(item.quantity for item in cart.items)', type: 'add', newLineNumber: 19),
          DiffLine(text: '+        if total_units >= self.min_item_threshold:', type: 'add', newLineNumber: 20),
          DiffLine(text: '+            discount_amount = cart.subtotal * Decimal(str(self.default_discount_rate))', type: 'add', newLineNumber: 21),
          DiffLine(text: '+            logger.info("applied_discount", units=total_units, rate=self.default_discount_rate)', type: 'add', newLineNumber: 22),
          DiffLine(text: '+            return discount_amount.quantize(Decimal("0.01"))', type: 'add', newLineNumber: 23),
          DiffLine(text: '+        return Decimal("0.00")', type: 'add', newLineNumber: 24),
          DiffLine(text: ' ', type: 'context', oldLineNumber: 21, newLineNumber: 25),
        ],
      ),
      DiffFile(
        path: 'tests/unit/test_discounts.py',
        status: 'added',
        additions: 24,
        deletions: 0,
        lines: [
          DiffLine(text: '@@ -0,0 +1,24 @@', type: 'context', newLineNumber: 1),
          DiffLine(text: '+import pytest', type: 'add', newLineNumber: 1),
          DiffLine(text: '+from decimal import Decimal', type: 'add', newLineNumber: 2),
          DiffLine(text: '+from backend.services.discount_engine import DiscountService', type: 'add', newLineNumber: 3),
          DiffLine(text: '+', type: 'add', newLineNumber: 4),
          DiffLine(text: '+def test_discount_triggered_at_three_items():', type: 'add', newLineNumber: 5),
          DiffLine(text: '+    svc = DiscountService(None)', type: 'add', newLineNumber: 6),
          DiffLine(text: '+    cart = MockCart(subtotal=Decimal("100.00"), item_count=3)', type: 'add', newLineNumber: 7),
          DiffLine(text: '+    assert svc.evaluate_cart_discount(cart) == Decimal("15.00")', type: 'add', newLineNumber: 8),
          DiffLine(text: '+', type: 'add', newLineNumber: 9),
          DiffLine(text: '+def test_no_discount_under_threshold():', type: 'add', newLineNumber: 10),
          DiffLine(text: '+    svc = DiscountService(None)', type: 'add', newLineNumber: 11),
          DiffLine(text: '+    cart = MockCart(subtotal=Decimal("100.00"), item_count=2)', type: 'add', newLineNumber: 12),
          DiffLine(text: '+    assert svc.evaluate_cart_discount(cart) == Decimal("0.00")', type: 'add', newLineNumber: 13),
        ],
      ),
      DiffFile(
        path: 'config/pricing_matrix.yaml',
        status: 'modified',
        additions: 4,
        deletions: 2,
        lines: [
          DiffLine(text: '@@ -3,4 +3,6 @@ promotion_rules:', type: 'context', oldLineNumber: 3, newLineNumber: 3),
          DiffLine(text: '-  tier1_threshold: 5', type: 'delete', oldLineNumber: 4),
          DiffLine(text: '-  tier1_percent: 10', type: 'delete', oldLineNumber: 5),
          DiffLine(text: '+  tier1_threshold: 3', type: 'add', newLineNumber: 4),
          DiffLine(text: '+  tier1_percent: 15', type: 'add', newLineNumber: 5),
          DiffLine(text: '+  audit_log: true', type: 'add', newLineNumber: 6),
        ],
      ),
    ];
  }

  void _toggleFile(String path) {
    setState(() {
      if (_expandedFiles.contains(path)) {
        _expandedFiles.remove(path);
      } else {
        _expandedFiles.add(path);
      }
    });
  }

  void _expandAll() {
    setState(() {
      _expandedFiles.addAll(_diffFiles.map((f) => f.path));
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedFiles.clear();
    });
  }

  void _handleApprove() {
    HapticFeedback.heavyImpact();
    setState(() => _isApplying = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patch approved and merged successfully.'),
          backgroundColor: T.success,
        ),
      );
      Navigator.of(context).maybePop();
    });
  }

  void _handleReject() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patch rejected by reviewer.'),
        backgroundColor: T.destructive,
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final totalAdditions = _diffFiles.fold<int>(0, (sum, f) => sum + f.additions);
    final totalDeletions = _diffFiles.fold<int>(0, (sum, f) => sum + f.deletions);

    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
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
                        color: T.surfaceMuted,
                        borderRadius: T.rSm,
                        border: Border.all(color: T.border),
                      ),
                      child: const Icon(Icons.arrow_back, color: T.onSurface, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DIFF REVIEW', style: T.headlineSm),
                        const SizedBox(height: 2),
                        Text(
                          '${_diffFiles.length} files changed',
                          style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                        ),
                      ],
                    ),
                  ),
                  // Totals
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: T.surfaceMuted,
                      borderRadius: T.rFull,
                      border: Border.all(color: T.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+$totalAdditions', style: T.labelUpXs.copyWith(color: T.success)),
                        const SizedBox(width: 6),
                        Text('-$totalDeletions', style: T.labelUpXs.copyWith(color: T.destructive)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: T.surfaceMuted,
                border: Border(bottom: BorderSide(color: T.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _expandAll,
                    child: Text('EXPAND ALL', style: T.labelUpXs.copyWith(color: T.accent)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _collapseAll,
                    child: Text('COLLAPSE ALL', style: T.labelUpXs.copyWith(color: T.onSurfaceVar)),
                  ),
                  const Spacer(),
                  Text(
                    'BRANCH: main',
                    style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                  ),
                ],
              ),
            ),

            // Scrollable File Tree & Line Diffs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: _diffFiles.length,
                itemBuilder: (context, i) {
                  final file = _diffFiles[i];
                  final isExpanded = _expandedFiles.contains(file.path);
                  return _buildFileDiffItem(file, isExpanded);
                },
              ),
            ),

            // Sticky Bottom Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: T.surface,
                border: Border(top: BorderSide(color: T.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonSecondary(
                      label: 'REJECT PATCH',
                      borderRadius: T.rSm,
                      onTap: _handleReject,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ButtonPrimary(
                      label: _isApplying ? 'APPLYING...' : 'APPROVE & MERGE',
                      borderRadius: T.rSm,
                      bg: T.primary,
                      textColor: T.onPrimary,
                      onTap: _handleApprove,
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

  Widget _buildFileDiffItem(DiffFile file, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.rMd,
        border: Border.all(color: T.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Header Row
          InkWell(
            onTap: () => _toggleFile(file.path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: T.surfaceMuted,
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 20,
                    color: T.onSurfaceVar,
                  ),
                  const SizedBox(width: 6),
                  _buildStatusBadge(file.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.path,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: T.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('+${file.additions} ', style: T.labelUpXs.copyWith(color: T.success)),
                  Text('-${file.deletions}', style: T.labelUpXs.copyWith(color: T.destructive)),
                ],
              ),
            ),
          ),

          // Code Diff Lines (when expanded)
          if (isExpanded)
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: file.lines.map(_buildDiffLine).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status) {
      'added' => T.success,
      'deleted' => T.destructive,
      _ => T.accentBlue,
    };
    final symbol = switch (status) {
      'added' => '+',
      'deleted' => '-',
      _ => '~',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: T.rSm,
      ),
      child: Text(
        symbol,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildDiffLine(DiffLine line) {
    Color stripColor = Colors.transparent;
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF94A3B8);

    if (line.type == 'add') {
      stripColor = T.success;
      bgColor = T.success.withValues(alpha: 0.12);
      textColor = const Color(0xFF86EFAC);
    } else if (line.type == 'delete') {
      stripColor = T.destructive;
      bgColor = T.destructive.withValues(alpha: 0.15);
      textColor = const Color(0xFFFCA5A5);
    } else if (line.text.startsWith('@@')) {
      textColor = const Color(0xFF60A5FA);
      bgColor = const Color(0xFF1E293B);
    }

    final lineNum = line.newLineNumber?.toString() ?? line.oldLineNumber?.toString() ?? ' ';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(
            color: stripColor != Colors.transparent ? stripColor : const Color(0xFF334155),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              lineNum,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

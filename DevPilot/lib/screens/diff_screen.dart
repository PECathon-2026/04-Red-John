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
    HapticFeedback.lightImpact();
    setState(() {
      if (_expandedFiles.contains(path)) {
        _expandedFiles.remove(path);
      } else {
        _expandedFiles.add(path);
      }
    });
  }

  Future<void> _handleApprove() async {
    HapticFeedback.mediumImpact();
    setState(() => _isApplying = true);
    await Future.delayed(const Duration(milliseconds: 700));
    widget.service.triggerAction('Apply Patch');
    if (mounted) {
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patch applied cleanly to repository branch.'),
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  void _handleReject() {
    HapticFeedback.lightImpact();
    widget.service.triggerAction('Reject Patch');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patch rejected. Feedback dispatched to orchestrator.'),
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final totalAdd = _diffFiles.fold(0, (sum, f) => sum + f.additions);
    final totalDel = _diffFiles.fold(0, (sum, f) => sum + f.deletions);

    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
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
                      decoration: BoxDecoration(border: Border.all(color: T.border)),
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
                          style: T.labelUpXs,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text('+$totalAdd ', style: T.labelUpSm.copyWith(color: T.success, fontWeight: FontWeight.bold)),
                      Text('-$totalDel', style: T.labelUpSm.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable File Tree & Line Diffs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                color: T.surfaceMuted,
                border: Border(top: BorderSide(color: T.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonSecondary(
                      label: 'REJECT PATCH',
                      onTap: _handleReject,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ButtonPrimary(
                      label: _isApplying ? 'APPLYING...' : 'APPROVE & MERGE',
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
        color: T.background,
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Header Row
          InkWell(
            onTap: () => _toggleFile(file.path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: T.surfaceMuted.withValues(alpha: 0.5),
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
                  Text('-${file.deletions}', style: T.labelUpXs.copyWith(color: Colors.red.shade400)),
                ],
              ),
            ),
          ),

          // Code Diff Lines (when expanded)
          if (isExpanded)
            Container(
              color: const Color(0xFF0C0C0C),
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
      _ => T.chart2,
    };
    final symbol = switch (status) {
      'added' => '+',
      'deleted' => '-',
      _ => '~',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2)),
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
    Color textColor = T.onSurfaceVar;

    if (line.type == 'add') {
      stripColor = T.success;
      bgColor = T.success.withValues(alpha: 0.08);
      textColor = const Color(0xFF86EFAC);
    } else if (line.type == 'delete') {
      stripColor = Colors.red.shade700;
      bgColor = Colors.red.shade900.withValues(alpha: 0.12);
      textColor = const Color(0xFFFCA5A5);
    } else if (line.text.startsWith('@@')) {
      textColor = T.chart2;
      bgColor = const Color(0xFF161616);
    }

    final lineNum = line.newLineNumber?.toString() ?? line.oldLineNumber?.toString() ?? ' ';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(
            color: stripColor != Colors.transparent ? stripColor : T.border,
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
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: T.onSurfaceMuted,
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

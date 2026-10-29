import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primitives.dart';

/// 2-column grid screen displaying all build and AI pipeline artifacts.
class ArtifactListScreen extends StatelessWidget {
  final List<ArtifactItem> artifacts;
  final TelemetryService service;
  final VoidCallback? onBack;

  const ArtifactListScreen({
    super.key,
    required this.artifacts,
    required this.service,
    this.onBack,
  });

  static Color artifactColor(ArtifactType t) => switch (t) {
        ArtifactType.apk => T.success,
        ArtifactType.image => T.chart2,
        ArtifactType.document => T.chart1,
        ArtifactType.log => T.chart3,
        ArtifactType.archive => T.chart4,
        _ => T.onSurfaceVar,
      };

  static IconData artifactIcon(ArtifactType t) => switch (t) {
        ArtifactType.apk => Icons.android_outlined,
        ArtifactType.image => Icons.image_outlined,
        ArtifactType.document => Icons.description_outlined,
        ArtifactType.log => Icons.terminal_rounded,
        ArtifactType.archive => Icons.archive_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

  void _inspectArtifact(BuildContext context, ArtifactItem a) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: T.background,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(T.lg),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: T.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(artifactIcon(a.type), color: artifactColor(a.type), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.name,
                    style: T.headlineSm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: T.border),
            const SizedBox(height: 16),
            _infoRow('TYPE', a.typeLabel),
            _infoRow('SIZE', a.size),
            if (a.path != null) _infoRow('PATH', a.path!),
            _infoRow('GENERATED',
                '${a.timestamp.hour.toString().padLeft(2, '0')}:${a.timestamp.minute.toString().padLeft(2, '0')} UTC'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ButtonSecondary(
                    label: 'COPY PATH',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: a.path ?? a.name));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Path copied to clipboard')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ButtonPrimary(
                    label: 'DOWNLOAD',
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${a.name}...')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: T.labelUpXs),
          Text(value, style: T.bodySm.copyWith(color: T.onSurface)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = artifacts.isNotEmpty ? artifacts : service.artifacts;

    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      if (onBack != null) {
                        onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(border: Border.all(color: T.border)),
                      child: const Icon(Icons.arrow_back,
                          color: T.onSurface, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('ALL ARTIFACTS', style: T.headlineSm),
                  ),
                  BadgePill('${list.length} ASSETS'),
                ],
              ),
            ),

            // 2-Column Hairline Lattice Grid
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No artifacts generated yet', style: T.bodySm),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final a = list[i];
                        final color = artifactColor(a.type);
                        final icon = artifactIcon(a.type);

                        return GestureDetector(
                          onTap: () => _inspectArtifact(context, a),
                          child: Container(
                            decoration: BoxDecoration(
                              color: T.surfaceMuted.withValues(alpha: 0.3),
                              border: Border.all(color: T.border),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(icon, size: 26, color: color),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                      ),
                                      child: Text(
                                        a.typeLabel,
                                        style: T.labelUpXs.copyWith(
                                          color: color,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  a.name,
                                  style: T.labelUpSm.copyWith(
                                    color: T.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(height: 1, color: T.border),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(a.size, style: T.labelUpXs),
                                    Text(
                                      '${a.timestamp.minute}m ago',
                                      style: T.labelUpXs.copyWith(
                                        color: T.onSurfaceMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Horizontal scrolling stream of artifact cards produced during execution.
///
/// Displays generated files (APKs, screenshots, diagnostic logs, PDFs)
/// with file-type badges, formatted file sizes, and interactive preview taps.
class ArtifactStream extends StatelessWidget {
  final List<ArtifactItem> artifacts;
  final void Function(ArtifactItem artifact)? onArtifactTap;
  final bool showHeader;

  const ArtifactStream({
    super.key,
    required this.artifacts,
    this.onArtifactTap,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (artifacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                const Text(
                  'Artifacts & Output',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.bgWarm,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${artifacts.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: artifacts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final artifact = artifacts[index];
              return _ArtifactCard(
                artifact: artifact,
                onTap: () => onArtifactTap?.call(artifact),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  final ArtifactItem artifact;
  final VoidCallback onTap;

  const _ArtifactCard({
    required this.artifact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _getArtifactMeta(artifact.type);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderSubtle,
          width: 1.2,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Type icon + Size pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: meta.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        meta.icon,
                        size: 20,
                        color: meta.fgColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgMain,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        artifact.size,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom row: File name & download/preview arrow
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artifact.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artifact.typeLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ArtifactTypeMeta _getArtifactMeta(ArtifactType type) {
    switch (type) {
      case ArtifactType.apk:
        return const _ArtifactTypeMeta(
          icon: Icons.install_mobile_rounded,
          bgColor: Color(0xFFE8F5E9),
          fgColor: Color(0xFF2E7D32),
        );
      case ArtifactType.image:
        return const _ArtifactTypeMeta(
          icon: Icons.image_outlined,
          bgColor: Color(0xFFF3E5F5),
          fgColor: Color(0xFF7B1FA2),
        );
      case ArtifactType.document:
        return const _ArtifactTypeMeta(
          icon: Icons.description_outlined,
          bgColor: Color(0xFFFFF3E0),
          fgColor: Color(0xFFE65100),
        );
      case ArtifactType.log:
        return const _ArtifactTypeMeta(
          icon: Icons.terminal_rounded,
          bgColor: Color(0xFFE0F7FA),
          fgColor: Color(0xFF00838F),
        );
      case ArtifactType.archive:
        return const _ArtifactTypeMeta(
          icon: Icons.folder_zip_outlined,
          bgColor: Color(0xFFEDE7F6),
          fgColor: Color(0xFF4527A0),
        );
      case ArtifactType.other:
        return const _ArtifactTypeMeta(
          icon: Icons.insert_drive_file_outlined,
          bgColor: Color(0xFFECEFF1),
          fgColor: Color(0xFF37474F),
        );
    }
  }
}

class _ArtifactTypeMeta {
  final IconData icon;
  final Color bgColor;
  final Color fgColor;

  const _ArtifactTypeMeta({
    required this.icon,
    required this.bgColor,
    required this.fgColor,
  });
}

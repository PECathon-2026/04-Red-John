import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modals/create_mission_modal.dart';
import '../widgets/running_task_card.dart';

/// Full implementation of the Paper & Lime editorial HomeScreen.
///
/// Features:
/// - Screen-based navigation (no bottom tabs).
/// - Top editorial app bar with user avatar, 'DEV PILOT' kicker, greeting, and ember alert dot.
/// - Metric strip displaying live performance stats with Space Grotesk tabular numerals.
/// - 'Your Projects (N)' carousel with paper-alt 24px cards, duration pills, and ↗ icons.
/// - Current Running Project Card directly below projects (live timer, lime pill, LAN E2EE).
/// - Floating quick utility bar for CLI and Settings access.
class HomeScreen extends StatefulWidget {
  final TelemetryService service;
  final void Function(ProjectItem project) onOpenProject;
  final void Function(AgentItem agent)? onOpenAgent;
  final VoidCallback? onOpenTerminal;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onKillTriggered;

  const HomeScreen({
    super.key,
    required this.service,
    required this.onOpenProject,
    this.onOpenAgent,
    this.onOpenTerminal,
    this.onOpenSettings,
    this.onKillTriggered,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final projects = widget.service.projects;
            final runningTask = widget.service.currentTask;
            final vitals = widget.service.vitals;

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Top App Bar ---
                      _buildTopAppBar(),

                      const SizedBox(height: 20),

                      // --- Hero Metric Data Strip ---
                      _buildMetricStrip(vitals),

                      const SizedBox(height: 24),

                      // --- Projects Section ---
                      _buildProjectsSection(projects),

                      const SizedBox(height: 24),

                      // --- Active Running Task Card ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT EXECUTION',
                              style: AppTheme.labelUppercase,
                            ),
                            const SizedBox(height: 10),
                            RunningTaskCard(
                              task: runningTask,
                              vitals: vitals,
                              onMacroAction: (action) {
                                widget.service.triggerAction(action);
                                if (action == 'Kill All' ||
                                    action.toLowerCase().contains('kill')) {
                                  widget.onKillTriggered?.call();
                                }
                              },
                              onTap: () {
                                if (projects.isNotEmpty) {
                                  widget.onOpenProject(projects.first);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Floating Bottom Quick Action Pill ---
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildFloatingQuickBar(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Avatar + Two-line greeting
          Row(
            children: [
              Container(
                key: const Key('header_avatar'),
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('DEV PILOT', style: AppTheme.labelUppercase),
                  const SizedBox(height: 2),
                  Text('Hello, Aryan', style: AppTheme.headlineMd),
                ],
              ),
            ],
          ),

          // Right: Utility icon buttons
          Row(
            children: [
              // Launch Mission Button
              GestureDetector(
                key: const Key('header_launch_icon'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  CreateMissionModal.show(context, widget.service);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Settings / Quick Action Button
              GestureDetector(
                key: const Key('header_grid_icon'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onOpenSettings?.call();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Notification icon button with Ember Alert Dot
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onOpenTerminal?.call();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 18,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        key: const Key('ember_alert_dot'),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent, // Ember orange #FF5A1F
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Hero Metric Data Strip ---
  Widget _buildMetricStrip(HardwareVitals vitals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: AppTheme.cardRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SYSTEM VITALS', style: AppTheme.labelUppercase),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${vitals.cpuPercent.toInt()}%',
                      style: AppTheme.displayMd.copyWith(color: AppTheme.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CPU LOAD',
                      style: AppTheme.caption.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 1,
              height: 36,
              color: AppTheme.border,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PIPELINE HEALTH', style: AppTheme.labelUppercase),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '99.8',
                      style: AppTheme.displayMd.copyWith(color: AppTheme.onSurface),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '% OK',
                      style: AppTheme.caption.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Projects Section ---
  Widget _buildProjectsSection(List<ProjectItem> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE WORKSPACE', style: AppTheme.labelUppercase),
                  const SizedBox(height: 4),
                  Text('Your Projects (${projects.length})', style: AppTheme.headlineSm),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.onSurface),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  CreateMissionModal.show(context, widget.service);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (projects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                CreateMissionModal.show(context, widget.service);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.rocket_launch_outlined, size: 36, color: AppTheme.primaryDark),
                    const SizedBox(height: 10),
                    const Text(
                      'No Active Missions Yet',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to launch a new mission or benchmark scenario',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 235,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final project = projects[index];
                return _WorkflowCard(
                  project: project,
                  onTap: () {
                    widget.service.selectMission(project.id);
                    widget.onOpenProject(project);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // --- Floating Quick Bar ---
  Widget _buildFloatingQuickBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceInverse,
        borderRadius: AppTheme.pillRadius,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(14, 15, 12, 0.28),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Launch Project Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.service.projects.isNotEmpty) {
                widget.onOpenProject(widget.service.projects.first);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary, // Electric Lime
                borderRadius: AppTheme.pillRadius,
              ),
              child: const Row(
                children: [
                  Icon(Icons.dashboard_rounded, size: 16, color: AppTheme.onPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Active Project',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // CLI Terminal Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onOpenTerminal?.call();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: AppTheme.onInverse,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Parameters / Settings Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onOpenSettings?.call();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: AppTheme.onInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper & Lime 24px Project Workflow Card.
class _WorkflowCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback onTap;

  const _WorkflowCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: AppTheme.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Category icon circle + Corner arrow icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder_outlined,
                      size: 18,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            // Middle: Project Title
            Text(
              project.title,
              style: AppTheme.cardTitle.copyWith(
                fontSize: 17,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Bottom: Duration Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: AppTheme.pillRadius,
              ),
              child: Text(
                project.duration,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

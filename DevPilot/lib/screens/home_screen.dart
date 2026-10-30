import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dicebear_avatar.dart';
import '../widgets/modals/create_mission_modal.dart';
import '../widgets/phosphor_icon.dart';
import '../widgets/primitives.dart';

/// Redesigned Modern Light HomeScreen.
///
/// Layout:
/// - Top greeting: "DEVPILOT", small "hello,", under it person's front name "Aryan" (no avatar, no plus button).
/// - Launch Mission Widget: Card widget with subtle watermark rocket icon and accent button.
/// - Projects Section: Horizontal scroll of cards with distinct accent colors and rounded corners. No pill shape buttons.
/// - Current Execution Section: Running agent only (no system stats), clean circular avatar with no box behind it.
/// - Past Executions Section: Clean rounded card list with status badges.
/// - System Vitals Section: Horizontal scrolling strip with clean metric cards.
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

  static const List<Color> _projectAccents = [
    T.accent,       // Indigo
    T.accentTeal,   // Teal
    T.accentBlue,   // Royal Blue
    T.accentPurple, // Violet
    T.amber,        // Amber
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final projects = widget.service.projects;
            final vitals = widget.service.vitals;

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Greeting (no avatar, small hello, front name Aryan, no plus button)
                  _buildGreeting(),

                  const SizedBox(height: 20),

                  // 2. Launch Mission Card Widget
                  _buildLaunchWidget(),

                  const SizedBox(height: 28),

                  // 3. Projects Section (horizontal scroll, distinct accents, no pill buttons)
                  _buildProjectsSection(projects),

                  const SizedBox(height: 28),

                  // 4. Current Execution Section (only running agent, no system stats)
                  _buildCurrentExecutionSection(),

                  const SizedBox(height: 28),

                  // 5. Past Executions Section
                  _buildPastExecutionsSection(),

                  const SizedBox(height: 28),

                  // 6. System Vitals Section (Horizontal scrolling strip)
                  _buildSystemVitalsSection(vitals),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. Top Greeting ---
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(T.lg, 24, T.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DEVPILOT', style: T.eyebrowWide),
          const SizedBox(height: 4),
          Text(
            'hello,',
            style: T.displaySm.copyWith(
              color: T.onSurfaceVar,
              height: 1.1,
            ),
          ),
          Text(
            'Aryan',
            style: T.displayMd.copyWith(
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Launch Mission Widget ---
  Widget _buildLaunchWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          CreateMissionModal.show(context, widget.service);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: T.rLg,
            border: Border.all(color: T.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Watermark Phosphor Icon
              Positioned(
                top: -10,
                right: -10,
                child: PhosphorIcon(
                  'rocket-launch',
                  size: 110,
                  color: T.accent.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(T.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: T.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('LAUNCH NEW MISSION', style: T.labelUpMd.copyWith(color: T.accent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Build something new →', style: T.headlineLg),
                    const SizedBox(height: 6),
                    Text(
                      'Configure agents, set goals, and start an autonomous pipeline.',
                      style: T.bodySm.copyWith(color: T.onSurfaceVar),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: T.primary,
                        borderRadius: T.rSm,
                      ),
                      child: Center(
                        child: Text(
                          'START MISSION',
                          style: T.labelUpSm.copyWith(
                            color: T.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Projects Section ---
  Widget _buildProjectsSection(List<ProjectItem> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.lg),
          child: SectionHeader(
            'PROJECTS',
            trailing: BadgePill(
              '${projects.length} ACTIVE',
              bg: T.surfaceMuted,
              textColor: T.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: T.lg),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final project = projects[i];
              final accentColor = _projectAccents[i % _projectAccents.length];
              return _buildProjectCard(project, accentColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(ProjectItem p, Color accentColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.service.selectMission(p.id);
        widget.onOpenProject(p);
      },
      child: Container(
        width: 195,
        padding: const EdgeInsets.all(T.md),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: T.rLg,
          border: Border.all(color: T.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Folder icon with accent badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: T.rSm,
                  ),
                  child: PhosphorIcon(
                    'folder-simple',
                    size: 18,
                    color: accentColor,
                  ),
                ),
                if (p.isLive)
                  BadgePill(
                    'LIVE',
                    bg: T.success.withValues(alpha: 0.12),
                    textColor: T.success,
                  ),
              ],
            ),
            // Middle: Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: T.headlineMd,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            // Bottom: Progress bar + subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HairlineBar(p.progress, color: accentColor),
                const SizedBox(height: 8),
                Text(
                  p.subtitle,
                  style: T.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Current Execution Section ---
  Widget _buildCurrentExecutionSection() {
    final runningAgents = widget.service.agents.where((a) {
      final p = a.phase.toLowerCase();
      return p == 'running' || p == 'working' || p == 'implementation';
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('CURRENT EXECUTION'),
          const SizedBox(height: 12),
          if (runningAgents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(T.md),
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: T.rMd,
                border: Border.all(color: T.border),
              ),
              child: Text(
                'No active execution running.',
                style: T.bodySm.copyWith(color: T.onSurfaceVar),
              ),
            )
          else
            _buildRunningAgentCard(runningAgents.first),
        ],
      ),
    );
  }

  Widget _buildRunningAgentCard(AgentItem agent) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.service.projects.isNotEmpty) {
          widget.onOpenProject(widget.service.projects.first);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(T.md),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: T.rLg,
          border: Border.all(color: T.success.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: T.success.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Modern human avatar (no outer box frame)
            CuteAvatar(name: agent.name, size: 52),
            const SizedBox(width: T.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: T.headlineSm),
                  const SizedBox(height: 2),
                  Text(
                    agent.team.toUpperCase(),
                    style: T.labelUpXs.copyWith(color: T.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent.currentTask.isNotEmpty
                        ? agent.currentTask
                        : 'Executing task pipeline',
                    style: T.bodySm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Running Badge with green success dot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: T.success.withValues(alpha: 0.12),
                borderRadius: T.rFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: T.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'RUNNING',
                    style: T.labelUpXs.copyWith(color: T.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Past Executions Section ---
  Widget _buildPastExecutionsSection() {
    final past = widget.service.pastExecutions.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'PAST EXECUTIONS',
            trailing: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.service.projects.isNotEmpty) {
                  widget.onOpenProject(widget.service.projects.first);
                }
              },
              child: Text(
                'View all →',
                style: T.labelUpXs.copyWith(color: T.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: T.rLg,
              border: Border.all(color: T.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < past.length; i++) ...[
                  if (i > 0) Container(height: 1, color: T.border),
                  Padding(
                    padding: const EdgeInsets.all(T.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(past[i].projectName, style: T.headlineSm),
                              const SizedBox(height: 2),
                              Text(
                                past[i].completedAgo,
                                style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                              ),
                            ],
                          ),
                        ),
                        BadgePill(
                          past[i].success ? 'DONE' : 'FAILED',
                          bg: past[i].success
                              ? T.success.withValues(alpha: 0.12)
                              : T.destructive.withValues(alpha: 0.12),
                          textColor: past[i].success
                              ? T.success
                              : T.destructive,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. System Vitals Section (HORIZONTAL) ---
  Widget _buildSystemVitalsSection(HardwareVitals v) {
    final vitals = [
      _VitalCardData(
        label: 'CPU LOAD',
        value: '${v.cpuPercent.toInt()}%',
        icon: 'cpu',
        barValue: v.cpuPercent / 100,
        accentColor: T.accentBlue,
      ),
      _VitalCardData(
        label: 'RAM USAGE',
        value: '${v.ramPercent.toInt()}%',
        icon: 'hard-drive',
        barValue: v.ramPercent / 100,
        accentColor: T.accentPurple,
      ),
      _VitalCardData(
        label: 'NETWORK',
        value: '${v.networkMBps.toStringAsFixed(1)} MB/s',
        icon: 'wifi-high',
        barValue: (v.networkMBps / 10).clamp(0.0, 1.0),
        accentColor: T.accentTeal,
      ),
      _VitalCardData(
        label: 'BATTERY',
        value: '${v.batteryPercent.toInt()}%',
        icon: 'gauge',
        barValue: v.batteryPercent / 100,
        accentColor: T.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: T.lg),
          child: SectionHeader('SYSTEM VITALS'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: T.lg),
            child: Row(
              children: [
                for (int i = 0; i < vitals.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _buildHorizontalVitalCard(vitals[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalVitalCard(_VitalCardData item) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(T.md),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: T.rMd,
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: T.labelUpSm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.12),
                  borderRadius: T.rSm,
                ),
                child: PhosphorIcon(item.icon, size: 14, color: item.accentColor),
              ),
            ],
          ),
          Text(item.value, style: T.numeralXl.copyWith(fontSize: 28)),
          if (item.barValue != null)
            ClipRRect(
              borderRadius: T.rFull,
              child: HairlineBar(item.barValue!, color: item.accentColor),
            ),
        ],
      ),
    );
  }
}

class _VitalCardData {
  final String label;
  final String value;
  final String icon;
  final double? barValue;
  final Color accentColor;

  const _VitalCardData({
    required this.label,
    required this.value,
    required this.icon,
    this.barValue,
    required this.accentColor,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dicebear_avatar.dart';
import '../widgets/modals/create_mission_modal.dart';
import '../widgets/primitives.dart';

/// Redesigned Monochrome Editorial HomeScreen.
///
/// Layout:
/// - Top greeting: "DEVPILOT", small "hello,", under it person's front name "Aryan" (no avatar), single "+" button.
/// - Launch Mission Widget: Card-like widget with watermark rocket icon.
/// - Projects Section: Horizontal scroll of cards with distinct monochrome tints. No pill shape buttons.
/// - Current Execution Section: Running agent only (no system stats).
/// - Past Executions Section: Hairline-separated rows of completed tasks.
/// - System Vitals Section: 2x2 Hairline lattice grid.
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

  static const List<Color> _cardTints = [
    Color(0xFF1A1A1A),
    Color(0xFF222222),
    Color(0xFF1E1E1E),
    Color(0xFF262626),
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
                  // 1. Top Greeting (no avatar, small hello, front name Aryan, single + button)
                  _buildGreeting(),

                  const SizedBox(height: 20),

                  // 2. Launch Mission Card Widget
                  _buildLaunchWidget(),

                  const SizedBox(height: 28),

                  // 3. Projects Section (horizontal scroll, distinct tints, no pill buttons)
                  _buildProjectsSection(projects),

                  const SizedBox(height: 28),

                  // 4. Current Execution Section (only running agent, no system stats)
                  _buildCurrentExecutionSection(),

                  const SizedBox(height: 28),

                  // 5. Past Executions Section
                  _buildPastExecutionsSection(),

                  const SizedBox(height: 28),

                  // 6. System Vitals Section (2-column hairline grid)
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
      padding: const EdgeInsets.fromLTRB(T.lg, 28, T.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DEVPILOT', style: T.eyebrowWide),
              const SizedBox(height: 4),
              Text(
                'hello,',
                style: T.displaySm.copyWith(
                  color: T.onSurfaceVar,
                  height: 1.05,
                ),
              ),
              Text(
                'Aryan',
                style: T.displayMd.copyWith(
                  height: 1.05,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          // Single action button — Launch new mission
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              CreateMissionModal.show(context, widget.service);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: T.background,
                border: Border.all(color: T.border),
              ),
              child: const Icon(Icons.add, color: T.onSurface, size: 24),
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
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(T.lg),
              decoration: BoxDecoration(
                color: T.surfaceMuted.withValues(alpha: 0.4),
                border: Border.all(color: T.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAUNCH NEW MISSION', style: T.labelUpMd),
                  const SizedBox(height: 8),
                  Text('Build something new →', style: T.headlineLg),
                  const SizedBox(height: 8),
                  Text(
                    'Configure agents, set goals, and start\nan autonomous execution.',
                    style: T.bodySm.copyWith(color: T.onSurfaceVar),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: T.onSurface,
                      borderRadius: T.zero,
                    ),
                    child: Center(
                      child: Text(
                        'START MISSION',
                        style: T.labelUpSm.copyWith(
                          color: T.background,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Watermark Icon
            Positioned(
              top: 16,
              right: 16,
              child: Icon(
                Icons.rocket_launch_outlined,
                size: 72,
                color: T.onSurface.withValues(alpha: 0.06),
              ),
            ),
          ],
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
            trailing: BadgePill('${projects.length} ACTIVE'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: T.lg),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final project = projects[i];
              final tint = _cardTints[i % _cardTints.length];
              return _buildProjectCard(project, tint);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(ProjectItem p, Color tint) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.service.selectMission(p.id);
        widget.onOpenProject(p);
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(T.md),
        decoration: BoxDecoration(
          color: tint,
          border: Border.all(color: T.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Folder icon + LIVE badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.folder_open_outlined,
                  size: 20,
                  color: T.onSurfaceVar,
                ),
                if (p.isLive) const BadgePill('LIVE'),
              ],
            ),
            // Middle: Title
            Text(
              p.title,
              style: T.headlineMd,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Bottom: Hairline progress bar + subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HairlineBar(p.progress),
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
                color: T.background,
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
          color: T.background,
          border: Border.all(color: T.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cute deterministic robot avatar (offline-first)
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
                    style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
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
                borderRadius: T.zero,
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
                style: T.labelUpXs.copyWith(color: T.onSurface),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: T.border)),
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
                                style: T.labelUpXs
                                    .copyWith(color: T.onSurfaceVar),
                              ),
                            ],
                          ),
                        ),
                        BadgePill(
                          past[i].success ? 'DONE' : 'FAILED',
                          bg: past[i].success
                              ? T.success.withValues(alpha: 0.15)
                              : T.destructive.withValues(alpha: 0.15),
                          textColor: past[i].success
                              ? T.success
                              : Colors.red.shade300,
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

  // --- 6. System Vitals Section ---
  Widget _buildSystemVitalsSection(HardwareVitals v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('SYSTEM VITALS'),
          const SizedBox(height: 12),
          HairlineGrid(
            crossAxisCount: 2,
            cells: [
              _VitalCell(
                label: 'CPU LOAD',
                value: '${v.cpuPercent.toInt()}%',
                barValue: v.cpuPercent / 100,
              ),
              _VitalCell(
                label: 'RAM USAGE',
                value: '${v.ramPercent.toInt()}%',
                barValue: v.ramPercent / 100,
              ),
              _VitalCell(
                label: 'NETWORK',
                value: '${v.networkMBps.toStringAsFixed(1)} MB/s',
              ),
              _VitalCell(
                label: 'BATTERY',
                value: '${v.batteryPercent.toInt()}%',
                barValue: v.batteryPercent / 100,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalCell extends StatelessWidget {
  final String label;
  final String value;
  final double? barValue;

  const _VitalCell({
    required this.label,
    required this.value,
    this.barValue,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(T.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: T.labelUpSm),
            const SizedBox(height: 6),
            Text(value, style: T.numeralXl),
            if (barValue != null) ...[
              const SizedBox(height: 8),
              HairlineBar(barValue!),
            ],
          ],
        ),
      );
}

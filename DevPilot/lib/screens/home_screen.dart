import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agent_card.dart';
import '../widgets/running_task_card.dart';

/// Full implementation of Image 1 Home Screen.
///
/// Features:
/// - Top Image 1 header with 4-dot matrix grid icon `::`, avatar, and greeting.
/// - Giant bold typography: "Your Projects (N)".
/// - Side-by-side / horizontally scrollable pastel workflow cards (Peach, Mint, Lavender).
/// - Current Running Task Card directly below projects (live timer, vitals bar, macro deck).
/// - Active Agent Roster section showing current personnel operations.
/// - Tactile 4-tab bottom navigation bar (Projects, Terminal, Agents, Settings).
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
  final GlobalKey _rosterSectionKey = GlobalKey();
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRoster() {
    final context = _rosterSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTabIndex = index);

    switch (index) {
      case 0:
        // Projects - scroll to top
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
        break;
      case 1:
        // Terminal drawer / screen
        widget.onOpenTerminal?.call();
        break;
      case 2:
        // Agents section
        _scrollToRoster();
        break;
      case 3:
        // Settings sheet / modal
        widget.onOpenSettings?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final projects = widget.service.projects;
            final runningTask = widget.service.currentTask;
            final vitals = widget.service.vitals;
            final agents = widget.service.agents;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Image 1 Top Header ---
                        _buildHeader(projects.length),

                        const SizedBox(height: 18),

                        // --- Image 1 Side-by-Side Pastel Workflow Cards ---
                        _buildProjectsCarousel(projects),

                        const SizedBox(height: 24),

                        // --- Running Task Card (Under Square Workflow Boxes) ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: RunningTaskCard(
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
                        ),

                        const SizedBox(height: 28),

                        // --- Active Agent Roster Section ---
                        _buildAgentRoster(agents),
                      ],
                    ),
                  ),
                ),

                // --- Bottom Navigation Bar ---
                _buildBottomNavigationBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Section 1: Header ---
  Widget _buildHeader(int projectCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Row: 4-dot matrix grid icon and avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 4-Dot Matrix Grid Icon (::)
              _buildFourDotGridIcon(),

              // User Avatar Circle
              _buildAvatar(),
            ],
          ),

          const SizedBox(height: 22),

          // Subtitle Greeting
          const Text(
            'Hello, Aryan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 4),

          // Giant Bold Title
          Text('Your Projects ($projectCount)', style: AppTheme.displayLarge),
        ],
      ),
    );
  }

  Widget _buildFourDotGridIcon() {
    return Container(
      key: const Key('header_grid_icon'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Center(
        child: SizedBox(
          width: 15,
          height: 15,
          child: Wrap(
            spacing: 3.5,
            runSpacing: 3.5,
            children: List.generate(
              4,
              (index) => Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppTheme.textDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      key: const Key('header_avatar'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.cardPeach,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderMedium, width: 1.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  // --- Section 2: Side-by-Side Pastel Workflow Cards ---
  Widget _buildProjectsCarousel(List<ProjectItem> projects) {
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 245,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final project = projects[index];
          return _WorkflowCard(
            project: project,
            onTap: () => widget.onOpenProject(project),
          );
        },
      ),
    );
  }

  // --- Section 3: Active Agent Roster ---
  Widget _buildAgentRoster(List<AgentItem> agents) {
    return Padding(
      key: _rosterSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count badge
          Row(
            children: [
              const Text('Active Agent Roster', style: AppTheme.titleLarge),
              const SizedBox(width: 8),
              Container(
                key: const Key('active_agent_roster_section'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.darkPill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${agents.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Agent Cards list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: agents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final agent = agents[index];
              return AgentCard(
                agent: agent,
                onTap: () => widget.onOpenAgent?.call(agent),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Section 4: Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: const Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavTab(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Projects',
              ),
              _buildNavTab(
                index: 1,
                icon: Icons.terminal_rounded,
                label: 'Terminal',
              ),
              _buildNavTab(
                index: 2,
                icon: Icons.group_rounded,
                label: 'Agents',
              ),
              _buildNavTab(
                index: 3,
                icon: Icons.tune_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => _handleTabSelected(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.darkPill : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Image 1 Pastel Workflow Card
class _WorkflowCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback onTap;

  const _WorkflowCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = project.backgroundColor;
    final fgColor = project.textColor;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTheme.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category icon badge & Arrow button (↗)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Badge (shopping bag, credit card, etc.)
                    _buildIconBadge(project),

                    // Top-right circular arrow button (↗)
                    _buildArrowButton(),
                  ],
                ),

                const Spacer(),

                // Title & Subtitle
                Text(
                  project.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: fgColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    project.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fgColor.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Avatar Stack + Duration Pill Row
                Row(
                  children: [
                    _buildAvatarStack(project),
                    const Spacer(),
                    _buildDurationPill(project.duration),
                  ],
                ),

                const SizedBox(height: 12),

                // Mini Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: project.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fgColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(ProjectItem project) {
    IconData icon;
    final lowerTitle = project.title.toLowerCase();
    if (lowerTitle.contains('admin') || lowerTitle.contains('dashboard')) {
      icon = Icons.shopping_bag_outlined;
    } else if (lowerTitle.contains('wallet')) {
      icon = Icons.credit_card_rounded;
    } else {
      icon = Icons.folder_open_rounded;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Icon(icon, size: 20, color: AppTheme.textDark),
    );
  }

  Widget _buildArrowButton() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow,
      ),
      child: const Icon(
        Icons.arrow_outward_rounded,
        size: 18,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildAvatarStack(ProjectItem project) {
    final initialsList = ['AT', 'DE', 'NI'];
    return SizedBox(
      height: 26,
      width: 58,
      child: Stack(
        children: [
          for (int i = 0; i < 3; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarBg(i),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initialsList[i],
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _avatarBg(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFAAEBFD);
      case 2:
      default:
        return const Color(0xFFE3C1C8);
    }
  }

  Widget _buildDurationPill(String duration) {
    if (duration.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        duration,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}

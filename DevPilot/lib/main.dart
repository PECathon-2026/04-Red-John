import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/models.dart';
import 'screens/artifact_list_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/full_terminal_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/telemetry_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/modals/agent_dossier_modal.dart';
import 'widgets/modals/approval_modal.dart';
import 'widgets/modals/cli_sheet.dart';
import 'widgets/modals/parameter_modal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final service = TelemetryService(autoStart: true);
  runApp(DevPilotApp(service: service));
}

/// Root widget for the DevPilot application.
class DevPilotApp extends StatefulWidget {
  final TelemetryService? service;
  final bool showOnboarding;
  final bool showAuth;

  const DevPilotApp({
    super.key,
    this.service,
    this.showOnboarding = false,
    this.showAuth = false,
  });

  @override
  State<DevPilotApp> createState() => _DevPilotAppState();
}

class _DevPilotAppState extends State<DevPilotApp> {
  late final TelemetryService _service;
  late final bool _ownsService;
  late bool _onboardingActive;
  late bool _authActive;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isApprovalDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _onboardingActive = widget.showOnboarding;
    _authActive = widget.showAuth;
    if (widget.service != null) {
      _service = widget.service!;
      _ownsService = false;
    } else {
      _service = TelemetryService(autoStart: true);
      _ownsService = true;
    }
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    if (_ownsService) {
      _service.dispose();
    }
    super.dispose();
  }

  void _onServiceUpdate() {
    if (_service.isPendingApproval && !_isApprovalDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _service.isPendingApproval && !_isApprovalDialogOpen) {
          _handleApprovalGate();
        }
      });
    }
  }

  Future<void> _handleApprovalGate([BuildContext? context]) async {
    if (_isApprovalDialogOpen) return;
    final targetContext = context ?? _navigatorKey.currentContext;
    if (targetContext == null) return;

    _isApprovalDialogOpen = true;

    final title = _service.pendingActionTitle ?? 'Kill All Processes';
    final details =
        _service.pendingActionDetails ??
        'Terminates all active worker threads, agent sandboxes, and build pipelines immediately. Requires biometric verification.';

    try {
      final approved = await ApprovalModal.show(
        targetContext,
        actionTitle: title,
        details: details,
        riskLevel: 'AMBER',
      );

      if (approved == true) {
        _service.approvePendingGate();
      } else {
        _service.denyPendingGate();
      }
    } finally {
      _isApprovalDialogOpen = false;
    }
  }

  void _navigateToDetail(BuildContext context, ProjectItem project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DetailScreen(
          service: _service,
          project: project,
          onBack: () => Navigator.of(ctx).pop(),
          onOpenCli: () => CliSheet.show(ctx, _service),
          onOpenSettings: () => ParameterModal.show(ctx, _service),
          onOpenAgent: (agent) => AgentDossierModal.show(ctx, agent: agent),
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    if (_onboardingActive) {
      return OnboardingScreen(
        onFinish: () => setState(() {
          _onboardingActive = false;
          _authActive = false;
        }),
        onNavigateToLogin: () => setState(() {
          _onboardingActive = false;
          _authActive = true;
        }),
      );
    }
    if (_authActive) {
      return AuthScreen(
        onSuccess: () => setState(() => _authActive = false),
        onBack: () => setState(() {
          _authActive = false;
          _onboardingActive = true;
        }),
      );
    }
    return _MainShell(
      service: _service,
      onOpenProject: (project) {
        final ctx = _navigatorKey.currentContext ?? context;
        _navigateToDetail(ctx, project);
      },
      onOpenAgent: (agent) {
        final ctx = _navigatorKey.currentContext ?? context;
        AgentDossierModal.show(ctx, agent: agent);
      },
      onKillTriggered: () {
        final ctx = _navigatorKey.currentContext ?? context;
        _handleApprovalGate(ctx);
      },
      onOpenOnboarding: () => setState(() => _onboardingActive = true),
      onOpenAuth: () => setState(() => _authActive = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevPilot',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: T.theme,
      home: _buildHome(context),
    );
  }
}

/// Architectural container hosting the 5-item bottom navigation bar and primary screens.
class _MainShell extends StatefulWidget {
  final TelemetryService service;
  final void Function(ProjectItem) onOpenProject;
  final void Function(AgentItem) onOpenAgent;
  final VoidCallback onKillTriggered;
  final VoidCallback? onOpenOnboarding;
  final VoidCallback? onOpenAuth;

  const _MainShell({
    required this.service,
    required this.onOpenProject,
    required this.onOpenAgent,
    required this.onKillTriggered,
    this.onOpenOnboarding,
    this.onOpenAuth,
  });

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentTabIndex = 0;

  void _onTabSelected(int index) {
    if (index == 4) {
      // SETTINGS tab opens ParameterModal bottom sheet
      ParameterModal.show(context, widget.service);
      return;
    }
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.background,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Home Screen
          HomeScreen(
            service: widget.service,
            onOpenProject: widget.onOpenProject,
            onOpenAgent: widget.onOpenAgent,
            onOpenTerminal: () => setState(() => _currentTabIndex = 2),
            onOpenSettings: () => ParameterModal.show(context, widget.service),
            onKillTriggered: widget.onKillTriggered,
          ),
          // Tab 1: Projects Overview
          widget.service.projects.isNotEmpty
              ? DetailScreen(
                  service: widget.service,
                  project: widget.service.projects.first,
                  onBack: () => setState(() => _currentTabIndex = 0),
                  onOpenCli: () => setState(() => _currentTabIndex = 2),
                  onOpenSettings: () => ParameterModal.show(context, widget.service),
                  onOpenAgent: widget.onOpenAgent,
                )
              : const Center(
                  child: Text('No active projects', style: TextStyle(color: T.onSurface)),
                ),
          // Tab 2: Terminal Screen
          FullTerminalScreen(
            service: widget.service,
            onBack: () => setState(() => _currentTabIndex = 0),
          ),
          // Tab 3: Artifacts Screen
          ArtifactListScreen(
            artifacts: widget.service.artifacts,
            service: widget.service,
            onBack: () => setState(() => _currentTabIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentTabIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

typedef MyApp = DevPilotApp;

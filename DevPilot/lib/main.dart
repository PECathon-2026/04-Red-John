import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/models.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'services/telemetry_service.dart';
import 'theme/app_theme.dart';
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

  const DevPilotApp({super.key, this.service});

  @override
  State<DevPilotApp> createState() => _DevPilotAppState();
}

class _DevPilotAppState extends State<DevPilotApp> {
  late final TelemetryService _service;
  late final bool _ownsService;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isApprovalDialogOpen = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevPilot',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: Builder(
        builder: (context) => HomeScreen(
          service: _service,
          onOpenProject: (project) => _navigateToDetail(context, project),
          onOpenAgent: (agent) => AgentDossierModal.show(context, agent: agent),
          onOpenTerminal: () => CliSheet.show(context, _service),
          onOpenSettings: () => ParameterModal.show(context, _service),
          onKillTriggered: () => _handleApprovalGate(context),
        ),
      ),
    );
  }
}

typedef MyApp = DevPilotApp;

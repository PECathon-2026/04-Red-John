import 'package:flutter_test/flutter_test.dart';
import 'package:devpilot/services/telemetry_service.dart';
import 'package:devpilot/models/models.dart';

void main() {
  group('TelemetryService Initialization', () {
    test('TelemetryService initializes with mock agents and vitals', () {
      final service = TelemetryService(autoStart: false);
      expect(service.agents.isNotEmpty, true);
      expect(service.vitals.cpuPercent, inInclusiveRange(0, 100));
      expect(service.goals.isNotEmpty, true);
      expect(service.logs.isNotEmpty, true);
      expect(service.artifacts.isNotEmpty, true);
      expect(service.projects.isNotEmpty, true);
      expect(service.currentTask.taskName.isNotEmpty, true);
      expect(service.currentTask.phase, TaskPhase.running);
      expect(service.isPendingApproval, false);
      expect(service.workerThreads, 8);
      expect(service.isVerbose, false);
      expect(service.isLANConnected, true);
    });
  });

  group('CLI and Terminal Logging', () {
    test('sendCliCommand appends input and simulated response to logs', () {
      final service = TelemetryService(autoStart: false);
      final initialCount = service.logs.length;
      service.sendCliCommand('flutter doctor');
      expect(service.logs.length, greaterThan(initialCount));
      expect(service.logs.last.message, contains('Doctor summary'));
    });

    test('sendCliCommand handles git status, docker ps, and arbitrary commands', () {
      final service = TelemetryService(autoStart: false);
      service.sendCliCommand('git status');
      expect(service.logs.last.message, contains('On branch main'));

      service.sendCliCommand('docker ps');
      expect(service.logs.last.message, contains('devpilot-telemetry'));

      service.sendCliCommand('whoami');
      expect(service.logs.last.message, contains('devpilot-operator'));
    });

    test('clearLogs empties terminal log feed', () {
      final service = TelemetryService(autoStart: false);
      expect(service.logs.isNotEmpty, true);
      service.clearLogs();
      expect(service.logs.isEmpty, true);
    });
  });

  group('Interactive Actions and Security Approval Gates', () {
    test('triggerAction for Kill All sets pending approval state', () {
      final service = TelemetryService(autoStart: false);
      expect(service.isPendingApproval, false);

      service.triggerAction('Kill All');
      expect(service.isPendingApproval, true);
      expect(service.pendingActionTitle, contains('Kill'));
      expect(service.pendingActionDetails, isNotNull);
    });

    test('approvePendingGate resolves gate and logs approval', () {
      final service = TelemetryService(autoStart: false);
      service.triggerAction('Kill All');
      expect(service.isPendingApproval, true);

      service.approvePendingGate();
      expect(service.isPendingApproval, false);
      expect(service.pendingActionTitle, isNull);
      expect(service.currentTask.phase, TaskPhase.idle);
      expect(service.logs.any((l) => l.message.contains('APPROVED')), isTrue);
    });

    test('denyPendingGate resolves gate and logs denial', () {
      final service = TelemetryService(autoStart: false);
      service.triggerAction('Kill All');
      expect(service.isPendingApproval, true);

      service.denyPendingGate();
      expect(service.isPendingApproval, false);
      expect(service.pendingActionTitle, isNull);
      expect(service.logs.last.message, contains('DENIED'));
    });

    test('triggerAction for non-destructive macros executes directly', () {
      final service = TelemetryService(autoStart: false);
      service.triggerAction('Run Tests');
      expect(service.isPendingApproval, false);
      expect(service.logs.any((l) => l.message.contains('Run Tests')), isTrue);

      service.triggerAction('Deploy App');
      expect(service.isPendingApproval, false);
      expect(service.logs.any((l) => l.message.contains('Deploy App')), isTrue);
    });
  });

  group('Parameters and Toggles', () {
    test('updateThreads and toggleVerbose update state and notify listeners', () {
      final service = TelemetryService(autoStart: false);
      var notifyCount = 0;
      service.addListener(() => notifyCount++);

      service.updateThreads(12);
      expect(service.workerThreads, 12);
      expect(notifyCount, 1);

      service.toggleVerbose(true);
      expect(service.isVerbose, true);
      expect(notifyCount, 2);

      service.toggleLAN(false);
      expect(service.isLANConnected, false);
      expect(notifyCount, 3);
    });
  });

  group('Simulation & Timer lifecycle', () {
    test('manual tick updates vitals and elapsed string', () {
      final service = TelemetryService(autoStart: false);
      service.simulateTick();
      expect(service.vitals.cpuPercent, inInclusiveRange(20, 85));
      expect(service.currentTask.elapsedString, startsWith('T+'));
    });

    test('dispose cleans up active timers without throwing', () {
      final service = TelemetryService(autoStart: true);
      expect(() => service.dispose(), returnsNormally);
    });
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Exception thrown when a backend API request fails.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// End-to-end HTTP and WebSocket API client for DevPilot `backend_main`.
///
/// Fully maps to FastAPI routes in `backend_main/app/api/v1/router.py`:
/// - Health (`/health/live`, `/health/ready`)
/// - Missions (`/missions`, `/missions/{id}`, `/missions/{id}/snapshot`, `/missions/{id}/patch`, `/missions/{id}/apply`, `/missions/{id}/run`, `/missions/{id}/stop`)
/// - Governance (`/missions/{id}/approvals`, `/approvals/{id}/respond`, `/missions/{id}/audit`)
/// - Guild & Agents (`/agents`, `/missions/{id}/hires`)
/// - Tools (`/tools`)
/// - Issues & Clarifications (`/missions/{id}/issues/{id}/resolve`)
/// - Realtime WebSocket (`/realtime/missions/{id}`)
class DevPilotApiClient {
  String _baseUrl;
  final http.Client _httpClient;
  final WebSocketChannel Function(Uri uri)? webSocketFactory;

  DevPilotApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.webSocketFactory,
  })  : _baseUrl = baseUrl ?? defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  /// Default host auto-detects Android emulator (10.0.2.2) vs iOS / Desktop (127.0.0.1).
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    _baseUrl = clean;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl/api/v1$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (query != null && query.isNotEmpty) {
      final queryParams = query.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // --- Health Endpoints ---

  /// Checks server readiness: storage, event bus, and LLM routes.
  Future<Map<String, dynamic>> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/api/v1/health/ready');
    final response = await _httpClient.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Health check failed: ${response.body}',
    );
  }

  // --- Mission Endpoints ---

  /// List all missions (`GET /api/v1/missions`).
  Future<List<Map<String, dynamic>>> listMissions({
    String? status,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (status != null) query['status'] = status;

    final uri = _uri('/missions', query);
    final response = await _httpClient.get(uri);
    final data = _handleJson(response);
    final list = data['missions'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Create a new mission (`POST /api/v1/missions`).
  Future<Map<String, dynamic>> createMission({
    required String request,
    required String repoPath,
    String? title,
    bool start = true,
  }) async {
    final uri = _uri('/missions');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'request': request,
        'repo_path': repoPath,
        'title': ?title,
        'start': start,
      }),
    );
    return _handleJson(response);
  }

  /// Get mission details (`GET /api/v1/missions/{id}`).
  Future<Map<String, dynamic>> getMission(String missionId) async {
    final uri = _uri('/missions/$missionId');
    final response = await _httpClient.get(uri);
    return _handleJson(response);
  }

  /// Get aggregated mission snapshot for UI cold-start (`GET /api/v1/missions/{id}/snapshot`).
  Future<Map<String, dynamic>> getMissionSnapshot(String missionId) async {
    final uri = _uri('/missions/$missionId/snapshot');
    final response = await _httpClient.get(uri);
    return _handleJson(response);
  }

  /// Start or resume mission execution (`POST /api/v1/missions/{id}/run`).
  Future<Map<String, dynamic>> runMission(String missionId) async {
    final uri = _uri('/missions/$missionId/run');
    final response = await _httpClient.post(uri);
    return _handleJson(response);
  }

  /// Gracefully stop a running mission (`POST /api/v1/missions/{id}/stop`).
  Future<Map<String, dynamic>> stopMission(
    String missionId, {
    String reason = 'stopped by operator',
  }) async {
    final uri = _uri('/missions/$missionId/stop');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    );
    return _handleJson(response);
  }

  /// Fetch full unified git diff patch (`GET /api/v1/missions/{id}/patch`).
  Future<String> getMissionPatch(String missionId) async {
    final uri = _uri('/missions/$missionId/patch');
    final response = await _httpClient.get(uri);
    if (response.statusCode == 200) {
      return response.body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Failed to fetch patch: ${response.body}',
    );
  }

  /// Request applying mission changes to the target repository (`POST /api/v1/missions/{id}/apply`).
  Future<Map<String, dynamic>> applyMissionChanges(String missionId) async {
    final uri = _uri('/missions/$missionId/apply');
    final response = await _httpClient.post(uri);
    return _handleJson(response);
  }

  // --- Governance & Human Approval Endpoints ---

  /// List approvals for a mission (`GET /api/v1/missions/{id}/approvals`).
  Future<List<Map<String, dynamic>>> listApprovals(
    String missionId, {
    String? status,
  }) async {
    final query = status != null ? {'status': status} : null;
    final uri = _uri('/missions/$missionId/approvals', query);
    final response = await _httpClient.get(uri);
    final data = _handleJson(response);
    final list = data['approvals'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Respond to an AMBER approval request (`POST /api/v1/approvals/{id}/respond`).
  Future<Map<String, dynamic>> respondToApproval({
    required String approvalId,
    required bool approved,
    String? note,
  }) async {
    final uri = _uri('/approvals/$approvalId/respond');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'approved': approved,
        'note': ?note,
      }),
    );
    return _handleJson(response);
  }

  /// Resolve an open issue / clarification question (`POST /api/v1/missions/{id}/issues/{id}/resolve`).
  Future<Map<String, dynamic>> resolveIssue({
    required String missionId,
    required String issueId,
    required String resolution,
  }) async {
    final uri = _uri('/missions/$missionId/issues/$issueId/resolve');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'resolution': resolution}),
    );
    return _handleJson(response);
  }

  /// Get tamper-evident governance audit trail (`GET /api/v1/missions/{id}/audit`).
  Future<Map<String, dynamic>> getAuditTrail(
    String missionId, {
    String? agent,
    int limit = 500,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (agent != null) query['agent'] = agent;

    final uri = _uri('/missions/$missionId/audit', query);
    final response = await _httpClient.get(uri);
    return _handleJson(response);
  }

  // --- Guild & Agents Endpoints ---

  /// Get the full 16-agent guild roster (`GET /api/v1/agents`).
  Future<List<Map<String, dynamic>>> getGuildRoster() async {
    final uri = _uri('/agents');
    final response = await _httpClient.get(uri);
    final data = _handleJson(response);
    final list = data['agents'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Get hired personnel on a mission (`GET /api/v1/missions/{id}/hires`).
  Future<Map<String, dynamic>> getMissionHires(String missionId) async {
    final uri = _uri('/missions/$missionId/hires');
    final response = await _httpClient.get(uri);
    return _handleJson(response);
  }

  /// Manually summon a specialist agent (`POST /api/v1/missions/{id}/hires`).
  Future<Map<String, dynamic>> hireSpecialist({
    required String missionId,
    required List<String> skills,
    required String reason,
  }) async {
    final uri = _uri('/missions/$missionId/hires');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'skills': skills, 'reason': reason}),
    );
    return _handleJson(response);
  }

  // --- Evidence & Tools ---

  /// Get verifiable evidence items (`GET /api/v1/missions/{id}/evidence`).
  Future<List<Map<String, dynamic>>> getEvidence(
    String missionId, {
    String? kind,
    String? taskId,
  }) async {
    final query = <String, dynamic>{};
    if (kind != null) query['kind'] = kind;
    if (taskId != null) query['task_id'] = taskId;

    final uri = _uri('/missions/$missionId/evidence', query);
    final response = await _httpClient.get(uri);
    final data = _handleJson(response);
    final list = data['evidence'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// List available tools catalogue (`GET /api/v1/tools`).
  Future<List<Map<String, dynamic>>> getToolCatalogue() async {
    final uri = _uri('/tools');
    final response = await _httpClient.get(uri);
    final data = _handleJson(response);
    final list = data['tools'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  // --- Real-time WebSocket Streaming ---

  /// Connect to the WebSocket event stream (`WS /api/v1/realtime/missions/{id}?after_seq={seq}`).
  WebSocketChannel connectRealtimeStream(
    String missionId, {
    int afterSeq = 0,
  }) {
    final wsBase = _baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    final query = afterSeq > 0 ? '?after_seq=$afterSeq' : '';
    final wsUri = Uri.parse('$wsBase/api/v1/realtime/missions/$missionId$query');
    final factory = webSocketFactory;
    if (factory != null) {
      return factory(wsUri);
    }
    return WebSocketChannel.connect(wsUri);
  }

  // --- Private Helpers ---

  Map<String, dynamic> _handleJson(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  void close() {
    _httpClient.close();
  }
}

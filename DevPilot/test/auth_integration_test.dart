import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:devpilot/screens/auth_screen.dart';
import 'package:devpilot/services/api_client.dart';
import 'package:devpilot/services/telemetry_service.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

/// A fake backend_main with auth on: one user, token `tok-1`.
http.Response _fakeBackend(http.Request request) {
  final path = request.url.path;
  final authed = request.headers['Authorization'] == 'Bearer tok-1';
  if (path == '/api/v1/health/ready') {
    return http.Response(jsonEncode({'status': 'ok', 'checks': {'storage': true, 'event_bus': true}}), 200,
        headers: _json);
  }
  if (path == '/api/v1/auth/login') {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    if (body['username'] == 'ops' && body['password'] == 'correct-horse') {
      return http.Response(
          jsonEncode({
            'access_token': 'tok-1',
            'token_type': 'bearer',
            'user': {'user_id': 'u1', 'username': 'ops', 'role': 'approver'},
          }),
          200,
          headers: _json);
    }
    return http.Response(jsonEncode({'error': {'code': 'unauthenticated', 'message': 'Invalid credentials'}}), 401,
        headers: _json);
  }
  if (!authed) {
    return http.Response(jsonEncode({'error': {'code': 'unauthenticated', 'message': 'Sign in to use DevPilot'}}), 401,
        headers: _json);
  }
  if (path == '/api/v1/auth/me') {
    return http.Response(jsonEncode({'user_id': 'u1', 'username': 'ops', 'role': 'approver'}), 200, headers: _json);
  }
  if (path == '/api/v1/missions') {
    return http.Response(jsonEncode({'missions': []}), 200, headers: _json);
  }
  return http.Response('{}', 200, headers: _json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('login stores the token and sends it as a bearer header', () async {
    final seen = <String?>[];
    final api = DevPilotApiClient(
      baseUrl: 'http://127.0.0.1:8000',
      httpClient: MockClient((r) async {
        seen.add(r.headers['Authorization']);
        return _fakeBackend(r);
      }),
    );

    final user = await api.login('ops', 'correct-horse');
    expect(user['username'], 'ops');
    expect(api.token, 'tok-1');

    await api.listMissions();
    expect(seen.last, 'Bearer tok-1');
  });

  test('backend error envelopes become readable ApiException messages', () async {
    final api = DevPilotApiClient(httpClient: MockClient((r) async => _fakeBackend(r)));
    await expectLater(
      api.listMissions(),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)
          .having((e) => e.message, 'message', 'Sign in to use DevPilot')),
    );
  });

  test('WebSocket URL carries the token', () {
    Uri? captured;
    final api = DevPilotApiClient(
      baseUrl: 'http://10.0.2.2:8000',
      webSocketFactory: (uri) {
        captured = uri;
        throw StateError('not connecting in tests');
      },
    );
    api.setToken('tok-1');
    expect(() => api.connectRealtimeStream('m-1', afterSeq: 7), throwsStateError);
    expect(captured.toString(), 'ws://10.0.2.2:8000/api/v1/realtime/missions/m-1?after_seq=7&token=tok-1');
  });

  test('a 401 flags sign-in; signing in clears it, persists the token, and signing out forgets it', () async {
    final service = TelemetryService(
      autoStart: false,
      client: DevPilotApiClient(httpClient: MockClient((r) async => _fakeBackend(r))),
    );

    await service.refreshFromBackend();
    expect(service.authRequired, isTrue);

    expect(await service.signIn('ops', 'wrong'), 'Wrong username or password');
    expect(service.authRequired, isTrue);

    expect(await service.signIn('ops', 'correct-horse'), isNull);
    expect(service.authRequired, isFalse);
    expect(service.username, 'ops');
    expect(service.role, 'approver');
    expect((await SharedPreferences.getInstance()).getString('devpilot_access_token'), 'tok-1');

    await service.signOut();
    expect(service.authRequired, isTrue);
    expect(service.apiClient.hasToken, isFalse);
    expect((await SharedPreferences.getInstance()).getString('devpilot_access_token'), isNull);
    service.dispose();
  });

  test('restoreSession reloads the saved token and server URL', () async {
    SharedPreferences.setMockInitialValues({
      'devpilot_access_token': 'tok-1',
      'devpilot_backend_url': 'http://192.168.1.20:8000',
    });
    final service = TelemetryService(
      autoStart: false,
      client: DevPilotApiClient(httpClient: MockClient((r) async => _fakeBackend(r))),
    );
    await service.restoreSession();
    expect(service.apiClient.baseUrl, 'http://192.168.1.20:8000');

    await service.refreshFromBackend();
    expect(service.authRequired, isFalse);
    expect(service.username, 'ops');
    service.dispose();
  });

  testWidgets('AuthScreen signs in through the backend and shows errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var success = false;
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(
        onSuccess: () => success = true,
        onSignIn: (u, p) async => p == 'correct-horse' ? null : 'Wrong username or password',
        backendUrl: 'http://127.0.0.1:8000',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('Server: http://127.0.0.1:8000'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ops');
    await tester.enterText(fields.at(1), 'nope');
    await tester.tap(find.text('SIGN IN TO CONSOLE'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong username or password'), findsOneWidget);
    expect(success, isFalse);

    await tester.enterText(fields.at(1), 'correct-horse');
    await tester.tap(find.text('SIGN IN TO CONSOLE'));
    await tester.pumpAndSettle();
    expect(success, isTrue);
  });
}

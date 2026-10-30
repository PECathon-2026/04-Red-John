# DevPilot mobile

Flutter client for the DevPilot backend (`backend_main`). It talks to the same
API as the web control room (`frontend_main`): the same accounts, missions,
approvals and live event stream, so a mission started on the web shows up here
and an approval answered on the phone clears on the web.

## Run against the backend

1. Start the backend so the phone can reach it:

   ```bash
   cd backend_main
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

   With auth on (the default), create the first admin with
   `BOOTSTRAP_ADMIN_PASSWORD` in `backend_main/.env`. Admins add more users
   via `POST /api/v1/auth/users`.

2. Run the app:

   ```bash
   flutter run
   ```

   The default server is `http://10.0.2.2:8000` on the Android emulator and
   `http://127.0.0.1:8000` elsewhere. On a physical phone, open Settings →
   LAN Host Gateway and enter your computer's LAN IP (e.g. `192.168.1.20`).
   The URL is remembered between launches.

3. Sign in with the same username and password you use on the web. The token
   is saved on the device; Settings → Sign out clears it. If the backend runs
   with `AUTH_ENABLED=false`, no sign-in is asked for.

"Explore in Demo Mode" skips sign-in and shows sample data offline.

## How it maps to the API

- `lib/services/api_client.dart`: HTTP + WebSocket client for `/api/v1`
  (bearer token on every request, `?token=` on the WebSocket).
- `lib/services/telemetry_service.dart`: app state; loads `/missions` and
  `/missions/{id}/snapshot`, follows `/realtime/missions/{id}`, and shows the
  sign-in screen whenever the backend answers 401.
- `lib/services/session_store.dart`: saved token and server URL.

## Tests

```bash
flutter test
```

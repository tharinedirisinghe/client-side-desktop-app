# Client Side Desktop App

Flutter desktop client for exam/assignment display and control. The app connects to a backend over WebSocket, receives activation/deactivation/timer events, fetches exam and student details through REST APIs, and renders information on a large-screen dashboard UI.

## Screenshots

![Screenshot 2024-07-09 213927](https://github.com/tharinedirisinghe/client-side-desktop-app/assets/136303928/b05590ee-1521-441d-bc55-182c8d82495c)

![Screenshot 2024-07-09 214005](https://github.com/tharinedirisinghe/client-side-desktop-app/assets/136303928/8bd6ddab-27c5-4a2d-8df7-0e614550fdf4)

## Features

- Desktop-oriented layout with a left announcements panel and center student/timer cards.
- Persistent device identity: prompts once for PC name and saves it locally.
- Real-time backend communication over WebSocket.
- Activation flow to load live exam + student data from REST endpoints.
- Deactivation flow to reset the UI to sample values.
- Live timer updates from backend (`seconds -> HH:MM:SS`).

## Tech Stack

- Flutter (Dart SDK >= 3.4.3 < 4.0.0)
- [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) for WebSocket communication
- [`http`](https://pub.dev/packages/http) for REST API calls
- [`path_provider`](https://pub.dev/packages/path_provider) for local file storage (`pc_name.txt`)

## Project Structure

- Main application entry and UI logic: `lib/main.dart`
- App icon/logo asset: `assets/itfac-logo.png`
- Flutter configuration and dependencies: `pubspec.yaml`

## Runtime Behavior

### 1) First launch

- If no saved PC name exists, a dialog asks the user to enter one.
- Value is saved to application documents directory as `pc_name.txt`.

### 2) WebSocket connection

- App connects to:
	- `ws://bcca-112-135-76-91.ngrok-free.app`
- Immediately sends the saved/entered PC name to backend.

### 3) Incoming socket messages

- `activate,<studentIndex>,<examId>`
	- Sends `activate_received`
	- Fetches exam details from `/api/v1/exams/{examId}`
	- Fetches student details from `/api/v1/students/{studentIndex}`
- `deactivate`
	- Resets screen data to sample placeholders
	- Sends `deactivate_received`
- `timer,<seconds>`
	- Updates countdown text in `HH:MM:SS`
	- Sends `timer_received`

## API Endpoints Used

- `GET https://bcca-112-135-76-91.ngrok-free.app/api/v1/exams/{examId}`
- `GET https://bcca-112-135-76-91.ngrok-free.app/api/v1/students/{studentId}`

The current implementation sends these headers:

- `Content-Type: application/json`
- `Authorization: Bearer "ngrok-skip-browser-warning": "69420"`

## Prerequisites

- Flutter SDK installed and available in `PATH`
- A desktop target enabled (Windows, macOS, or Linux)

Check setup:

```bash
flutter doctor
```

## Getting Started

1. Clone the repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Run on your desktop platform:

```bash
flutter run -d windows
```

Use `macos` or `linux` target instead if needed.

## Build

### Windows

```bash
flutter build windows
```

### macOS

```bash
flutter build macos
```

### Linux

```bash
flutter build linux
```

## Development Notes

- This code currently keeps backend URLs and auth-related header values hardcoded in `lib/main.dart`.
- Consider moving environment-specific settings to a config layer (for example, compile-time defines via `--dart-define`) for safer deployments.

## Troubleshooting

- If the app cannot connect, verify the WebSocket host is reachable and still active.
- If data is not displayed after activation, check backend API responses for the provided IDs.
- If the PC name prompt appears repeatedly, ensure app has permission to write to its documents directory.

## License

No license file is currently defined in this repository.


# Nocturne

Nocturne is an early SwiftUI customization workspace for iOS 27-era devices. The first milestone is a non-jailbroken, sandbox-safe module manager.

## Platform boundary

An ordinary iOS app cannot install system-wide tweaks, inject code into SpringBoard or other apps, write to protected system locations, or gain privileged access from a proof-of-concept vulnerability. This project therefore focuses on modules that Nocturne interprets inside its own app: appearance presets, dashboard features, and declarative configuration. Module metadata is data, not executable payload.

## Build

Open the generated `Nocturne.xcodeproj` in Xcode, or run:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Nocturne.xcodeproj -scheme Nocturne -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The GitHub Actions workflow performs this build on every push and pull request and uploads the simulator app bundle as an artifact. A simulator build is not an installable signed IPA; device distribution requires signing with an Apple development/distribution identity.

## Current functionality

- Four persistent, live UI palettes: Midnight, Amethyst, Graphite, and OLED Black.
- Installable appearance modules that apply their declared palette when enabled.
- Module discovery, category filtering, and text search.
- Install, enable, disable, and remove operations persisted in the app's Application Support directory.
- JSON manifest import with file-size, field-length, identifier, and capability validation.

These are app-local features; they do not change SpringBoard, icons on the Home Screen, or other applications.

## Module manifests

Nocturne can import JSON module manifests. Example:

```json
{
  "id": "com.example.focus-pack",
  "name": "Focus Pack",
  "version": "1.0.0",
  "author": "Example",
  "description": "A sample in-app configuration pack.",
  "category": "Productivity",
  "capabilities": ["dashboard-widget", "theme-preset"]
}
```

Capabilities are descriptive and do not grant operating-system privileges.

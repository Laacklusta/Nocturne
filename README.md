# Nocturne

Nocturne is an early iOS 27 customization utility for non-jailbroken devices. It is being developed around real, user-approved iOS configuration mechanisms rather than pretending to provide jailbreak-style code injection.

## What works now

- **Tweak Center:** builds an Apple configuration profile containing a Home Screen Web Clip.
- Configure the shortcut's display name, destination URL, and standalone/full-screen launch behavior.
- Export the `.mobileconfig` file through the iOS share sheet. The user must open it and approve installation in Settings.
- The existing module browser, installation state, JSON manifest import, and in-app palettes remain available as separate app-local features.

## Important platform limits

A normal App Store-style iOS app cannot inject code into SpringBoard or other apps, replace arbitrary app icons, write to protected system locations, or silently install configuration profiles. Nocturne does not claim to do those things.

A Web Clip is a real iOS-supported Home Screen shortcut to a website. It is not a native app icon replacement and does not modify SpringBoard. Profile installation is always a user action.

## Build

Open the generated `Nocturne.xcodeproj` in Xcode, or run:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Nocturne.xcodeproj -scheme Nocturne -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions is configured to build the iOS Simulator target. A simulator build is not an installable signed IPA; device distribution requires signing with an Apple development/distribution identity.

## Next supported extension points

- Additional manually installable configuration-profile payloads, only where Apple supports them on the target OS.
- Shortcuts setup flows that the user explicitly authorizes.
- Real WidgetKit and app-extension targets.
- Safari Web Extensions and content blockers, installed and enabled through Apple's supported extension flow.

Nocturne will not execute arbitrary downloaded binaries or use memory-corruption exploits as a privilege escalation mechanism.

## Security research

The Research tab summarizes the public SKVLENT iOS 27 research on CVE-2026-112611, including its demonstrated userland primitives, explicit limitations, and the iOS 27.2 fix boundary. It is informational only: Nocturne does not execute the proof of concept, attempt kernel access, or perform privilege escalation. The version comparison is advisory and does not establish device exploitability.

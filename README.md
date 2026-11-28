# Nocturne

Nocturne is a dark, jailbreak-inspired **UI simulator** for iOS. It demonstrates a staged progress flow, a simulated respring screen, and a sample package catalog.

## What it does

- Presents an interactive jailbreak-style dashboard.
- Runs a timed, explicitly simulated workflow with a local activity log.
- Shows a fake respring animation that returns to the app; it does not reboot iOS or restart SpringBoard.
- Includes a sample package browser and a companion App Clip target.

## What it does not do

Nocturne does not jailbreak devices, exploit vulnerabilities, obtain elevated privileges, install packages, modify system files, or claim compatibility with any jailbreak. Device information is read locally for display only. All progress and package entries are simulated.

## Build

Requires Xcode and XcodeGen:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Nocturne.xcodeproj -scheme Nocturne -sdk iphoneos -configuration Release CODE_SIGNING_ALLOWED=NO build
```

The App Clip is a build target, not a distributable App Clip experience yet. Public invocation requires an associated domain, matching App IDs and provisioning, and App Store Connect configuration.

## Inspiration and attribution

The interface takes general inspiration from the visual conventions of the iOS jailbreak ecosystem. It is not affiliated with or endorsed by Dopamine, Sileo, or Zebra.

The public [Dopamine repository](https://github.com/opa334/Dopamine) is MIT-licensed. Its current Swift files are low-level tooling rather than a SwiftUI front end, so no Dopamine Swift source was transplanted into this project. See the upstream repository for its license and notices.

## License

Nocturne project code: MIT.

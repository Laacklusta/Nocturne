# Nocturne

Nocturne is an iOS customization and security-research project with **iOS 27.0 as its primary research target**. The app is being structured so compatibility can be tracked across other supported iOS releases without treating a version match as proof of exploitability.

## Current project status

- SwiftUI application shell with dashboard, module browser, installed-module list, settings, and research pages.
- Local JSON module manifests with an explicit capability allowlist. Modules currently affect Nocturne itself; they are not system tweak packages.
- Tweak Center can generate a user-installable configuration profile containing a Home Screen Web Clip.
- Research page tracks the public CVE-2026-112611 claims and distinguishes reported primitives from capabilities that have not been demonstrated.
- iOS version reporting is advisory. The app does not yet identify exact build/hardware applicability or provide a jailbreak backend.

## iOS 27 compatibility track

| iOS version | Nocturne research status |
| --- | --- |
| 27.0 / 27.0.1 | Primary research target / reported pre-fix range |
| 27.1.x | Reported pre-fix range; exact build must be verified |
| 27.2 and later | Reported CVE-2026-112611 fix boundary |
| iOS 17–26 | App deployment target; this specific CVE research does not assess these releases |

The CVE-2026-112611 research identifies iOS 27.2 as the fix boundary. Earlier versions should be treated as a reported affected range, not as confirmed exploitable builds. Hardware, exact build, mitigations, and reachability all matter.

## Research status: CVE-2026-112611

The public SKVLENT material describes a constrained PDF-selected 4-byte zero write and heap corruption in a CoreGraphics shading path, with privileged userland reachability through QuickLook's CGPDFService process.

The cited work does **not** demonstrate a general arbitrary read/write primitive, kernel read/write, code execution, a complete privilege-escalation chain, or a working jailbreak. Nocturne currently records this research; it does not run the proof of concept or attempt kernel memory access.

References:
- [SKVLENT · CVE-2026-112611](https://github.com/SKVLENT/CVE-2026-112611)
- [SKVLENT · iOS 27 Research Exploits](https://github.com/SKVLENT/iOS27-Research-Exploits)
- [Apple · iOS 27.2 security content](https://support.apple.com/HT149230)

## Architecture direction

Nocturne separates three concerns:

1. **Core app:** UI, module metadata, device/version reporting, settings, and diagnostics.
2. **Environment adapters:** integration points for supported jailbreak/package environments. Each adapter must declare its supported iOS builds, architecture, package layout, permissions, and capabilities.
3. **Research catalog:** vulnerability references, affected/fixed build notes, evidence status, and reproducibility metadata. Experimental work remains separate from production tweak functionality.

A module manifest is not executable code and does not grant privileges. Nocturne will not silently install profiles, execute arbitrary downloaded binaries, or present unverified exploit claims as working features.

## Build

Open the generated `Nocturne.xcodeproj` in Xcode, or run:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Nocturne.xcodeproj -scheme Nocturne -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions builds the iOS Simulator target. A simulator build is not an installable signed IPA; device distribution requires signing with an Apple development/distribution identity.

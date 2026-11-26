# Security model

Nocturne is designed for non-jailbroken iOS. It uses documented user-facing platform mechanisms and does not attempt to bypass the iOS application sandbox.

## Configuration profiles

- The current Tweak Center generates a data-only Apple configuration profile with a `com.apple.webClip.managed` payload.
- The Web Clip URL is restricted to HTTP or HTTPS and its display name is length-limited.
- The profile is written as an XML property list with generated UUIDs.
- Nocturne exports the profile for the user to inspect and install manually. It cannot silently install or remove profiles.
- A Web Clip adds a website shortcut; it does not replace an arbitrary native app icon or inject code into SpringBoard.

## Unsupported capabilities

Nocturne does not include jailbreak-only tweak injection, private SpringBoard hooks, dynamic library loading into other processes, protected filesystem writes, or exploit-based privilege escalation. These features cannot be truthfully delivered by an ordinary non-jailbroken app.

The app does not currently parse Debian packages, execute package scripts, or load native tweak payloads.

## Imported module manifests

- JSON imports are limited to 64 KiB before decoding.
- IDs, names, descriptions, versions, categories, capability counts, and capability names are validated.
- Imported module data is never executed as code.

## CVE-2026-112611 research note

No exploit implementation, malicious PDF, memory-corruption primitive, or private-framework call from the referenced research is included in Nocturne. It is not treated as a privilege boundary bypass or a supported iOS 27 backend.

## Reporting

Please open a private security advisory or contact the repository owner with a reproducible report. Do not submit exploit payloads targeting other people's devices.

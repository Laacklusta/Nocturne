# Security model

Nocturne treats all imported module manifests as untrusted data.

## Import boundary

- Only JSON module manifests are currently accepted by the app.
- Imports are limited to 64 KiB before decoding.
- IDs, names, descriptions, versions, categories, capability counts, and capability names are validated.
- Only the built-in declarative capabilities are accepted: `theme-preset`, `dashboard-widget`, and `in-app-actions`.
- Imported data is never executed as code.
- Nocturne does not currently parse PDFs, install Debian packages, load dynamic libraries, or process native tweak payloads.

## CVE-2026-112611 research note

The linked research describes an out-of-bounds write in CoreGraphics PDF ShadingType 5 and an experimental userland exploit chain. No exploit implementation, malicious PDF, memory-corruption primitive, or private-framework call is included in Nocturne. The research is not treated as a privilege boundary bypass or a supported iOS 27 backend.

If package inspection is added later, it should be implemented as a bounded, data-only parser with explicit archive-entry limits and no execution of package scripts or binaries.

## Reporting

Please open a private security advisory or contact the repository owner with a reproducible report. Do not submit exploit payloads targeting other people's devices.

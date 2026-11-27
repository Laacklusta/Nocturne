import SwiftUI
import UIKit
import PDFKit
import Darwin
import PDFKit

struct ResearchView: View {
    @EnvironmentObject private var theme: ThemeManager
    @State private var results: [String: String] = [:]
    @State private var diagnosticLog: [String] = []
    @State private var isRunningDiagnostics = false
    @State private var pdfProbeStatus = "Not run"

    private let currentVersion = UIDevice.current.systemVersion
    private var currentBuild: String { sysctlString("kern.osversion") ?? "Unavailable" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Vulnerability Lab", systemImage: "waveform.path.ecg")
                        .foregroundStyle(theme.accent)
                    Text("Evidence-aware checks for this device and published iOS research. Version compatibility is not exploit verification. No exploit payloads, cross-app file access, or kernel memory operations are performed.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Diagnostics") {
                    Button {
                        runAllDiagnostics()
                    } label: {
                        HStack {
                            Label("Run All Diagnostics", systemImage: "stethoscope")
                            Spacer()
                            if isRunningDiagnostics {
                                ProgressView()
                            } else {
                                Image(systemName: "play.fill")
                            }
                        }
                    }
                    .disabled(isRunningDiagnostics)
                    Text("Runs the complete safe diagnostic suite and records each result below. No exploit payloads or privileged memory operations are used.")
                        .font(.caption).foregroundStyle(.secondary)
                    if !diagnosticLog.isEmpty {
                        Button(role: .destructive) {
                            diagnosticLog.removeAll()
                        } label: {
                            Label("Clear diagnostic log", systemImage: "trash")
                                .font(.caption)
                        }
                    }
                }

                Section("This device") {
                    LabeledContent("iOS version", value: currentVersion)
                    LabeledContent("Build", value: currentBuild)
                    LabeledContent("Device model", value: UIDevice.current.model)
                    LabeledContent("Kernel R/W", value: "Not demonstrated")
                    Text("The build identifier is read from the public kern.osversion sysctl. UIKit does not expose a complete hardware identifier or a general entitlement inventory. Exact device-side exploitability still requires a controlled test and evidence log.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("PDF parser stress test") {
                    LabeledContent("Last run", value: pdfProbeStatus)
                    Text("Generates a valid PDF, then runs bounded truncation and byte-mutation cases through PDFKit inside Nocturne. This exercises parser robustness but is not the CVE trigger and does not contact privileged renderers.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Diagnostic log") {
                    if diagnosticLog.isEmpty {
                        Text("No diagnostic run yet. Tap Run All Diagnostics to begin.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(diagnosticLog.enumerated()), id: \.offset) { _, entry in
                            Text(entry)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(.vertical, 2)
                        }
                    }
                }

                Section("worse_query · sandbox escape") {
                    Label("Container-boundary access, not kernel access", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                    Text("The upstream PoC documents selected app, extension, daemon, App Group and system-container paths on supported builds. WQ Files 0.9.30 reports iOS 26.0–26.7.2 and iOS 27.0 through 27.3 beta 1, with a patch at 27.3 beta 2 (24C5049d). Its maintainer lists iPhone 17 Pro Max on 27.0.1 as tested.")
                        .font(.caption).foregroundStyle(.secondary)
                    resultRow("worse_query", fallback: "Not checked")
                    Button {
                        results["worse_query"] = worseQueryAssessment()
                    } label: {
                        Label("Check this build against reports", systemImage: "checkmark.shield")
                    }
                    Text("This is a version/build comparison only. It does not invoke worse_query, inspect another app's files, or prove that the App Group entitlement is preserved by the signing method.")
                        .font(.caption2).foregroundStyle(.secondary)
                    Link(destination: URL(string: "https://github.com/forcequitOS/worse_query")!) {
                        Label("Upstream worse_query source", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://github.com/kolbicz/WQFiles/releases")!) {
                        Label("WQ Files releases and device reports", systemImage: "link")
                    }
                }

                Section("Validation chain") {
                    Label("Sequential, evidence-logged checks", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.subheadline.weight(.semibold))
                    Text("The chain fingerprints the device, verifies Nocturne's own container, exercises a benign PDF round-trip, and records published vulnerability boundaries. It does not run exploit payloads or cross security boundaries.")
                        .font(.caption).foregroundStyle(.secondary)
                    resultRow("chain", fallback: "Not run")
                    resultRow("pdf", fallback: "Not run")
                }

                Section("CVE-2026-112611 · CoreGraphics PDF") {
                    Text("The SKVLENT v0.4 report documents a PDF-triggered out-of-bounds write and heap spill, plus a constrained heap-pointer write in CGPDFService when the target is mapped, writable and initially zero. It also describes a crash-based word oracle. These are researcher-reported results, not independently reproduced by Nocturne.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("The report does not demonstrate arbitrary-value R/W, a general arbitrary read, control-flow hijack, code execution, kernel R/W, or a jailbreak.")
                        .font(.caption).foregroundStyle(.secondary)
                    resultRow("cve", fallback: "Not checked")
                    Button {
                        results["cve"] = cveAssessment()
                    } label: {
                        Label("Check this build against fix boundary", systemImage: "checkmark.shield")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/CVE-2026-112611")!) {
                        Label("CVE-2026-112611 v0.4 research", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/iOS27-Research-Exploits")!) {
                        Label("Broader iOS 27 research notebook", systemImage: "link")
                    }
                }

                Section("Other research worth tracking") {
                    researchRow("CVE-2026-112477 · IOSurface", status: "Not reproduced", detail: "Related race condition; the research notebook reports inert size validation and no kernel R/W.")
                    researchRow("CVE-2026-112696 · ANE", status: "Static analysis only", detail: "A kernel-driver bounds issue is localised in a patch comparison, but the user client is not reachable from the tested app sandbox.")
                    researchRow("CVE-2026-111497 · Brotli", status: "Blocked on device", detail: "A write was reproduced locally; the device test hits an MTE tag-check failure before the alleged disclosure is established.")
                    researchRow("CVE-2026-112706 · mediaplaybackd", status: "Access boundary reproduced", detail: "A media service was reported to open a file on an app's behalf; this is a service-permission issue, not code execution.")
                    researchRow("Metal GPU VA", status: "Same-context only", detail: "GPU reads and writes were reported within one context; the tested process boundary was not crossed.")
                }

                Section("Safe local diagnostics") {
                    Text("This test creates, reads, and removes a temporary file inside Nocturne's own Application Support directory. It verifies ordinary app-container file access only.")
                        .font(.caption).foregroundStyle(.secondary)
                    resultRow("sandbox", fallback: "Not run")
                    Button {
                        results["sandbox"] = runOwnContainerSelfTest()
                    } label: {
                        Label("Test Nocturne's own sandbox", systemImage: "folder.badge.checkmark")
                    }
                }

                Section("Kernel read / write assessment") {
                    resultRow("kernel", fallback: "No kernel primitive integrated")
                    Button {
                        results["kernel"] = "Not demonstrated. Nocturne has no kernel read/write backend. No kernel memory access was attempted."
                    } label: {
                        Label("Assess kernel R/W capability", systemImage: "memorychip")
                    }
                    Text("Neither worse_query nor the cited CVE research establishes kernel R/W on this device. A constrained write in a userland system service is not a kernel primitive.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Research references") {
                    Link(destination: URL(string: "https://support.apple.com/HT149230")!) {
                        Label("Apple · iOS 27.2 security content", systemImage: "apple.logo")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/iOS27-Research-Exploits/blob/main/vulnerabilities/_harness/PROJECT-STATUS.md")!) {
                        Label("Research project status and negative results", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Research")
            .onAppear {
                if UserDefaults.standard.bool(forKey: "nocturne.pdfProbeInProgress") {
                    UserDefaults.standard.set(false, forKey: "nocturne.pdfProbeInProgress")
                    diagnosticLog.append("[(Date().formatted(date: .omitted, time: .standard))] PDF parser stress: Previous run ended before completion; possible app termination during parser testing. This is not proof of a vulnerability.")
                }
            }
        }
    }

    private func runAllDiagnostics() {
        guard !isRunningDiagnostics else { return }
        isRunningDiagnostics = true
        diagnosticLog.removeAll()

        func record(_ name: String, _ outcome: String) {
            results[name] = outcome
            let timestamp = Date().formatted(date: .omitted, time: .standard)
            diagnosticLog.append("[\(timestamp)] \(name): \(outcome)")
        }

        Task { @MainActor in
            record("Chain", "Started staged device and attack-surface assessment.")
            record("Device", "\(UIDevice.current.model), iOS \(currentVersion), build \(currentBuild)")
            record("App identity", Bundle.main.bundleIdentifier ?? "Bundle identifier unavailable")
            record("App bundle", FileManager.default.fileExists(atPath: Bundle.main.bundlePath)
                ? "Passed: application bundle is readable."
                : "Failed: application bundle path is unavailable.")

            record("worse_query", worseQueryAssessment())
            record("cve", cveAssessment())
            record("PDF baseline", "Generating a valid PDF and checking PDFKit parsing.")

            UserDefaults.standard.set(true, forKey: "nocturne.pdfProbeInProgress")
            let pdfResult = await runPDFParserStressTest()
            UserDefaults.standard.set(false, forKey: "nocturne.pdfProbeInProgress")
            pdfProbeStatus = pdfResult
            record("PDF parser stress", pdfResult)

            record("sandbox", runOwnContainerSelfTest())
            record("Entitlements", "Not enumerated: no entitlement-inspection backend; no private entitlement APIs called.")
            record("Service boundary", "No external XPC service or other app container was contacted.")
            record("kernel", "Not demonstrated. No kernel memory access was attempted.")
            record("Exploit chain", "Stopped at evidence collection. No sandbox escape, privileged service payload, or kernel primitive was executed.")
            diagnosticLog.append("[\(Date().formatted(date: .omitted, time: .standard))] COMPLETE: Research chain finished.")
            isRunningDiagnostics = false
        }
    }

    // Bounded PDFKit robustness test using generated input and deterministic mutations.
    // It does not reproduce CVE-2026-112611 or target a privileged renderer.
    private func runPDFParserStressTest() async -> String {
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let baseline = renderer.pdfData { context in
            context.beginPage()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18)
            ]
            "Nocturne PDF parser baseline".draw(at: CGPoint(x: 48, y: 48), withAttributes: attributes)
        }

        guard !baseline.isEmpty, let baselineDocument = PDFDocument(data: baseline),
              baselineDocument.pageCount == 1 else {
            return "Failed: generated baseline PDF could not be parsed as a one-page document."
        }

        return await Task.detached(priority: .utility) {
            let original = [UInt8](baseline)
            guard original.count > 64 else {
                return "Failed: generated PDF was unexpectedly small."
            }

            var corpus: [Data] = []
            for divisor in 2...8 {
                let cut = max(1, original.count - original.count / divisor)
                corpus.append(Data(original.prefix(cut)))
            }

            let strideSize = max(1, original.count / 14)
            for offset in Swift.stride(from: 16, to: original.count, by: strideSize) {
                var changed = original
                changed[offset] ^= 0xFF
                corpus.append(Data(changed))
            }

            corpus.append(Data([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]))
            corpus.append(Data(original + Array(repeating: 0x00, count: 64)))
            corpus = Array(corpus.prefix(24))

            var parsed = 0
            var rejected = 0
            for candidate in corpus {
                if let document = PDFDocument(data: candidate), document.pageCount > 0 {
                    parsed += 1
                } else {
                    rejected += 1
                }
            }

            return "Completed \(corpus.count) bounded mutations in Nocturne's process: \(parsed) parsed, \(rejected) rejected. No crash observed during this run; this does not establish CVE status or absence of memory corruption."
        }.value
    }

    @ViewBuilder
    private func resultRow(_ key: String, fallback: String) -> some View {
        HStack(alignment: .top) {
            Text("Last result").font(.subheadline)
            Spacer()
            Text(results[key] ?? fallback)
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing).frame(maxWidth: 220, alignment: .trailing)
        }
    }

    private func researchRow(_ title: String, status: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(status).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func worseQueryAssessment() -> String {
        if isVersion(in: currentVersion, from: "26.0", through: "26.7.2") {
            return "Within WQ Files' reported iOS 26 range. Not proof of reachability."
        }
        if compareVersions(currentVersion, "27.0") != .orderedAscending &&
            compareVersions(currentVersion, "27.2.99") != .orderedDescending {
            return "Within WQ Files' reported iOS 27 range. Maintainer device test is 27.0.1; this build still needs an on-device access test."
        }
        if compareVersions(currentVersion, "27.3") == .orderedSame {
            if currentBuild == "24C5049d" || currentBuild > "24C5049d" {
                return "Build is at or beyond the reported 27.3 beta 2 patch boundary."
            }
            if currentBuild == "24C5037i" {
                return "Matches the reported 27.3 beta 1 supported build. Not proof of reachability."
            }
            return "iOS 27.3 detected, but this build is not identified in the published boundary list."
        }
        if compareVersions(currentVersion, "27.3") == .orderedDescending {
            return "Outside the published WQ Files support range; later builds are reported patched."
        }
        return "Not covered by the currently cited WQ Files compatibility reports."
    }

    private func cveAssessment() -> String {
        if compareVersions(currentVersion, "27.2") == .orderedAscending {
            return "Earlier than the published 27.2 fix boundary. Research reproduction is specifically reported on iPhone18,1 / 27.0.1 (24A446); this device's exploitability is not established."
        }
        return "At or after the published iOS 27.2 fix boundary. No exploit test was run."
    }

    private func runOwnContainerSelfTest() -> String {
        let manager = FileManager.default
        guard let support = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return "Failed: Application Support directory unavailable."
        }
        let probe = support.appendingPathComponent("nocturne-sandbox-self-test.tmp")
        let payload = Data("Nocturne local sandbox self-test".utf8)
        do {
            try payload.write(to: probe, options: .atomic)
            let readBack = try Data(contentsOf: probe)
            try manager.removeItem(at: probe)
            return readBack == payload
                ? "Passed: Nocturne can write/read/delete a file in its own container. No other path was accessed."
                : "Failed: data read-back did not match."
        } catch {
            try? manager.removeItem(at: probe)
            return "Failed: \(error.localizedDescription)"
        }
    }

    private func runBenignPDFSelfTest() -> String {
        // Generate a harmless one-page PDF in memory, then parse and render it
        // using the same public PDFKit/CoreGraphics stack used by ordinary apps.
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            let message = "Nocturne benign PDF validation"
            (message as NSString).draw(
                at: CGPoint(x: 48, y: 48),
                withAttributes: [.font: UIFont.systemFont(ofSize: 18)]
            )
        }

        guard let document = PDFDocument(data: pdfData),
              document.pageCount == 1,
              let page = document.page(at: 0) else {
            return "Failed: generated test PDF could not be parsed as a one-page document."
        }

        let thumbnail = page.thumbnail(of: CGSize(width: 256, height: 256), for: .mediaBox)
        guard thumbnail.cgImage != nil else {
            return "Failed: PDF parsed, but thumbnail rendering returned no image."
        }

        return "Passed: generated, parsed, and rendered a benign one-page PDF in memory. This does not test CVE-2026-112611."
    }

    private func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        let result = value.withUnsafeMutableBufferPointer {
            sysctlbyname(name, $0.baseAddress, &size, nil, 0)
        }
        guard result == 0 else { return nil }
        return String(cString: value)
    }

    private func isVersion(in version: String, from lower: String, through upper: String) -> Bool {
        compareVersions(version, lower) != .orderedAscending &&
        compareVersions(version, upper) != .orderedDescending
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".").compactMap { Int($0) }
        let right = rhs.split(separator: ".").compactMap { Int($0) }
        for index in 0..<max(left.count, right.count) {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }
}

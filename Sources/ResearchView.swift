import SwiftUI
import UIKit

struct ResearchView: View {
    @EnvironmentObject private var theme: ThemeManager
    @State private var results: [String: String] = [:]

    private let currentVersion = UIDevice.current.systemVersion

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Vulnerability Lab", systemImage: "waveform.path.ecg")
                        .foregroundStyle(theme.accent)
                    Text("Run non-destructive checks against this device's reported OS version and Nocturne's own sandbox. These checks do not execute exploit code, access other apps' data, or test kernel memory.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("This device") {
                    LabeledContent("iOS version", value: currentVersion)
                    LabeledContent("Device model", value: UIDevice.current.model)
                    LabeledContent("Kernel R/W", value: "Not available")
                    Text("UIKit does not expose the exact build identifier, hardware model identifier, entitlement validation, or exploitability. Version matches are advisory.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("worse_query · sandbox escape") {
                    Label("Not a CVE or a jailbreak", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                    Text("The upstream proof of concept describes access to selected app and system container paths through a sandbox-extension issue. Its README lists iOS 26.0–26.7.2 and iOS 27.2. The author explicitly says it is not relevant to a jailbreak.")
                        .font(.caption).foregroundStyle(.secondary)
                    resultRow("worse_query", fallback: "Not checked")
                    Button {
                        results["worse_query"] = worseQueryAssessment()
                    } label: {
                        Label("Check reported version compatibility", systemImage: "checkmark.shield")
                    }
                    Text("This compares the OS version with public reports only. It does not invoke worse_query or attempt to open protected containers.")
                        .font(.caption2).foregroundStyle(.secondary)
                    Link(destination: URL(string: "https://github.com/forcequitOS/worse_query")!) {
                        Label("Upstream worse_query source", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://github.com/kolbicz/WQFiles")!) {
                        Label("WQ Files · additional device reports", systemImage: "link")
                    }
                }

                Section("CVE-2026-112611 · CoreGraphics") {
                    Text("Public research describes a constrained 4-byte zero write in a PDF-selected CoreGraphics shading path and heap corruption. It does not establish general-purpose arbitrary R/W, kernel R/W, or a complete privilege-escalation chain.")
                        .font(.caption).foregroundStyle(.secondary)
                    resultRow("cve", fallback: "Not checked")
                    Button {
                        results["cve"] = cveAssessment()
                    } label: {
                        Label("Check reported version range", systemImage: "checkmark.shield")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/CVE-2026-112611")!) {
                        Label("CVE-2026-112611 research", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/iOS27-Research-Exploits")!) {
                        Label("iOS 27 research collection", systemImage: "link")
                    }
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
                        results["kernel"] = "Not testable: Nocturne has no kernel read/write primitive or kernel exploit backend integrated. No memory access was attempted."
                    } label: {
                        Label("Assess kernel R/W capability", systemImage: "memorychip")
                    }
                    Text("A sandbox escape is not a kernel exploit. worse_query does not provide kernel privileges or kernel memory access. The CVE-2026-112611 public material does not demonstrate kernel R/W either.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Research references") {
                    Link(destination: URL(string: "https://support.apple.com/HT149230")!) {
                        Label("Apple · iOS 27.2 security content", systemImage: "apple.logo")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Research")
        }
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

    private func worseQueryAssessment() -> String {
        if isVersion(in: currentVersion, from: "26.0", through: "26.7.2") {
            return "Inside upstream's reported iOS 26 range. Not proof of reachability."
        }
        if isVersion(in: currentVersion, from: "27.2", through: "27.2") {
            return "Matches upstream's listed iOS 27.2 target. Not proof of reachability."
        }
        if isVersion(in: currentVersion, from: "27.0", through: "27.1.99") {
            return "Not listed in the upstream README's iOS 27 target (27.2). Third-party reports differ; exact build remains unverified."
        }
        if compareVersions(currentVersion, "27.3") != .orderedAscending {
            return "Outside the upstream listed range. Check current patch-status reports for this exact build."
        }
        return "Outside the upstream README's listed range. No exploit test was run."
    }

    private func cveAssessment() -> String {
        if compareVersions(currentVersion, "27.2") == .orderedAscending {
            return "Reported pre-fix version range. Hardware/build applicability and exploitability are unverified."
        }
        return "At or after the reported iOS 27.2 fix boundary. No exploit test was run."
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

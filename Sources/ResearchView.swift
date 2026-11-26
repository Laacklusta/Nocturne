import SwiftUI
import UIKit

struct ResearchView: View {
    @EnvironmentObject private var theme: ThemeManager

    private let currentVersion = UIDevice.current.systemVersion
    private let fixedVersion = "27.2"

    private var appearsPreFix: Bool {
        compareVersions(currentVersion, fixedVersion) == .orderedAscending
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Research reference loaded", systemImage: "doc.text.magnifyingglass")
                        .foregroundStyle(theme.accent)
                    Text("This page summarizes public, device-tested research. No exploit is run, no memory is read or written, and Nocturne does not attempt privilege escalation.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("CVE-2026-112611 · CoreGraphics") {
                    LabeledContent("Your iOS version", value: currentVersion)
                    LabeledContent("Reported test build", value: "27.0.1 (24A446)")
                    LabeledContent("Fixed in", value: "iOS 27.2")
                    HStack {
                        Text("Version assessment")
                        Spacer()
                        Text(appearsPreFix ? "Pre-fix version range" : "27.2 or newer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(appearsPreFix ? .orange : .green)
                    }
                    Text("This is only a version comparison. It does not verify the device build, hardware applicability, exploitability, or whether a vendor backport is present.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("What SKVLENT demonstrated") {
                    evidence("PDF-selected 4-byte zero write", detail: "Reproduced in the CoreGraphics PDF shading path on the documented test build.")
                    evidence("Heap corruption primitive", detail: "Attacker-controlled values spill beyond a PDF shading record.")
                    evidence("Privileged userland reachability", detail: "The research reports a write primitive in the QuickLook CGPDFService process.")
                }

                Section("What it did not demonstrate") {
                    evidence("Arbitrary read/write", detail: "The documented write values are constrained; a general-purpose data read/write primitive is not established.")
                    evidence("Code execution", detail: "No working control-flow hijack or code execution is reported.")
                    evidence("Kernel read/write or jailbreak", detail: "The research repository explicitly says neither has been demonstrated.")
                }

                Section("How this informs Nocturne") {
                    Text("Nocturne can use this research to track compatibility, explain the security boundary, and keep future experiments isolated. It cannot turn a CoreGraphics userland bug into kernel access by itself.")
                    Text("The current Tweak Center remains limited to documented, user-approved iOS configuration features. No exploit payloads or privileged operations are included.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Primary research") {
                    Link(destination: URL(string: "https://github.com/SKVLENT/CVE-2026-112611")!) {
                        Label("SKVLENT · CVE-2026-112611", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/iOS27-Research-Exploits")!) {
                        Label("SKVLENT · iOS 27 Research Exploits", systemImage: "link")
                    }
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

    private func evidence(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 3)
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

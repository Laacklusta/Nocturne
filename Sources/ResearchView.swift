import SwiftUI
import UIKit

struct ResearchView: View {
    @EnvironmentObject private var theme: ThemeManager
    private let currentVersion = UIDevice.current.systemVersion
    private let fixVersion = "27.2"

    private var assessment: String {
        compareVersions(currentVersion, fixVersion) == .orderedAscending
            ? "Reported pre-fix range" : "At/after reported fix"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("iOS 27 research track", systemImage: "waveform.path.ecg")
                        .foregroundStyle(theme.accent)
                    Text("Nocturne tracks public security research separately from confirmed device support. A version match is not proof that a vulnerability is reachable or that a jailbreak exists.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("This device") {
                    LabeledContent("Reported iOS version", value: currentVersion)
                    LabeledContent("Research assessment", value: assessment)
                    Text("UIKit exposes the OS version, not the exact build number, hardware applicability, jailbreak state, or exploitability.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("CVE-2026-112611 · reported scope") {
                    compatibilityRow("iOS 27.0 / 27.0.1", "Primary research target")
                    compatibilityRow("iOS 27.1.x", "Pre-fix range; verify build")
                    compatibilityRow("iOS 27.2 and later", "Reported fixed")
                    compatibilityRow("iOS 17–26", "Not assessed by this research")
                    Text("The public research identifies iOS 27.2 as the fix boundary. Earlier versions are a reported pre-fix range only; exact build and hardware applicability require independent verification.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Reported primitive status") {
                    evidence("Constrained 4-byte zero write", "Reported in a PDF-selected CoreGraphics shading path.")
                    evidence("Heap corruption", "Associated with an out-of-bounds heap corruption condition.")
                    evidence("Privileged userland reachability", "The research describes reachability through QuickLook's CGPDFService process.")
                }
                Section("Not demonstrated by this research") {
                    evidence("General arbitrary read/write", "The reported write is constrained; a general-purpose read/write primitive is not established.")
                    evidence("Kernel read/write", "The public research does not demonstrate kernel memory read or write.")
                    evidence("Working jailbreak or persistence", "No complete privilege-escalation chain or jailbreak is established.")
                }
                Section("Nocturne implementation status") {
                    statusRow("Version-aware compatibility catalog", "In progress", .orange)
                    statusRow("Jailbreak environment adapters", "Not integrated", .secondary)
                    statusRow("CVE proof-of-concept integration", "Not integrated", .secondary)
                    Text("The app currently contains research notes and compatibility reporting only. It does not execute the CVE proof of concept or modify kernel memory. System-tweak backends must be implemented and tested independently for each supported environment.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Primary references") {
                    Link(destination: URL(string: "https://github.com/SKVLENT/CVE-2026-112611")!) {
                        Label("SKVLENT · CVE-2026-112611", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://github.com/SKVLENT/iOS27-Research-Exploits")!) {
                        Label("SKVLENT · iOS 27 research", systemImage: "link")
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

    private func compatibilityRow(_ version: String, _ status: String) -> some View {
        HStack {
            Text(version).font(.subheadline.weight(.medium))
            Spacer()
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func evidence(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 3)
    }

    private func statusRow(_ title: String, _ state: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(state).font(.caption.weight(.medium)).foregroundStyle(color)
        }
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

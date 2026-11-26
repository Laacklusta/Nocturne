import SwiftUI
import UIKit

struct TweakCenterView: View {
    @EnvironmentObject private var theme: ThemeManager
    @State private var clipName = "My Web App"
    @State private var clipURL = "https://example.com"
    @State private var opensFullscreen = true
    @State private var generatedFile: ShareableProfile?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Supported system configuration", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("These are user-installed iOS configuration profiles, not injected SpringBoard tweaks. iOS displays the profile installation screen and you decide whether to install it.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section {
                    TextField("Shortcut name", text: $clipName)
                        .textInputAutocapitalization(.words)
                    TextField("Website URL", text: $clipURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Toggle("Open as a full-screen web app", isOn: $opensFullscreen)
                    Button {
                        exportWebClip()
                    } label: {
                        Label("Generate installable profile", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(clipName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("Home Screen Web Clip")
                } footer: {
                    Text("Creates a .mobileconfig containing Apple's Web Clip payload. After sharing or saving it, open the file on your iPhone and approve installation in Settings.")
                }

                Section("What this can and cannot do") {
                    capabilityRow("Add a Home Screen website shortcut", supported: true)
                    capabilityRow("Launch a site in standalone mode", supported: true)
                    capabilityRow("Replace arbitrary app icons", supported: false)
                    capabilityRow("Inject code into SpringBoard or apps", supported: false)
                    capabilityRow("Change protected system UI", supported: false)
                }

                Section("More tweak types") {
                    Label("App extensions and widgets", systemImage: "square.grid.2x2")
                    Text("These require dedicated extension targets and user placement. They cannot modify unrelated apps.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Label("Shortcuts automations", systemImage: "command")
                    Text("Nocturne can provide setup flows and shortcut links, but iOS requires the user to authorize and configure personal automations.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Tweak Center")
            .sheet(item: $generatedFile) { item in
                ActivitySheet(activityItems: [item.url])
                    .presentationDetents([.medium, .large])
            }
            .alert("Couldn't create profile", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func capabilityRow(_ title: String, supported: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(supported ? Color.green : Color.secondary)
        }
        .font(.subheadline)
    }

    private func exportWebClip() {
        let name = clipName.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawURL = clipURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count <= 60,
              let components = URLComponents(string: rawURL),
              let scheme = components.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = components.host, !host.isEmpty,
              let normalizedURL = components.url else {
            errorMessage = "Enter a name (60 characters or fewer) and a valid HTTP or HTTPS website URL."
            return
        }

        do {
            let profileUUID = UUID().uuidString
            let payloadUUID = UUID().uuidString
            let payload: [String: Any] = [
                "PayloadType": "com.apple.webClip.managed",
                "PayloadVersion": 1,
                "PayloadIdentifier": "com.nocturne.webclip.\(payloadUUID.lowercased())",
                "PayloadUUID": payloadUUID,
                "PayloadDisplayName": name,
                "PayloadDescription": "Home Screen web shortcut created with Nocturne.",
                "Label": name,
                "URL": normalizedURL.absoluteString,
                "Icon": makeDefaultIcon(),
                "IsRemovable": true,
                "FullScreen": opensFullscreen,
                "Precomposed": true
            ]
            let profile: [String: Any] = [
                "PayloadContent": [payload],
                "PayloadDescription": "Adds the \(name) web shortcut to the Home Screen.",
                "PayloadDisplayName": "Nocturne · \(name)",
                "PayloadIdentifier": "com.nocturne.profile.\(profileUUID.lowercased())",
                "PayloadOrganization": "Nocturne",
                "PayloadRemovalDisallowed": false,
                "PayloadType": "Configuration",
                "PayloadUUID": profileUUID,
                "PayloadVersion": 1
            ]
            let data = try PropertyListSerialization.data(
                fromPropertyList: profile,
                format: .xml,
                options: 0
            )
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Nocturne-\(safeFilename(name)).mobileconfig")
            try data.write(to: fileURL, options: .atomic)
            generatedFile = ShareableProfile(url: fileURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makeDefaultIcon() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 180))
        let image = renderer.image { context in
            UIColor(red: 0.20, green: 0.12, blue: 0.34, alpha: 1).setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 180, height: 180))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 104, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let mark = NSAttributedString(string: "N", attributes: attributes)
            let size = mark.size()
            mark.draw(at: CGPoint(x: (180 - size.width) / 2, y: (180 - size.height) / 2 - 4))
        }
        return image.pngData() ?? Data()
    }

    private func safeFilename(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let cleaned = value.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
        return String(cleaned.prefix(40)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

private struct ShareableProfile: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct ActivitySheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

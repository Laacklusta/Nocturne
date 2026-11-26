import SwiftUI
import UniformTypeIdentifiers

@main
struct NocturneApp: App {
    @StateObject private var store = ModuleStore()
    @StateObject private var theme = ThemeManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(theme)
                .preferredColorScheme(.dark)
        }
    }
}

enum NocturneTheme: String, CaseIterable, Identifiable {
    case midnight = "Midnight"
    case amethyst = "Amethyst"
    case graphite = "Graphite"
    case oled = "OLED Black"

    var id: String { rawValue }
    var background: Color {
        switch self {
        case .midnight: return Color(red: 0.035, green: 0.039, blue: 0.055)
        case .amethyst: return Color(red: 0.075, green: 0.045, blue: 0.105)
        case .graphite: return Color(red: 0.075, green: 0.080, blue: 0.090)
        case .oled: return .black
        }
    }
    var panel: Color {
        switch self {
        case .midnight: return Color(red: 0.085, green: 0.090, blue: 0.12)
        case .amethyst: return Color(red: 0.14, green: 0.085, blue: 0.18)
        case .graphite: return Color(red: 0.14, green: 0.15, blue: 0.17)
        case .oled: return Color(red: 0.055, green: 0.055, blue: 0.065)
        }
    }
    var accent: Color {
        switch self {
        case .midnight: return Color(red: 0.58, green: 0.38, blue: 0.98)
        case .amethyst: return Color(red: 0.82, green: 0.48, blue: 1.0)
        case .graphite: return Color(red: 0.42, green: 0.72, blue: 1.0)
        case .oled: return Color(red: 0.45, green: 0.72, blue: 1.0)
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published var selected: NocturneTheme {
        didSet { UserDefaults.standard.set(selected.rawValue, forKey: "nocturne.selectedTheme") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "nocturne.selectedTheme") ?? ""
        selected = NocturneTheme(rawValue: saved) ?? .midnight
    }

    var background: Color { selected.background }
    var panel: Color { selected.panel }
    var accent: Color { selected.accent }

    func applyModule(_ module: ModuleRecord) {
        guard module.manifest.capabilities.contains("theme-preset"),
              let themeName = module.manifest.theme,
              let choice = NocturneTheme(rawValue: themeName) else { return }
        selected = choice
    }
}

struct ModuleManifest: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let version: String
    let author: String
    let description: String
    let category: String
    let minimumAppVersion: String?
    let capabilities: [String]
    var theme: String? = nil
}

struct ModuleRecord: Identifiable, Codable, Hashable {
    var manifest: ModuleManifest
    var isInstalled = false
    var isEnabled = false
    var id: String { manifest.id }
}

@MainActor
final class ModuleStore: ObservableObject {
    @Published var modules: [ModuleRecord] = []
    @Published var query = ""
    @Published var category = "All"

    private let saveURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        saveURL = directory.appendingPathComponent("modules.json")
        if let data = try? Data(contentsOf: saveURL),
           let saved = try? JSONDecoder().decode([ModuleRecord].self, from: data) {
            modules = saved
        } else {
            modules = Self.samples
            persist()
        }
    }

    var installed: [ModuleRecord] { modules.filter(\.isInstalled) }
    var categories: [String] { ["All"] + Set(modules.map { $0.manifest.category }).sorted() }
    var filtered: [ModuleRecord] {
        modules.filter {
            (category == "All" || $0.manifest.category == category) &&
            (query.isEmpty || $0.manifest.name.localizedCaseInsensitiveContains(query) ||
             $0.manifest.description.localizedCaseInsensitiveContains(query))
        }.sorted { $0.manifest.name < $1.manifest.name }
    }

    func install(_ id: String) {
        guard let i = modules.firstIndex(where: { $0.id == id }) else { return }
        modules[i].isInstalled = true
        persist()
    }

    func remove(_ id: String) {
        guard let i = modules.firstIndex(where: { $0.id == id }) else { return }
        modules[i].isInstalled = false
        modules[i].isEnabled = false
        persist()
    }

    func toggle(_ enabled: Bool, id: String) {
        guard let i = modules.firstIndex(where: { $0.id == id }), modules[i].isInstalled else { return }
        modules[i].isEnabled = enabled
        persist()
    }

    func importManifest(_ url: URL) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let manifest = try JSONDecoder().decode(ModuleManifest.self, from: Data(contentsOf: url))
        guard !manifest.id.isEmpty, !manifest.name.isEmpty, !manifest.version.isEmpty else {
            throw ImportError.invalidManifest
        }
        if let i = modules.firstIndex(where: { $0.id == manifest.id }) {
            modules[i] = ModuleRecord(manifest: manifest)
        } else {
            modules.append(ModuleRecord(manifest: manifest))
        }
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(modules) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private static let samples = [
        ModuleRecord(manifest: ModuleManifest(
            id: "com.nocturne.midnight", name: "Midnight Palette", version: "1.0.0",
            author: "Nocturne", description: "A deep charcoal and violet palette for the Nocturne interface.",
            category: "Appearance", minimumAppVersion: "0.1.0", capabilities: ["theme-preset"], theme: "Midnight"
        )),
        ModuleRecord(manifest: ModuleManifest(
            id: "com.nocturne.amethyst", name: "Amethyst Palette", version: "1.0.0",
            author: "Nocturne", description: "A richer violet palette with a brighter lavender accent.",
            category: "Appearance", minimumAppVersion: "0.1.0", capabilities: ["theme-preset"], theme: "Amethyst"
        )),
        ModuleRecord(manifest: ModuleManifest(
            id: "com.nocturne.graphite", name: "Graphite Palette", version: "1.0.0",
            author: "Nocturne", description: "A neutral graphite interface with a cool blue accent.",
            category: "Appearance", minimumAppVersion: "0.1.0", capabilities: ["theme-preset"], theme: "Graphite"
        )),
        ModuleRecord(manifest: ModuleManifest(
            id: "com.nocturne.oled", name: "OLED Black", version: "1.0.0",
            author: "Nocturne", description: "Near-pure black panels for an OLED-friendly interface.",
            category: "Appearance", minimumAppVersion: "0.1.0", capabilities: ["theme-preset"], theme: "OLED Black"
        )),
        ModuleRecord(manifest: ModuleManifest(
            id: "com.nocturne.focus", name: "Focus Dashboard", version: "1.0.0",
            author: "Nocturne", description: "A clean dashboard preset and layout configuration.",
            category: "Productivity", minimumAppVersion: "0.1.0", capabilities: ["dashboard-widget"]
        )),
        ModuleRecord(manifest: ModuleManifest(
            id: "com.nocturne.shortcuts", name: "Quick Actions", version: "1.0.0",
            author: "Community", description: "Shortcuts displayed inside the Nocturne app.",
            category: "Utilities", minimumAppVersion: "0.1.0", capabilities: ["in-app-actions"]
        ))
    ]
}

enum ImportError: LocalizedError {
    case invalidManifest
    var errorDescription: String? { "The selected file is not a valid Nocturne module manifest." }
}

struct RootView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Home", systemImage: "square.grid.2x2.fill") }
            ModuleBrowserView().tabItem { Label("Discover", systemImage: "square.stack.3d.up.fill") }
            InstalledView().tabItem { Label("Installed", systemImage: "checkmark.seal.fill") }
            SettingsView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }.tint(theme.accent)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: ModuleStore
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOCTURNE").font(.caption.bold()).tracking(3).foregroundStyle(.secondary)
                        Text("Make iOS yours.").font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Your customization workspace").foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        metric("Installed", value: "\(store.installed.count)", icon: "square.stack.3d.up")
                        metric("Enabled", value: "\(store.installed.filter(\.isEnabled).count)", icon: "checkmark.circle")
                    }
                    NavigationLink { ModuleBrowserView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Discover modules").font(.headline)
                                Text("Browse presets and in-app extensions").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }.padding(18).background(theme.panel).clipShape(RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                    Label("Non-jailbroken mode", systemImage: "lock.shield.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                    Text("Modules customize Nocturne itself. iOS does not let an ordinary app inject tweaks into SpringBoard or other apps.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20)
            }.background(theme.background.ignoresSafeArea()).toolbar(.hidden, for: .navigationBar)
        }
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundStyle(theme.accent)
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(theme.panel).clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ModuleBrowserView: View {
    @EnvironmentObject private var store: ModuleStore
    @EnvironmentObject private var theme: ThemeManager
    @State private var importing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.categories, id: \.self) { item in
                            Button(item) { store.category = item }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(store.category == item ? theme.accent : theme.panel)
                                .foregroundStyle(.white).clipShape(Capsule())
                        }
                    }.padding(.horizontal)
                }
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.filtered) { module in
                            NavigationLink { ModuleDetailView(id: module.id) } label: {
                                ModuleRow(module: module)
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal)
                }
            }.background(theme.background.ignoresSafeArea())
                .navigationTitle("Discover")
                .searchable(text: $store.query, prompt: "Search modules")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { importing = true } label: { Image(systemName: "square.and.arrow.down") }
                    }
                }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    do { try store.importManifest(result.get()) }
                    catch { errorMessage = error.localizedDescription }
                }
                .alert("Import failed", isPresented: Binding(
                    get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { errorMessage = nil }
                } message: { Text(errorMessage ?? "") }
        }
    }
}

struct ModuleRow: View {
    let module: ModuleRecord
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: module.manifest.category == "Appearance" ? "paintpalette.fill" : "puzzlepiece.extension.fill")
                .font(.title2).foregroundStyle(theme.accent)
                .frame(width: 52, height: 52).background(theme.accent.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(module.manifest.name).font(.headline)
                Text(module.manifest.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text("\(module.manifest.author) · v\(module.manifest.version)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: module.isInstalled ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(module.isInstalled ? .green : .secondary)
        }.padding(14).background(theme.panel).clipShape(RoundedRectangle(cornerRadius: 17))
    }
}

struct ModuleDetailView: View {
    let id: String
    @EnvironmentObject private var store: ModuleStore
    @EnvironmentObject private var theme: ThemeManager
    private var module: ModuleRecord? { store.modules.first { $0.id == id } }

    var body: some View {
        Group {
            if let module {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 48)).foregroundStyle(theme.accent)
                            .frame(maxWidth: .infinity).padding(.vertical, 28)
                            .background(theme.panel).clipShape(RoundedRectangle(cornerRadius: 22))
                        Text(module.manifest.name).font(.largeTitle.bold())
                        Text(module.manifest.description).foregroundStyle(.secondary)
                        detail("Version", module.manifest.version)
                        detail("Author", module.manifest.author)
                        detail("Category", module.manifest.category)
                        Text("Declared capabilities").font(.headline)
                        ForEach(module.manifest.capabilities, id: \.self) {
                            Label($0, systemImage: "checkmark.circle").font(.subheadline)
                        }
                        Text("Capabilities describe features inside Nocturne. They do not grant access to protected iOS components.")
                            .font(.footnote).foregroundStyle(.secondary)
                        if module.isInstalled {
                            Toggle("Enable module", isOn: Binding(
                                get: { module.isEnabled },
                                set: {
                                    store.toggle($0, id: id)
                                    if $0 && module.manifest.capabilities.contains("theme-preset") {
                                        theme.applyModule(module)
                                    }
                                }
                            )).tint(theme.accent)
                            Button("Remove module", role: .destructive) { store.remove(id) }
                                .buttonStyle(.bordered).frame(maxWidth: .infinity)
                        } else {
                            Button("Install module") { store.install(id) }
                                .buttonStyle(.borderedProminent).tint(theme.accent)
                                .frame(maxWidth: .infinity)
                        }
                    }.padding(20)
                }.background(theme.background.ignoresSafeArea())
                    .navigationTitle("Module").navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("Module unavailable", systemImage: "questionmark.folder")
            }
        }
    }

    private func detail(_ title: String, _ value: String) -> some View {
        HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).fontWeight(.medium) }
            .font(.subheadline)
    }
}

struct InstalledView: View {
    @EnvironmentObject private var store: ModuleStore
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        NavigationStack {
            List {
                if store.installed.isEmpty {
                    ContentUnavailableView("No modules installed", systemImage: "square.stack.3d.up",
                        description: Text("Discover and install modules to see them here."))
                        .listRowBackground(Color.clear)
                }
                ForEach(store.installed) { module in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(module.manifest.name).font(.headline)
                            Text("v\(module.manifest.version)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("Enabled", isOn: Binding(
                            get: { module.isEnabled },
                            set: {
                                store.toggle($0, id: module.id)
                                if $0 && module.manifest.capabilities.contains("theme-preset") {
                                    theme.applyModule(module)
                                }
                            }
                        )).labelsHidden().tint(theme.accent)
                    }.listRowBackground(theme.panel)
                }
            }.scrollContentBackground(.hidden).background(theme.background)
                .navigationTitle("Installed")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $theme.selected) {
                        ForEach(NocturneTheme.allCases) { choice in
                            Text(choice.rawValue).tag(choice)
                        }
                    }
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8).fill(theme.accent).frame(width: 28, height: 28)
                        VStack(alignment: .leading) {
                            Text("Live preview").font(.subheadline.weight(.semibold))
                            Text("Theme changes apply throughout Nocturne and are saved automatically.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                }
                Section("Application") {
                    LabeledContent("Name", value: "Nocturne")
                    LabeledContent("Version", value: "0.1.0 · Foundation")
                    LabeledContent("Mode", value: "Non-jailbroken")
                }
                Section("Compatibility") {
                    Label("Sandbox-safe module system", systemImage: "checkmark.shield.fill").foregroundStyle(.green)
                    Text("System-wide tweak injection, SpringBoard modification and privileged package installation are outside the capabilities of this build.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("About") {
                    Text("Nocturne is an independent project and is not affiliated with Apple, Cyanide, or SnowBoard.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.scrollContentBackground(.hidden).background(theme.background)
                .navigationTitle("Settings")
        }
    }
}

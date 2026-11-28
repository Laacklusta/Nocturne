import SwiftUI

private enum ClipStyle {
    static let bg = Color(red: 0.055, green: 0.065, blue: 0.085)
    static let surface = Color(red: 0.105, green: 0.12, blue: 0.15)
    static let raised = Color(red: 0.145, green: 0.16, blue: 0.195)
    static let accent = Color(red: 0.40, green: 0.66, blue: 1.0)
    static let green = Color(red: 0.30, green: 0.82, blue: 0.57)
    static let secondary = Color.white.opacity(0.56)
    static let separator = Color.white.opacity(0.08)
}

private struct DemoPackage: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let version: String
    let author: String
    let section: String
    let icon: String
    let tint: Color
    let description: String

    static let catalog: [DemoPackage] = [
        .init(id: "orion", name: "Orion UI", summary: "A refined interface concept", version: "1.4.2", author: "Nocturne Labs", section: "Themes", icon: "paintpalette.fill", tint: .purple, description: "A sample appearance package for previewing the package details and install flow. No system files are changed."),
        .init(id: "lunar", name: "Lunar Status", summary: "Status bar layout concept", version: "2.0.1", author: "Mira", section: "Tweaks", icon: "moon.stars.fill", tint: .cyan, description: "A mock status presentation concept with configurable visual options."),
        .init(id: "velvet", name: "Velvet", summary: "A softer visual theme", version: "1.1.0", author: "Nocturne Labs", section: "Themes", icon: "sparkles", tint: .pink, description: "A sample theme entry used to demonstrate package browsing."),
        .init(id: "nocturne-tools", name: "Nocturne Tools", summary: "Utilities and visual components", version: "0.9.8", author: "Nocturne Labs", section: "Utilities", icon: "wrench.and.screwdriver.fill", tint: .orange, description: "A collection of placeholder utilities for this interactive catalog.")
    ]
}

@main
struct NocturneClipApp: App {
    var body: some Scene {
        WindowGroup { ClipStoreView() }
    }
}

struct ClipStoreView: View {
    @AppStorage("clip.demo.installed") private var installedIDs = ""
    @State private var selectedTab = 0
    @State private var search = ""
    @State private var selectedPackage: DemoPackage?
    @State private var showRepoInfo = false

    private var installed: Set<String> {
        Set(installedIDs.split(separator: ",").map(String.init))
    }
    private var visiblePackages: [DemoPackage] {
        DemoPackage.catalog.filter {
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.summary.localizedCaseInsensitiveContains(search))
            && (selectedTab != 2 || installed.contains($0.id))
        }
    }

    var body: some View {
        ZStack {
            ClipStyle.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if selectedTab == 1 { sourcesPage }
                else { packagePage }
                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedPackage) { package in
            PackageDetailSheet(package: package, isInstalled: installed.contains(package.id)) {
                toggleInstall(package)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Demo Source", isPresented: $showRepoInfo) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("packages.nocturne.demo\nThis is a local sample source. It does not fetch or install system packages.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(ClipStyle.accent.opacity(0.18))
                Image(systemName: "shippingbox.fill").font(.system(size: 19, weight: .semibold)).foregroundStyle(ClipStyle.accent)
            }.frame(width: 39, height: 39)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nocturne").font(.system(size: 18, weight: .bold, design: .rounded))
                Text("PACKAGE CATALOG").font(.system(size: 8, weight: .heavy)).tracking(1.7).foregroundStyle(ClipStyle.secondary)
            }
            Spacer()
            Button { showRepoInfo = true } label: {
                Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ClipStyle.accent).frame(width: 36, height: 36)
                    .background(ClipStyle.surface, in: Circle())
            }
        }
        .padding(.horizontal, 17).padding(.top, 12).padding(.bottom, 14)
        .background(ClipStyle.bg)
    }

    private var packagePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedTab == 2 ? "Installed" : "Explore")
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                        Text(selectedTab == 2 ? "Your locally saved demo items" : "Discover packages and extensions")
                            .font(.system(size: 11)).foregroundStyle(ClipStyle.secondary)
                    }
                    Spacer()
                    Text("DEMO").font(.system(size: 9, weight: .heavy)).tracking(1)
                        .foregroundStyle(ClipStyle.accent).padding(.horizontal, 9).padding(.vertical, 6)
                        .background(ClipStyle.accent.opacity(0.12), in: Capsule())
                }

                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").foregroundStyle(ClipStyle.secondary)
                    TextField("Search packages", text: $search)
                        .font(.system(size: 13)).autocorrectionDisabled()
                }
                .padding(.horizontal, 13).frame(height: 43)
                .background(ClipStyle.surface, in: RoundedRectangle(cornerRadius: 12))

                if selectedTab == 0 {
                    featuredBanner
                    HStack {
                        Text("ALL PACKAGES").font(.system(size: 9, weight: .heavy)).tracking(1.5).foregroundStyle(ClipStyle.secondary)
                        Spacer()
                        Text("\(visiblePackages.count) ITEMS").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(ClipStyle.secondary)
                    }.padding(.top, 2)
                }

                if visiblePackages.isEmpty {
                    ContentUnavailableView("No Packages", systemImage: "shippingbox", description: Text("Try another search or browse the catalog."))
                        .padding(.top, 30)
                } else {
                    LazyVStack(spacing: 9) {
                        ForEach(visiblePackages) { item in
                            Button { selectedPackage = item } label: {
                                PackageRow(package: item, installed: installed.contains(item.id))
                            }.buttonStyle(.plain)
                        }
                    }
                }

                Text("LOCAL DEMO CATALOG · PACKAGE ACTIONS ONLY AFFECT THIS PREVIEW")
                    .font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(ClipStyle.secondary.opacity(0.7))
                    .padding(.top, 5)
            }
            .padding(.horizontal, 16).padding(.bottom, 18)
        }
    }

    private var featuredBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles").font(.system(size: 25, weight: .medium)).foregroundStyle(.white)
                .frame(width: 52, height: 52).background(ClipStyle.accent.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover Nocturne").font(.system(size: 14, weight: .bold))
                Text("A curated collection of UI concepts").font(.system(size: 10)).foregroundStyle(.white.opacity(0.75))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.7))
        }
        .padding(13)
        .background(LinearGradient(colors: [Color(red: 0.25, green: 0.37, blue: 0.62), Color(red: 0.28, green: 0.22, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
    }

    private var sourcesPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sources").font(.system(size: 29, weight: .bold, design: .rounded))
            Text("PACKAGE REPOSITORIES").font(.system(size: 9, weight: .heavy)).tracking(1.5).foregroundStyle(ClipStyle.secondary)
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill").foregroundStyle(ClipStyle.accent).frame(width: 42, height: 42).background(ClipStyle.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nocturne Demo Source").font(.system(size: 13, weight: .bold))
                    Text("packages.nocturne.demo").font(.system(size: 10, design: .monospaced)).foregroundStyle(ClipStyle.secondary)
                    Text("LOCAL · 4 PACKAGES").font(.system(size: 8, weight: .bold)).foregroundStyle(ClipStyle.green)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill").foregroundStyle(ClipStyle.green)
            }
            .padding(13).background(ClipStyle.surface, in: RoundedRectangle(cornerRadius: 14))
            Text("This repository is bundled sample data. Adding external repositories and installing system tweaks are not supported in the App Clip.")
                .font(.system(size: 11)).foregroundStyle(ClipStyle.secondary)
            Spacer()
        }.padding(17)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton("square.grid.2x2.fill", "Explore", 0)
            tabButton("list.bullet.rectangle", "Sources", 1)
            tabButton("checkmark.circle.fill", "Installed", 2)
        }
        .padding(.top, 10).padding(.bottom, 7)
        .background(ClipStyle.surface)
        .overlay(alignment: .top) { Rectangle().fill(ClipStyle.separator).frame(height: 1) }
    }

    private func tabButton(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = index; search = "" } } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                Text(title).font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(selectedTab == index ? ClipStyle.accent : ClipStyle.secondary)
            .frame(maxWidth: .infinity).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func toggleInstall(_ package: DemoPackage) {
        var next = installed
        if next.contains(package.id) { next.remove(package.id) } else { next.insert(package.id) }
        installedIDs = next.sorted().joined(separator: ",")
    }
}

private struct PackageRow: View {
    let package: DemoPackage
    let installed: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: package.icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(package.tint)
                .frame(width: 46, height: 46).background(package.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(package.name).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                Text(package.summary).font(.system(size: 10)).foregroundStyle(ClipStyle.secondary).lineLimit(1)
                Text("\(package.section.uppercased())  ·  v\(package.version)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundStyle(ClipStyle.secondary.opacity(0.8))
            }
            Spacer(minLength: 3)
            Text(installed ? "OPEN" : "GET")
                .font(.system(size: 9, weight: .heavy)).foregroundStyle(installed ? ClipStyle.green : ClipStyle.accent)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background((installed ? ClipStyle.green : ClipStyle.accent).opacity(0.12), in: Capsule())
        }
        .padding(12).background(ClipStyle.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ClipStyle.separator, lineWidth: 1))
    }
}

private struct PackageDetailSheet: View {
    let package: DemoPackage
    let isInstalled: Bool
    let action: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ClipStyle.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Spacer()
                    Capsule().fill(Color.white.opacity(0.22)).frame(width: 34, height: 4)
                    Spacer()
                }.padding(.top, 8)
                HStack(spacing: 13) {
                    Image(systemName: package.icon).font(.system(size: 26, weight: .semibold)).foregroundStyle(package.tint)
                        .frame(width: 62, height: 62).background(package.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(package.name).font(.system(size: 20, weight: .bold))
                        Text("Version \(package.version) · by \(package.author)").font(.system(size: 10)).foregroundStyle(ClipStyle.secondary)
                    }
                }
                Divider().overlay(ClipStyle.separator)
                Text("DESCRIPTION").font(.system(size: 9, weight: .heavy)).tracking(1.3).foregroundStyle(ClipStyle.secondary)
                Text(package.description).font(.system(size: 12)).foregroundStyle(.white.opacity(0.82))
                Label("Demo action — saves this item only inside the App Clip.", systemImage: "info.circle")
                    .font(.system(size: 10)).foregroundStyle(ClipStyle.secondary)
                Spacer()
                Button {
                    action()
                    dismiss()
                } label: {
                    Text(isInstalled ? "Remove from Preview" : "Add to Preview")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(ClipStyle.accent, in: RoundedRectangle(cornerRadius: 13))
                }.buttonStyle(.plain)
            }.padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

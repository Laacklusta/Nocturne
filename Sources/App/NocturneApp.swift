import SwiftUI

@main
struct NocturneApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

enum Palette {
    static let background = Color(red: 0.035, green: 0.043, blue: 0.058)
    static let panel = Color(red: 0.075, green: 0.086, blue: 0.108)
    static let panel2 = Color(red: 0.105, green: 0.119, blue: 0.145)
    static let accent = Color(red: 0.54, green: 0.43, blue: 0.98)
    static let green = Color(red: 0.30, green: 0.82, blue: 0.57)
    static let muted = Color(red: 0.53, green: 0.57, blue: 0.65)
    static let line = Color.white.opacity(0.075)
}

struct RootView: View {
    @State private var tab = 0
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            Group {
                switch tab {
                case 0: DashboardView()
                case 1: PackagesView()
                default: SettingsView()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                tabButton("square.grid.2x2.fill", "Home", 0)
                tabButton("shippingbox.fill", "Packages", 1)
                tabButton("gearshape.fill", "Settings", 2)
            }
            .padding(.top, 12).padding(.bottom, 8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
        }
        .preferredColorScheme(.dark)
    }
    private func tabButton(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { tab = index } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(tab == index ? Palette.accent : Palette.muted)
            .frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }
}

struct DashboardView: View {
    @State private var running = false
    @State private var complete = false
    @State private var showRespring = false
    @State private var progress = 0.0
    @State private var log: [String] = ["Nocturne Demo Engine 1.0 initialized.", "Device inspection is local and read-only."]
    @State private var timer: Timer?

    private let stages = [
        "Inspecting device profile",
        "Checking simulated environment",
        "Preparing demo bootstrap",
        "Verifying mock package database",
        "Finalizing demonstration"
    ]

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    statusCard
                    actionCard
                    logCard
                    footer
                }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 22)
            }
            if showRespring { RespringSimulationView { showRespring = false } }
        }
        .onDisappear { timer?.invalidate() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("NOCTURNE").font(.system(size: 12, weight: .black, design: .rounded)).tracking(3).foregroundStyle(Palette.muted)
                Text("Dashboard").font(.system(size: 30, weight: .bold, design: .rounded))
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Palette.accent).frame(width: 6, height: 6)
                Text("DEMO MODE").font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1)
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Palette.accent.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(Palette.accent.opacity(0.25), lineWidth: 1))
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("SYSTEM STATUS", systemImage: "waveform.path.ecg")
                    .font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(Palette.muted)
                Spacer()
                Text("SIMULATED").font(.system(size: 9, weight: .bold)).foregroundStyle(Palette.accent)
            }
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle().stroke(Palette.line, lineWidth: 7).frame(width: 62, height: 62)
                    Circle().trim(from: 0, to: complete ? 1 : 0.13).stroke(Palette.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 62, height: 62)
                    Image(systemName: complete ? "checkmark" : "lock.fill").font(.system(size: 19, weight: .semibold)).foregroundStyle(complete ? Palette.green : Palette.muted)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(complete ? "Demo completed" : "Not jailbroken")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                    Text(complete ? "All simulated stages finished" : "No system modifications detected")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
            }
            Rectangle().fill(Palette.line).frame(height: 1)
            HStack {
                metric("DEVICE", UIDevice.current.model)
                Spacer()
                metric("iOS VERSION", UIDevice.current.systemVersion)
                Spacer()
                metric("MODE", "READ-ONLY")
            }
        }
        .padding(17).background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))
    }
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(Palette.muted)
            Text(value).font(.system(size: 11, weight: .semibold, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("JAILBREAK SIMULATION").font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(Palette.muted)
                Spacer()
                Text(running ? "RUNNING" : complete ? "COMPLETE" : "READY")
                    .font(.system(size: 9, weight: .bold)).foregroundStyle(running ? Palette.accent : Palette.green)
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(running ? stages[min(Int(progress * Double(stages.count)), stages.count - 1)] : complete ? "Simulation finished" : "Ready to begin")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(Palette.muted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.panel2)
                        Capsule().fill(Palette.accent).frame(width: geo.size.width * progress)
                    }
                }.frame(height: 5)
            }
            Button(action: startSimulation) {
                HStack(spacing: 9) {
                    Image(systemName: running ? "hourglass" : complete ? "arrow.clockwise" : "bolt.fill")
                    Text(running ? "Simulation running…" : complete ? "Run again" : "Start jailbreak simulation")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).frame(height: 50)
                .background(LinearGradient(colors: [Palette.accent, Color(red: 0.38, green: 0.29, blue: 0.78)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain).disabled(running)
            if complete {
                Button { showRespring = true } label: {
                    Label("Respring (simulated)", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.accent)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
            }
            Text("This is a visual demo. It does not exploit iOS, install a bootstrap, or change device security state.")
                .font(.system(size: 10)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
        }
        .padding(17).background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.line, lineWidth: 1))
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CONSOLE").font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(Palette.muted)
                Spacer()
                Circle().fill(Palette.green).frame(width: 6, height: 6)
                Text("LOCAL").font(.system(size: 9, weight: .bold)).foregroundStyle(Palette.muted)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("›").foregroundStyle(Palette.accent)
                        Text(line).foregroundStyle(Palette.muted)
                    }.font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16).background(Color.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line, lineWidth: 1))
    }
    private var footer: some View {
        Text("NOCTURNE • INTERACTIVE UI DEMONSTRATION")
            .font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(Palette.muted.opacity(0.65))
    }

    private func startSimulation() {
        timer?.invalidate()
        running = true; complete = false; progress = 0
        log = ["Nocturne Demo Engine initialized.", "Beginning simulated workflow…"]
        var step = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.85, repeats: true) { t in
            guard step < stages.count else {
                t.invalidate()
                running = false; complete = true; progress = 1
                log.append("DEMO COMPLETE — no jailbreak was performed.")
                return
            }
            log.append("[SIM] " + stages[step] + "…")
            step += 1
            progress = Double(step) / Double(stages.count)
        }
    }
}

struct RespringSimulationView: View {
    let onFinish: () -> Void
    @State private var phase = 0
    @State private var rotation = 0.0
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "apple.logo").font(.system(size: 48, weight: .light)).foregroundStyle(.white.opacity(0.9))
                ProgressView().tint(.white).scaleEffect(1.15)
                Text(phase == 0 ? "Restarting SpringBoard" : "Returning to Nocturne")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.72))
                Text("SIMULATED RESPRING").font(.system(size: 9, weight: .bold)).tracking(2).foregroundStyle(.white.opacity(0.35))
                Spacer()
            }.padding(30)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                phase = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onFinish() }
            }
        }
    }
}

struct PackagesView: View {
    private let packages: [(String, String, String, String)] = [
        ("Orion UI", "A refined interface customization preview", "1.4.2", "paintpalette.fill"),
        ("Lunar Status", "Status bar layout concept", "2.0.1", "circle.lefthalf.filled"),
        ("Velvet", "Subtle system-wide appearance preset", "1.1.0", "sparkles"),
        ("Nocturne Tools", "Demo utilities and visual components", "0.9.8", "wrench.and.screwdriver.fill")
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Packages").font(.system(size: 30, weight: .bold, design: .rounded))
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Palette.muted)
                    Text("Search demo packages").foregroundStyle(Palette.muted)
                    Spacer()
                }.padding(13).background(Palette.panel, in: RoundedRectangle(cornerRadius: 12))
                HStack {
                    Text("DEMO REPOSITORY").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundStyle(Palette.muted)
                    Spacer()
                    Text("4 PACKAGES").font(.system(size: 9, weight: .bold)).foregroundStyle(Palette.accent)
                }
                ForEach(packages, id: \.0) { item in
                    HStack(spacing: 13) {
                        Image(systemName: item.3).font(.system(size: 20)).foregroundStyle(Palette.accent)
                            .frame(width: 48, height: 48).background(Palette.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.0).font(.system(size: 14, weight: .bold))
                            Text(item.1).font(.system(size: 10)).foregroundStyle(Palette.muted).lineLimit(2)
                            Text("Version \(item.2)").font(.system(size: 9, design: .monospaced)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Text("GET").font(.system(size: 10, weight: .heavy)).foregroundStyle(Palette.accent).padding(.horizontal, 13).padding(.vertical, 7).background(Palette.accent.opacity(0.12), in: Capsule())
                    }.padding(13).background(Palette.panel, in: RoundedRectangle(cornerRadius: 15))
                }
                Text("Packages shown here are sample entries. GET does not download or install software.")
                    .font(.system(size: 10)).foregroundStyle(Palette.muted)
            }.padding(18)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings").font(.system(size: 30, weight: .bold, design: .rounded))
            setting("Application", "Nocturne Demo", "moon.stars.fill")
            setting("Build", "1.0.0 • Preview", "number")
            setting("Device changes", "Disabled", "lock.fill")
            setting("Respring", "Visual simulation only", "arrow.clockwise")
            Spacer()
            Text("Nocturne is an educational UI simulator. It is not affiliated with Dopamine, Sileo, or Zebra.")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }.padding(18).padding(.top, 10)
    }
    private func setting(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Palette.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(value).font(.system(size: 10)).foregroundStyle(Palette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(Palette.muted)
        }.padding(14).background(Palette.panel, in: RoundedRectangle(cornerRadius: 13))
    }
}

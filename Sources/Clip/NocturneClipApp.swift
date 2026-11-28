import SwiftUI

@main
struct NocturneClipApp: App {
    var body: some Scene {
        WindowGroup { ClipHomeView() }
    }
}

struct ClipHomeView: View {
    private let items: [(String, String, String)] = [
        ("Orion UI", "Interface customization concept", "paintpalette.fill"),
        ("Lunar Status", "Status bar appearance preview", "circle.lefthalf.filled"),
        ("Velvet", "A softer visual theme", "sparkles")
    ]
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.043, blue: 0.058).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOCTURNE").font(.system(size: 10, weight: .black)).tracking(3).foregroundStyle(.white.opacity(0.5))
                            Text("Preview").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        }
                        Spacer()
                        Text("APP CLIP").font(.system(size: 9, weight: .heavy)).tracking(1).foregroundStyle(Color.purple).padding(9).background(Color.purple.opacity(0.15), in: Capsule())
                    }
                    Text("A compact look at the Nocturne demo package catalog.")
                        .font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
                    ForEach(items, id: \.0) { item in
                        HStack(spacing: 13) {
                            Image(systemName: item.2).font(.system(size: 20)).foregroundStyle(Color.purple)
                                .frame(width: 48, height: 48).background(Color.purple.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.0).font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                                Text(item.1).font(.system(size: 10)).foregroundStyle(.white.opacity(0.55))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.35))
                        }.padding(13).background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15))
                    }
                    Text("DEMO CATALOG • NO INSTALLS OR DEVICE MODIFICATIONS")
                        .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.4))
                }.padding(20)
            }
        }.preferredColorScheme(.dark)
    }
}

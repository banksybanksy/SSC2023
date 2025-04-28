import SwiftUI

@main
struct AnatoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var learnedAndStudiedTerms = LearnedAndStudiedTerms()
    @State private var shouldShowWhatsNew = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverTab(generateHapticFeedback: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            })
            .environmentObject(learnedAndStudiedTerms)
            .tag(0)
            .tabItem {
                VStack(spacing: 4) {
                    Image(systemName: "cursorarrow.rays")
                        .imageScale(.large)
                    Text("Discover")
                        .font(.caption2)
                }
            }
            BrowseTab()
                .environmentObject(learnedAndStudiedTerms)
                .tag(1)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: "heart.text.square")
                            .imageScale(.large)
                        Text("Browse")
                            .font(.caption2)
                    }
                }
            ChallengeView()
                .environmentObject(learnedAndStudiedTerms)
                .tag(2)
                .tabItem {
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .imageScale(.large)
                        Text("Challenge")
                            .font(.caption2)
                    }
                }
        }
        .sheet(isPresented: $shouldShowWhatsNew) {
            WhatsNewView(shouldShow: $shouldShowWhatsNew)
        }
        .onAppear {
            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
            if !hasLaunchedBefore {
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                shouldShowWhatsNew = true
            }
        }
    }
}

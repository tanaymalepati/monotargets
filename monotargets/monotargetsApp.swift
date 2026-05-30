import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct monotargetsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store           = AppStore()
    @State private var isAuthenticated = false
    @State private var checkedSession  = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !checkedSession {
                    // Splash while we check stored session
                    SplashView()
                } else if isAuthenticated {
                    ContentView()
                        .environment(store)
                        .transition(.opacity)
                } else {
                    AuthView(onAuthenticated: {
                        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                            isAuthenticated = true
                        }
                        // Start background sync after login
                        Task { await store.syncToSupabase() }
                    })
                    .environment(store)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: checkedSession)
            .animation(.easeInOut(duration: 0.35), value: isAuthenticated)
            .task {
                // Check for a stored Supabase session
                if let _ = await SupabaseClient.shared.loadStoredSession() {
                    // Pull latest cloud data
                    if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                        await store.replaceData(with: remote)
                    }
                    isAuthenticated = true
                }
                checkedSession = true
            }
        }
    }
}

// MARK: - Splash

private struct SplashView: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "target")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(Mono.C.accent)
                    .scaleEffect(pulse ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                Text("MONOTARGETS")
                    .font(Mono.T.mono(16, .bold))
                    .foregroundColor(Mono.C.text)
                    .tracking(4)
            }
            .onAppear { pulse = true }
        }
    }
}

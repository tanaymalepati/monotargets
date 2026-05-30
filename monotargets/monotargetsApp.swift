import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask { .portrait }
}

@main
struct monotargetsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store     = AppStore()
    @State private var authState = AuthState()

    // launch states
    @State private var launchChecked  = false
    @State private var loadingData    = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !launchChecked {
                    SplashView()
                } else if !authState.isAuthenticated {
                    AuthView(onAuthenticated: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            authState.isAuthenticated = true
                        }
                        // pull cloud data after sign-in
                        Task {
                            if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                                await store.replaceData(with: remote)
                            }
                        }
                    })
                    .environment(store)
                    .environment(authState)
                    .transition(.opacity)
                } else {
                    ContentView()
                        .environment(store)
                        .environment(authState)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: launchChecked)
            .animation(.easeInOut(duration: 0.3), value: authState.isAuthenticated)
            .task { await checkSession() }
        }
    }

    private func checkSession() async {
        // Restore stored session if available
        if let _ = await SupabaseClient.shared.loadStoredSession() {
            if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                await store.replaceData(with: remote)
            }
            authState.isAuthenticated = true
        }
        launchChecked = true
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
        }
        .onAppear { pulse = true }
    }
}

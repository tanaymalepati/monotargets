import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct monotargetsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = AppStore()

    // True once we've finished the async launch check
    @State private var launchChecked  = false
    // True when the user should see the main app (either logged in or offline)
    @State private var showMainApp    = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !launchChecked {
                    SplashView()
                        .transition(.opacity)
                } else if showMainApp {
                    ContentView()
                        .environment(store)
                        .transition(.opacity)
                } else {
                    AuthView(onAuthenticated: {
                        withAnimation(.easeInOut(duration: 0.35)) { showMainApp = true }
                    })
                    .environment(store)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: launchChecked)
            .animation(.easeInOut(duration: 0.3), value: showMainApp)
            .task { await checkLaunchState() }
        }
    }

    private func checkLaunchState() async {
        // 1. Already chose offline mode in a previous session
        if UserDefaults.standard.bool(forKey: "offline_mode") {
            launchChecked = true
            showMainApp   = true
            return
        }

        // 2. Stored Supabase session
        if let _ = await SupabaseClient.shared.loadStoredSession() {
            // Pull latest cloud data before showing the app
            if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                await store.replaceData(with: remote)
            }
            launchChecked = true
            showMainApp   = true
            return
        }

        // 3. No session, no offline flag → show auth
        launchChecked = true
        showMainApp   = false
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

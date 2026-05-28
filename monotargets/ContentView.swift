import SwiftUI

struct ContentView: View {
    @AppStorage("onboarding_done") private var onboardingDone = false

    var body: some View {
        Group {
            if onboardingDone {
                RootView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .tint(Mono.C.text)
    }
}

#Preview {
    let store = AppStore()
    store.transactions = Transaction.samples
    store.savingsItems = SavingsItem.samples
    return ContentView()
        .environment(store)
}

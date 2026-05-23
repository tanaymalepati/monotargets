import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
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

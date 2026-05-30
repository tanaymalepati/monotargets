import Foundation

// Single source of truth for whether the user is logged in.
// Injected into the environment so any view can trigger sign-out / account deletion.

@Observable
final class AuthState {
    var isAuthenticated: Bool = false

    func signOut(store: AppStore) async {
        await SupabaseClient.shared.signOut()
        await store.clearAll()
        await MainActor.run { isAuthenticated = false }
    }

    func deleteAccount(store: AppStore) async throws {
        try await SupabaseClient.shared.deleteAccount()
        await store.clearAll()
        await MainActor.run { isAuthenticated = false }
    }
}

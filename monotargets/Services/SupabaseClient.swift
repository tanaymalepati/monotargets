import Foundation

// MARK: - Supabase Configuration

enum Supabase {
    static let url     = "https://htebllrggksxbbgdyuso.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0ZWJsbHJnZ2tzeGJiZ2R5dXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNTM1NjUsImV4cCI6MjA5NTYyOTU2NX0.eP-Uhaj6rzviWe9U-NZk2rVpH-5jZoRr9dIJ0PrwzsA"
}

// MARK: - Auth Models

struct AuthResponse: Codable {
    let accessToken:  String
    let refreshToken: String
    let user:         SupabaseUser
    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id:    String
    let email: String?
}

struct AuthError: Codable, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Session persistence

struct StoredSession: Codable {
    let accessToken:  String
    let refreshToken: String
    let userID:       String
    let email:        String?
}

// MARK: - Client

actor SupabaseClient {
    static let shared = SupabaseClient()

    private var accessToken:  String?
    private var refreshToken: String?
    private(set) var currentUserID: String?
    private(set) var currentEmail:  String?

    private let sessionKey = "supabase_session"

    // ── Session ────────────────────────────────────────────

    func loadStoredSession() -> StoredSession? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(StoredSession.self, from: data)
        else { return nil }
        accessToken    = session.accessToken
        refreshToken   = session.refreshToken
        currentUserID  = session.userID
        currentEmail   = session.email
        return session
    }

    var isSignedIn: Bool { accessToken != nil }

    private func persistSession(_ auth: AuthResponse) {
        accessToken   = auth.accessToken
        refreshToken  = auth.refreshToken
        currentUserID = auth.user.id
        currentEmail  = auth.user.email
        let stored = StoredSession(
            accessToken:  auth.accessToken,
            refreshToken: auth.refreshToken,
            userID:       auth.user.id,
            email:        auth.user.email
        )
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func clearSession() {
        accessToken   = nil
        refreshToken  = nil
        currentUserID = nil
        currentEmail  = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    // ── Auth endpoints ─────────────────────────────────────

    func signUp(email: String, password: String, displayName: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email":    email,
            "password": password,
            "data":     ["display_name": displayName]
        ]
        let auth: AuthResponse = try await post(path: "/auth/v1/signup", body: body, auth: false)
        persistSession(auth)
        return auth
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["email": email, "password": password]
        let auth: AuthResponse = try await post(
            path: "/auth/v1/token?grant_type=password", body: body, auth: false
        )
        persistSession(auth)
        return auth
    }

    func signOut() async throws {
        guard let token = accessToken else { clearSession(); return }
        var req = request(path: "/auth/v1/logout", method: "POST")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)
        clearSession()
    }

    func refreshSession() async throws {
        guard let rt = refreshToken else { throw AuthError(message: "No refresh token") }
        let body: [String: Any] = ["refresh_token": rt]
        let auth: AuthResponse = try await post(
            path: "/auth/v1/token?grant_type=refresh_token", body: body, auth: false
        )
        persistSession(auth)
    }

    // ── Vault data ─────────────────────────────────────────

    func uploadVaultData(_ data: VaultData) async throws {
        guard let uid = currentUserID else { throw AuthError(message: "Not signed in") }
        let encoded = try JSONEncoder().encode(data)
        guard let payload = try? JSONSerialization.jsonObject(with: encoded) else {
            throw AuthError(message: "Encode failed")
        }
        let body: [String: Any] = ["user_id": uid, "payload": payload]
        try await upsert(table: "vault_data", body: body, onConflict: "user_id")
    }

    func downloadVaultData() async throws -> VaultData? {
        guard let uid = currentUserID else { return nil }
        let rows: [[String: Any]] = try await select(
            table: "vault_data",
            query: "user_id=eq.\(uid)&select=payload"
        )
        guard let first = rows.first,
              let payload = first["payload"],
              let jsonData = try? JSONSerialization.data(withJSONObject: payload)
        else { return nil }
        return try JSONDecoder().decode(VaultData.self, from: jsonData)
    }

    // ── Profile ────────────────────────────────────────────

    func updateProfile(displayName: String) async throws {
        guard let uid = currentUserID else { return }
        let body: [String: Any] = ["id": uid, "display_name": displayName]
        try await upsert(table: "profiles", body: body, onConflict: "id")
    }

    // ── HTTP helpers ────────────────────────────────────────

    private func request(path: String, method: String) -> URLRequest {
        var req = URLRequest(url: URL(string: Supabase.url + path)!)
        req.httpMethod = method
        req.setValue(Supabase.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func post<T: Decodable>(path: String, body: [String: Any], auth: Bool) async throws -> T {
        var req = request(path: path, method: "POST")
        if !auth { req.setValue(nil, forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let err = (try? JSONDecoder().decode(AuthError.self, from: data))
                ?? AuthError(message: "HTTP \(http.statusCode)")
            throw err
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func upsert(table: String, body: [String: Any], onConflict: String) async throws {
        var req = request(path: "/rest/v1/\(table)", method: "POST")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        req.setValue("on_conflict=\(onConflict)", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError(message: msg)
        }
    }

    private func select(table: String, query: String) async throws -> [[String: Any]] {
        var req = request(path: "/rest/v1/\(table)?\(query)", method: "GET")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw AuthError(message: msg)
        }
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }
}

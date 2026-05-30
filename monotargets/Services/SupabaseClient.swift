import Foundation

// MARK: - Configuration

enum Supabase {
    static let url     = "https://htebllrggksxbbgdyuso.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0ZWJsbHJnZ2tzeGJiZ2R5dXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNTM1NjUsImV4cCI6MjA5NTYyOTU2NX0.eP-Uhaj6rzviWe9U-NZk2rVpH-5jZoRr9dIJ0PrwzsA"

    // Internal auth email for a username — never shown to the user
    static func authEmail(for username: String) -> String {
        "\(username.lowercased())@monotargets.local"
    }
}

// MARK: - Username Validation

enum UsernameValidation {
    case valid
    case tooShort
    case invalidChars
    case leadingTrailingUnderscore
    case onlyNumbers
    case taken

    var message: String {
        switch self {
        case .valid:                     return ""
        case .tooShort:                  return "At least 5 characters"
        case .invalidChars:              return "Letters, numbers and _ only"
        case .leadingTrailingUnderscore: return "Can't start or end with _"
        case .onlyNumbers:               return "Must contain at least one letter"
        case .taken:                     return "Username taken — pick another or sign in"
        }
    }

    static func check(_ raw: String) -> UsernameValidation {
        guard raw.count >= 5 else { return .tooShort }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return .invalidChars }
        guard !raw.hasPrefix("_") && !raw.hasSuffix("_") else { return .leadingTrailingUnderscore }
        guard !raw.allSatisfy(\.isNumber) else { return .onlyNumbers }
        return .valid
    }
}

// MARK: - Auth Models

struct AuthResponse: Codable {
    let accessToken:  String?
    let refreshToken: String?
    let user:         SupabaseUser?
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

// MARK: - Auth Errors

enum AuthClientError: LocalizedError {
    case userNotFound
    case usernameTaken
    case wrongPassword
    case emailConfirmationRequired
    case notSignedIn
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:              return "No account found with that username or email."
        case .usernameTaken:             return "Username already taken — pick another or sign in."
        case .wrongPassword:             return "Incorrect password."
        case .emailConfirmationRequired: return "Please confirm your email, then try signing in."
        case .notSignedIn:               return "You're not signed in."
        case .custom(let m):             return m
        }
    }
}

// MARK: - Session Storage

struct StoredSession: Codable {
    let accessToken:  String
    let refreshToken: String
    let userID:       String
    let username:     String
    let email:        String?
}

// MARK: - Supabase Client

actor SupabaseClient {
    static let shared = SupabaseClient()

    private var accessToken:  String?
    private var refreshToken: String?
    private(set) var currentUserID:  String?
    private(set) var currentUsername: String?
    private(set) var currentEmail:    String?

    private let sessionKey = "supabase_session_v2"

    // ── Session ─────────────────────────────────────────────

    var isSignedIn: Bool { accessToken != nil }

    func loadStoredSession() -> StoredSession? {
        guard
            let data = UserDefaults.standard.data(forKey: sessionKey),
            let s    = try? JSONDecoder().decode(StoredSession.self, from: data)
        else { return nil }
        accessToken      = s.accessToken
        refreshToken     = s.refreshToken
        currentUserID    = s.userID
        currentUsername  = s.username
        currentEmail     = s.email
        return s
    }

    private func persist(_ auth: AuthResponse, username: String, realEmail: String?) {
        guard let at = auth.accessToken, let rt = auth.refreshToken, let u = auth.user else { return }
        accessToken     = at
        refreshToken    = rt
        currentUserID   = u.id
        currentUsername = username
        currentEmail    = realEmail
        let s = StoredSession(accessToken: at, refreshToken: rt,
                              userID: u.id, username: username, email: realEmail)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    func clearSession() {
        accessToken     = nil
        refreshToken    = nil
        currentUserID   = nil
        currentUsername = nil
        currentEmail    = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    // ── Username availability ────────────────────────────────

    func isUsernameAvailable(_ username: String) async -> Bool {
        let encoded = username.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        let rows: [[String: Any]] = (try? await select(
            table: "profiles",
            query: "username=ilike.\(encoded)&select=id",
            requiresAuth: false
        )) ?? []
        return rows.isEmpty
    }

    // ── Sign Up ──────────────────────────────────────────────

    func signUp(username: String, password: String, realEmail: String?) async throws {
        // 1. Validate username format
        let validation = UsernameValidation.check(username)
        guard validation == .valid else { throw AuthClientError.custom(validation.message) }

        // 2. Check availability
        let available = await isUsernameAvailable(username)
        guard available else { throw AuthClientError.usernameTaken }

        // 3. Create auth user with generated internal email
        let authEmail = Supabase.authEmail(for: username)
        var meta: [String: String] = ["username": username]
        if let real = realEmail, !real.trimmingCharacters(in: .whitespaces).isEmpty {
            meta["real_email"] = real.trimmingCharacters(in: .whitespaces).lowercased()
            meta["display_name"] = username
        } else {
            meta["display_name"] = username
        }

        let body: [String: Any] = ["email": authEmail, "password": password, "data": meta]
        let auth: AuthResponse = try await post(path: "/auth/v1/signup", body: body, requiresAuth: false)

        // Check if email confirmation is blocking us
        if auth.accessToken == nil {
            throw AuthClientError.emailConfirmationRequired
        }

        persist(auth, username: username, realEmail: realEmail)

        // Save display name locally
        UserDefaults.standard.set(username, forKey: "user_name")
    }

    // ── Sign In ──────────────────────────────────────────────

    func signIn(usernameOrEmail: String, password: String) async throws {
        let trimmed = usernameOrEmail.trimmingCharacters(in: .whitespaces)
        let isEmail = trimmed.contains("@")

        let (authEmail, username): (String, String)

        if isEmail {
            // Lookup username from profiles by real_email
            let encoded = trimmed.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            let rows: [[String: Any]] = (try? await select(
                table: "profiles",
                query: "real_email=eq.\(encoded)&select=username",
                requiresAuth: false
            )) ?? []
            guard let first = rows.first, let uname = first["username"] as? String else {
                throw AuthClientError.userNotFound
            }
            username  = uname
            authEmail = Supabase.authEmail(for: uname)
        } else {
            // Check username exists before attempting sign-in
            let exists = !(await isUsernameAvailable(trimmed))
            guard exists else { throw AuthClientError.userNotFound }
            username  = trimmed
            authEmail = Supabase.authEmail(for: trimmed)
        }

        // Attempt sign-in
        let body: [String: Any] = ["email": authEmail, "password": password]
        do {
            let auth: AuthResponse = try await post(
                path: "/auth/v1/token?grant_type=password",
                body: body, requiresAuth: false
            )
            // Fetch real_email from profiles
            let realEmail = await fetchRealEmail(username: username)
            persist(auth, username: username, realEmail: realEmail)
            UserDefaults.standard.set(username, forKey: "user_name")
        } catch let err as AuthClientError {
            throw err
        } catch {
            // Map generic Supabase invalid_credentials to wrong password (user exists but pw wrong)
            throw AuthClientError.wrongPassword
        }
    }

    // ── Sign Out ─────────────────────────────────────────────

    func signOut() async {
        if let token = accessToken {
            var req = makeRequest(path: "/auth/v1/logout", method: "POST")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: req)
        }
        clearSession()
    }

    // ── Vault sync ───────────────────────────────────────────

    func uploadVaultData(_ data: VaultData) async throws {
        guard let uid = currentUserID else { throw AuthClientError.notSignedIn }
        let encoded = try JSONEncoder().encode(data)
        guard let payload = try? JSONSerialization.jsonObject(with: encoded) else { return }
        let body: [String: Any] = ["user_id": uid, "payload": payload]
        try await upsert(table: "vault_data", body: body, onConflict: "user_id")
    }

    func downloadVaultData() async throws -> VaultData? {
        guard let uid = currentUserID else { return nil }
        let rows: [[String: Any]] = try await select(
            table: "vault_data",
            query: "user_id=eq.\(uid)&select=payload"
        )
        guard
            let first   = rows.first,
            let payload = first["payload"],
            let jsonData = try? JSONSerialization.data(withJSONObject: payload)
        else { return nil }
        return try? JSONDecoder().decode(VaultData.self, from: jsonData)
    }

    // ── Helpers ──────────────────────────────────────────────

    private func fetchRealEmail(username: String) async -> String? {
        let encoded = username.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        let rows: [[String: Any]] = (try? await select(
            table: "profiles",
            query: "username=ilike.\(encoded)&select=real_email",
            requiresAuth: false
        )) ?? []
        return rows.first?["real_email"] as? String
    }

    private func makeRequest(path: String, method: String, requiresAuth: Bool = true) -> URLRequest {
        var req = URLRequest(url: URL(string: Supabase.url + path)!)
        req.httpMethod = method
        req.setValue(Supabase.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if requiresAuth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func post<T: Decodable>(path: String, body: [String: Any], requiresAuth: Bool = true) async throws -> T {
        var req = makeRequest(path: path, method: "POST", requiresAuth: requiresAuth)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = parseErrorMessage(from: data, status: http.statusCode)
            throw AuthClientError.custom(msg)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func upsert(table: String, body: [String: Any], onConflict: String) async throws {
        var req = makeRequest(path: "/rest/v1/\(table)", method: "POST")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        req.setValue("on_conflict=\(onConflict)", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw AuthClientError.custom(parseErrorMessage(from: data, status: http.statusCode))
        }
    }

    func select(table: String, query: String, requiresAuth: Bool = true) async throws -> [[String: Any]] {
        let req = makeRequest(path: "/rest/v1/\(table)?\(query)", method: "GET", requiresAuth: requiresAuth)
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
    }

    private func parseErrorMessage(from data: Data, status: Int) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "HTTP \(status)"
        }
        let raw = (json["msg"] as? String)
            ?? (json["error_description"] as? String)
            ?? (json["message"] as? String)
            ?? (json["error"] as? String)
            ?? "HTTP \(status)"

        // Map raw Supabase errors to friendly strings
        let lower = raw.lowercased()
        if lower.contains("invalid login") || lower.contains("invalid_credentials") {
            return "Incorrect password."
        }
        if lower.contains("email not confirmed") {
            return "Email confirmation required. Disable 'Confirm email' in Supabase Auth settings."
        }
        return raw
    }
}

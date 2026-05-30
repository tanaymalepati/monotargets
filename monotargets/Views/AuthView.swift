import SwiftUI

// MARK: - Auth View

struct AuthView: View {
    @Environment(AppStore.self) private var store
    let onAuthenticated: () -> Void

    @State private var mode: Mode = .signIn
    @State private var username = ""
    @State private var password = ""
    @State private var email    = ""       // optional, sign-up only
    @State private var showEmail = false   // reveal optional email field
    @State private var isLoading   = false
    @State private var errorMsg: String?
    @State private var usernameState: FieldState = .idle
    @State private var appeared = false

    // focus management
    @FocusState private var focus: Field?
    enum Field: Hashable { case username, password, email }
    enum Mode { case signIn, signUp }
    enum FieldState: Equatable { case idle, checking, valid, invalid(String) }

    // ── Validation ─────────────────────────────────────────

    private var usernameValidation: UsernameValidation {
        UsernameValidation.check(username)
    }

    private var canSubmit: Bool {
        guard password.count >= 6 else { return false }
        if mode == .signUp {
            return usernameValidation == .valid && usernameState != .invalid("")
        } else {
            return username.count >= 1
        }
    }

    // ── Body ───────────────────────────────────────────────

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            // Soft teal glow
            RadialGradient(
                colors: [Mono.C.accent.opacity(0.10), .clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Logo ────────────────────────────────
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Mono.C.surfaceTop)
                                .frame(width: 80, height: 80)
                            Image(systemName: "target")
                                .font(.system(size: 38, weight: .light))
                                .foregroundColor(Mono.C.accent)
                        }
                        Text("MONOTARGETS")
                            .font(Mono.T.mono(18, .bold))
                            .foregroundColor(Mono.C.text)
                            .tracking(4)
                        Text("Your savings, organised.")
                            .font(Mono.T.mono(12, .regular))
                            .foregroundColor(Mono.C.textTert)
                    }
                    .padding(.top, 64)
                    .padding(.bottom, 44)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)
                    .animation(.spring(duration: 0.55, bounce: 0.2).delay(0.05), value: appeared)

                    // ── Mode switcher ───────────────────────
                    HStack(spacing: 4) {
                        modeButton(.signIn, label: "Sign In")
                        modeButton(.signUp, label: "Sign Up")
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Mono.C.surfaceTop))
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.45, bounce: 0.2).delay(0.1), value: appeared)

                    // ── Form ────────────────────────────────
                    VStack(spacing: 0) {
                        // Username / email-or-username input
                        AuthInputRow(
                            icon: mode == .signIn ? "at" : "person",
                            placeholder: mode == .signIn ? "Username or email" : "Username",
                            text: $username,
                            keyboard: .default,
                            isLowercase: true,
                            isFocused: focus == .username,
                            trailingView: { usernameTrailing },
                            onSubmit: { focus = .password }
                        )
                        .focused($focus, equals: .username)
                        .onChange(of: username) { _, new in
                            if mode == .signUp { scheduleUsernameCheck(new) }
                            errorMsg = nil
                        }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        // Password
                        AuthInputRow(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            isFocused: focus == .password,
                            trailingView: {
                                if !password.isEmpty {
                                    AnyView(
                                        Text("\(password.count)")
                                            .font(Mono.T.mono(10, .medium))
                                            .foregroundColor(password.count >= 6 ? Mono.C.accent : Mono.C.textDim)
                                    )
                                } else {
                                    AnyView(EmptyView())
                                }
                            },
                            onSubmit: {
                                if mode == .signUp && showEmail { focus = .email }
                                else if canSubmit { submit() }
                            }
                        )
                        .focused($focus, equals: .password)
                        .onChange(of: password) { _, _ in errorMsg = nil }

                        // Optional email (sign-up only)
                        if mode == .signUp {
                            if showEmail {
                                MonoDivider().padding(.horizontal, Mono.S.md)
                                AuthInputRow(
                                    icon: "envelope",
                                    placeholder: "Email (optional)",
                                    text: $email,
                                    keyboard: .emailAddress,
                                    isLowercase: true,
                                    isFocused: focus == .email,
                                    trailingView: {
                                        if !email.isEmpty {
                                            AnyView(
                                                Button { email = ""; focus = nil } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(Mono.C.textDim)
                                                }
                                                .buttonStyle(.plain)
                                            )
                                        } else { AnyView(EmptyView()) }
                                    },
                                    onSubmit: { if canSubmit { submit() } }
                                )
                                .focused($focus, equals: .email)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            } else {
                                // "Add email" nudge
                                Button {
                                    withAnimation(.spring(duration: 0.3, bounce: 0.25)) { showEmail = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focus = .email }
                                    Haptic.light()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .semibold))
                                        Text("Add email (optional)")
                                            .font(Mono.T.mono(11, .medium))
                                    }
                                    .foregroundColor(Mono.C.textDim)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Mono.S.md)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .fill(Mono.C.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                                    .strokeBorder(Mono.C.border, lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.45, bounce: 0.2).delay(0.15), value: appeared)

                    // Username hint (sign-up)
                    if mode == .signUp && !username.isEmpty {
                        usernameHint
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Error message
                    if let err = errorMsg {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(err)
                                .font(Mono.T.mono(12, .regular))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(Mono.C.red)
                        .padding(.horizontal, 28)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Submit ─────────────────────────────
                    Button(action: submit) {
                        ZStack {
                            if isLoading {
                                ProgressView().tint(Mono.C.bg).scaleEffect(0.85)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: mode == .signIn
                                          ? "arrow.right.circle.fill"
                                          : "person.badge.plus")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(mode == .signIn ? "Sign In" : "Create Account")
                                        .font(Mono.T.mono(15, .semibold))
                                }
                            }
                        }
                        .foregroundColor(canSubmit ? Mono.C.bg : Mono.C.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .fill(canSubmit ? Mono.C.text : Mono.C.surfaceTop)
                        )
                    }
                    .disabled(!canSubmit || isLoading)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.45, bounce: 0.2).delay(0.2), value: appeared)
                    .animation(.spring(duration: 0.25), value: canSubmit)


                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear { appeared = true }
        .onTapGesture { focus = nil }
        .animation(.spring(duration: 0.28, bounce: 0.25), value: mode)
        .animation(.spring(duration: 0.25), value: errorMsg != nil)
        .animation(.spring(duration: 0.3, bounce: 0.2), value: showEmail)
    }

    // ── Mode button ─────────────────────────────────────────

    private func modeButton(_ m: Mode, label: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.28, bounce: 0.3)) {
                mode = m
                errorMsg = nil
                showEmail = false
                usernameState = .idle
            }
            Haptic.select()
        } label: {
            Text(label)
                .font(Mono.T.mono(13, .semibold))
                .foregroundColor(mode == m ? Mono.C.bg : Mono.C.textSec)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(mode == m ? Mono.C.text : .clear)
                )
        }
        .buttonStyle(.plain)
    }

    // ── Username trailing indicator ─────────────────────────

    @ViewBuilder
    private var usernameTrailing: some View {
        switch usernameState {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView().scaleEffect(0.7).tint(Mono.C.textDim)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Mono.C.accent)
                .transition(.scale.combined(with: .opacity))
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Mono.C.red)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // ── Username hint row ───────────────────────────────────

    @ViewBuilder
    private var usernameHint: some View {
        let v = usernameValidation
        if v != .valid {
            Label(v.message, systemImage: "info.circle")
                .font(Mono.T.mono(11, .regular))
                .foregroundColor(Mono.C.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if case .invalid(let msg) = usernameState, !msg.isEmpty {
            Label(msg, systemImage: "xmark.circle")
                .font(Mono.T.mono(11, .regular))
                .foregroundColor(Mono.C.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if usernameState == .valid {
            Label("@\(username) is available!", systemImage: "checkmark.circle")
                .font(Mono.T.mono(11, .medium))
                .foregroundColor(Mono.C.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // ── Username availability debounce ──────────────────────

    @State private var usernameCheckTask: Task<Void, Never>?

    private func scheduleUsernameCheck(_ raw: String) {
        usernameCheckTask?.cancel()
        let v = UsernameValidation.check(raw)
        guard v == .valid else {
            withAnimation { usernameState = .idle }
            return
        }
        withAnimation { usernameState = .checking }
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else { return }
            let available = await SupabaseClient.shared.isUsernameAvailable(raw)
            await MainActor.run {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    usernameState = available ? .valid : .invalid("Username taken")
                }
            }
        }
    }

    // ── Submit ──────────────────────────────────────────────

    private func submit() {
        guard canSubmit, !isLoading else { return }
        focus = nil
        isLoading = true
        errorMsg  = nil
        Haptic.medium()

        Task {
            do {
                if mode == .signUp {
                    let realEmail = showEmail && !email.trimmingCharacters(in: .whitespaces).isEmpty
                        ? email.trimmingCharacters(in: .whitespaces)
                        : nil
                    try await SupabaseClient.shared.signUp(
                        username: username.trimmingCharacters(in: .whitespaces).lowercased(),
                        password: password,
                        realEmail: realEmail
                    )
                } else {
                    try await SupabaseClient.shared.signIn(
                        usernameOrEmail: username.trimmingCharacters(in: .whitespaces),
                        password: password
                    )
                    // Pull cloud data on sign-in
                    if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                        await store.replaceData(with: remote)
                    }
                }
                await MainActor.run {
                    isLoading = false
                    Haptic.success()
                    // Clear offline mode flag since they're now logged in
                    UserDefaults.standard.removeObject(forKey: "offline_mode")
                    onAuthenticated()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMsg  = error.localizedDescription
                    Haptic.medium()
                }
            }
        }
    }
}

// MARK: - Reusable Input Row

struct AuthInputRow<Trailing: View>: View {
    let icon:        String
    let placeholder: String
    @Binding var text: String
    var keyboard:    UIKeyboardType = .default
    var isSecure:    Bool = false
    var isLowercase: Bool = false
    var isFocused:   Bool = false
    @ViewBuilder var trailingView: () -> Trailing
    var onSubmit:    () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isFocused ? Mono.C.accent : Mono.C.textTert)
                .frame(width: 20)
                .animation(.spring(duration: 0.2), value: isFocused)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .onSubmit(onSubmit)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(isLowercase ? .never : .words)
                        .onSubmit(onSubmit)
                }
            }
            .font(Mono.T.mono(14, .regular))
            .foregroundColor(Mono.C.text)
            .tint(Mono.C.accent)

            trailingView()
        }
        .padding(Mono.S.md)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
    }
}

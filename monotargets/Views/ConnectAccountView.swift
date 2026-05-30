import SwiftUI

// MARK: - Connect Account View
// Shown from Settings when the user is in offline mode and wants to
// create / sign into an account. On success, local data is uploaded to the cloud.

struct ConnectAccountView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss)    private var dismiss
    let onConnected: () -> Void

    @State private var mode:     Mode = .signUp
    @State private var username  = ""
    @State private var password  = ""
    @State private var email     = ""
    @State private var showEmail = false
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var usernameState: AuthView.FieldState = .idle

    @FocusState private var focus: AuthView.Field?
    enum Mode { case signIn, signUp }

    private var canSubmit: Bool {
        guard password.count >= 6 else { return false }
        if mode == .signUp { return UsernameValidation.check(username) == .valid }
        return username.count >= 1
    }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 34, weight: .light))
                            .foregroundColor(Mono.C.accent)
                            .padding(.bottom, 4)
                        Text("Connect Account")
                            .font(Mono.T.mono(18, .bold))
                            .foregroundColor(Mono.C.text)
                        Text("Your existing data will be uploaded to the cloud.")
                            .font(Mono.T.mono(12, .regular))
                            .foregroundColor(Mono.C.textTert)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)

                    // Mode toggle
                    HStack(spacing: 4) {
                        ForEach([("New Account", Mode.signUp), ("Sign In", Mode.signIn)], id: \.0) { label, m in
                            Button {
                                withAnimation(.spring(duration: 0.25, bounce: 0.3)) { mode = m; errorMsg = nil }
                                Haptic.select()
                            } label: {
                                Text(label)
                                    .font(Mono.T.mono(13, .semibold))
                                    .foregroundColor(mode == m ? Mono.C.bg : Mono.C.textSec)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(mode == m ? Mono.C.text : .clear))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Mono.C.surfaceTop))
                    .padding(.horizontal, 24)

                    // Form
                    VStack(spacing: 0) {
                        AuthInputRow(
                            icon: mode == .signIn ? "at" : "person",
                            placeholder: mode == .signIn ? "Username or email" : "Choose a username",
                            text: $username,
                            isLowercase: true,
                            isFocused: focus == .username,
                            trailingView: {
                                if mode == .signUp {
                                    AnyView(usernameIndicator)
                                } else {
                                    AnyView(EmptyView())
                                }
                            },
                            onSubmit: { focus = .password }
                        )
                        .focused($focus, equals: .username)
                        .onChange(of: username) { _, new in
                            if mode == .signUp { scheduleCheck(new) }
                            errorMsg = nil
                        }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        AuthInputRow(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            isFocused: focus == .password,
                            trailingView: { AnyView(EmptyView()) },
                            onSubmit: { if mode == .signUp && showEmail { focus = .email } else if canSubmit { submit() } }
                        )
                        .focused($focus, equals: .password)
                        .onChange(of: password) { _, _ in errorMsg = nil }

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
                                    trailingView: { AnyView(EmptyView()) },
                                    onSubmit: { if canSubmit { submit() } }
                                )
                                .focused($focus, equals: .email)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            } else {
                                Button {
                                    withAnimation(.spring(duration: 0.3, bounce: 0.25)) { showEmail = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focus = .email }
                                    Haptic.light()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
                                        Text("Add email (optional)").font(Mono.T.mono(11, .medium))
                                    }
                                    .foregroundColor(Mono.C.textDim)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Mono.S.md).padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .fill(Mono.C.surface)
                            .overlay(RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                                .strokeBorder(Mono.C.border, lineWidth: 0.5))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .animation(.spring(duration: 0.3, bounce: 0.2), value: showEmail)

                    if let err = errorMsg {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(err).font(Mono.T.mono(12, .regular))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(Mono.C.red)
                        .padding(.horizontal, 28).padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Button(action: submit) {
                        ZStack {
                            if isLoading {
                                ProgressView().tint(Mono.C.bg).scaleEffect(0.85)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: mode == .signIn
                                          ? "arrow.right.circle.fill" : "icloud.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(mode == .signIn ? "Sign In & Sync" : "Create & Upload Data")
                                        .font(Mono.T.mono(15, .semibold))
                                }
                            }
                        }
                        .foregroundColor(canSubmit ? Mono.C.bg : Mono.C.textDim)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(canSubmit ? Mono.C.text : Mono.C.surfaceTop))
                    }
                    .disabled(!canSubmit || isLoading)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24).padding(.top, 16)
                    .animation(.spring(duration: 0.25), value: canSubmit)

                    Spacer(minLength: 60)
                }
            }
        }
        .navigationTitle("Connect Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .font(Mono.T.body).foregroundColor(Mono.C.textSec)
            }
        }
        .animation(.spring(duration: 0.28), value: mode)
        .animation(.spring(duration: 0.25), value: errorMsg != nil)
    }

    @ViewBuilder
    private var usernameIndicator: some View {
        switch usernameState {
        case .idle:    EmptyView()
        case .checking: ProgressView().scaleEffect(0.7).tint(Mono.C.textDim)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14)).foregroundColor(Mono.C.accent)
        case .invalid:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14)).foregroundColor(Mono.C.red)
        }
    }

    @State private var checkTask: Task<Void, Never>?

    private func scheduleCheck(_ raw: String) {
        checkTask?.cancel()
        guard UsernameValidation.check(raw) == .valid else {
            withAnimation { usernameState = .idle }; return
        }
        withAnimation { usernameState = .checking }
        checkTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            let available = await SupabaseClient.shared.isUsernameAvailable(raw)
            await MainActor.run {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    usernameState = available ? .valid : .invalid("Username taken")
                }
            }
        }
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        focus = nil; isLoading = true; errorMsg = nil; Haptic.medium()
        Task {
            do {
                if mode == .signUp {
                    let realEmail = showEmail && !email.trimmingCharacters(in: .whitespaces).isEmpty
                        ? email.trimmingCharacters(in: .whitespaces) : nil
                    try await SupabaseClient.shared.signUp(
                        username: username.trimmingCharacters(in: .whitespaces).lowercased(),
                        password: password, realEmail: realEmail
                    )
                } else {
                    try await SupabaseClient.shared.signIn(
                        usernameOrEmail: username.trimmingCharacters(in: .whitespaces),
                        password: password
                    )
                }
                // Upload local data to the new / existing account
                try? await SupabaseClient.shared.uploadVaultData(store.currentVaultData)
                await MainActor.run {
                    UserDefaults.standard.removeObject(forKey: "offline_mode")
                    isLoading = false; Haptic.success(); onConnected()
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

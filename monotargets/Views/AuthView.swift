import SwiftUI

// MARK: - Auth View (Login / Sign Up)

struct AuthView: View {
    @Environment(AppStore.self) private var store
    let onAuthenticated: () -> Void

    @State private var mode: Mode = .signIn
    @State private var email       = ""
    @State private var password    = ""
    @State private var displayName = ""
    @State private var isLoading   = false
    @State private var errorMsg: String?
    @State private var appeared    = false

    enum Mode { case signIn, signUp }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        (mode == .signIn || !displayName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            // Subtle radial glow behind the card
            RadialGradient(
                colors: [Mono.C.accent.opacity(0.12), .clear],
                center: .top, startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Logo / wordmark ──────────────────────────────
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Mono.C.surfaceTop)
                                .frame(width: 72, height: 72)
                            Image(systemName: "target")
                                .font(.system(size: 34, weight: .light))
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
                    .padding(.top, 72)
                    .padding(.bottom, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -16)

                    // ── Mode switcher ────────────────────────────────
                    HStack(spacing: 4) {
                        ForEach([Mode.signIn, .signUp], id: \.label) { m in
                            Button {
                                withAnimation(.spring(duration: 0.25, bounce: 0.3)) { mode = m }
                                errorMsg = nil
                                Haptic.select()
                            } label: {
                                Text(m.label)
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
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Mono.C.surfaceTop)
                    )
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    // ── Form card ────────────────────────────────────
                    VStack(spacing: 0) {
                        if mode == .signUp {
                            AuthField(
                                icon: "person",
                                placeholder: "Display name",
                                text: $displayName,
                                keyboard: .default
                            )
                            MonoDivider().padding(.horizontal, Mono.S.md)
                        }

                        AuthField(
                            icon: "envelope",
                            placeholder: "Email address",
                            text: $email,
                            keyboard: .emailAddress,
                            isLowercase: true
                        )
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        AuthField(
                            icon: "lock",
                            placeholder: "Password (min 6 chars)",
                            text: $password,
                            isSecure: true
                        )
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
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)

                    // ── Error ─────────────────────────────────────────
                    if let err = errorMsg {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 12, weight: .semibold))
                            Text(err)
                                .font(Mono.T.mono(12, .regular))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(Mono.C.red)
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Submit button ─────────────────────────────────
                    Button(action: submit) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .tint(Mono.C.bg)
                                    .scaleEffect(0.85)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: mode == .signIn ? "arrow.right.circle.fill" : "person.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(mode.buttonLabel)
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
                                .shadow(color: canSubmit ? .white.opacity(0.06) : .clear, radius: 12)
                        )
                        .animation(.spring(duration: 0.25), value: canSubmit)
                    }
                    .disabled(!canSubmit || isLoading)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)

                    // ── Continue offline ──────────────────────────────
                    Button {
                        Haptic.light()
                        onAuthenticated()
                    } label: {
                        Text("Continue without account")
                            .font(Mono.T.mono(12, .regular))
                            .foregroundColor(Mono.C.textDim)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.2).delay(0.1)) { appeared = true }
        }
        .animation(.spring(duration: 0.3), value: mode)
        .animation(.spring(duration: 0.25), value: errorMsg)
    }

    private func submit() {
        guard canSubmit else { return }
        isLoading = true
        errorMsg  = nil
        Haptic.medium()

        Task {
            do {
                if mode == .signUp {
                    _ = try await SupabaseClient.shared.signUp(
                        email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                        password: password,
                        displayName: displayName.trimmingCharacters(in: .whitespaces)
                    )
                    // Seed display name into AppStorage
                    await MainActor.run {
                        UserDefaults.standard.set(
                            displayName.trimmingCharacters(in: .whitespaces),
                            forKey: "user_name"
                        )
                    }
                    // Try to download existing vault data
                    if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                        await store.replaceData(with: remote)
                    }
                } else {
                    _ = try await SupabaseClient.shared.signIn(
                        email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                        password: password
                    )
                    // Pull remote data on sign-in
                    if let remote = try? await SupabaseClient.shared.downloadVaultData() {
                        await store.replaceData(with: remote)
                    }
                }
                await MainActor.run {
                    isLoading = false
                    Haptic.success()
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

// MARK: - Auth Field

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var isLowercase: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Mono.C.textTert)
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(isLowercase ? .never : .words)
                }
            }
            .font(Mono.T.mono(14, .regular))
            .foregroundColor(Mono.C.text)
            .tint(Mono.C.accent)
        }
        .padding(Mono.S.md)
        .frame(minHeight: 52)
    }
}

// MARK: - Mode helpers

private extension AuthView.Mode {
    var label: String {
        switch self { case .signIn: return "Sign In"; case .signUp: return "Sign Up" }
    }
    var buttonLabel: String {
        switch self { case .signIn: return "Sign In"; case .signUp: return "Create Account" }
    }
}

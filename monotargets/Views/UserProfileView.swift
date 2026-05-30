import SwiftUI

struct UserProfileView: View {
    @Environment(AppStore.self)  private var store
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss)      private var dismiss

    private var username: String { UserDefaults.standard.string(forKey: "user_name") ?? "—" }

    @State private var showChangePassword  = false
    @State private var showDeleteConfirm   = false
    @State private var showSignOutConfirm  = false
    @State private var appeared            = false

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.lg) {

                    // ── Avatar + username ────────────────────────────────────
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Mono.C.accent.opacity(0.3), Mono.C.accent.opacity(0.08)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 88, height: 88)
                            Text(String(username.prefix(1)).uppercased())
                                .font(Mono.T.mono(36, .bold))
                                .foregroundColor(Mono.C.accent)
                        }

                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text("@\(username)")
                                    .font(Mono.T.mono(20, .bold))
                                    .foregroundColor(Mono.C.text)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Mono.C.textDim)
                            }
                            Text("Username cannot be changed")
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Mono.S.xl)
                    .monoCard()
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.92)

                    // ── Account stats ────────────────────────────────────────
                    SettingsSection(title: "Account") {
                        SettingsRow(icon: "person.fill", label: "Username") {
                            Text("@\(username)")
                                .font(Mono.T.mono(13, .medium))
                                .foregroundColor(Mono.C.textSec)
                        } action: {}

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        SettingsRow(icon: "icloud.fill", label: "Sync Status") {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Mono.C.accent)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(Mono.T.mono(12, .medium))
                                    .foregroundColor(Mono.C.accent)
                            }
                        } action: {}
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // ── Security ─────────────────────────────────────────────
                    SettingsSection(title: "Security") {
                        SettingsRow(icon: "lock.rotation", label: "Change Password") {
                            EmptyView()
                        } action: {
                            showChangePassword = true
                            Haptic.light()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // ── Session ──────────────────────────────────────────────
                    SettingsSection(title: "Session") {
                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", label: "Sign Out") {
                            EmptyView()
                        } action: {
                            showSignOutConfirm = true
                            Haptic.medium()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // ── Danger ───────────────────────────────────────────────
                    SettingsSection(title: "Danger Zone") {
                        DangerButton(icon: "person.crop.circle.badge.xmark", label: "Delete Account") {
                            showDeleteConfirm = true
                            Haptic.medium()
                        }
                        .padding(Mono.S.sm)
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 60)
                }
                .padding(.top, Mono.S.md)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.05)) { appeared = true }
        }
        // Change Password sheet
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
                .environment(store)
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Mono.C.bg)
                .presentationCornerRadius(24)
        }
        // Sign-out confirmation
        .confirmationDialog("Sign out of @\(username)?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await authState.signOut(store: store) }
            }
            Button("Cancel", role: .cancel) {}
        }
        // Delete account confirmation
        .confirmationDialog("Delete your account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task {
                    try? await authState.deleteAccount(store: store)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes @\(username) and all your data. This cannot be undone.")
        }
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword    = ""
    @State private var confirmPassword = ""
    @State private var isLoading      = false
    @State private var errorMsg: String?
    @State private var success         = false

    @FocusState private var focus: Field?
    enum Field { case new, confirm }

    private var isValid: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    private var mismatch: Bool {
        !confirmPassword.isEmpty && newPassword != confirmPassword
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(white: 0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 14).padding(.bottom, 20)

            Text("Change Password")
                .font(Mono.T.mono(16, .semibold))
                .foregroundColor(Mono.C.text)
                .padding(.bottom, Mono.S.lg)

            VStack(spacing: 0) {
                AuthInputRow(
                    icon: "lock",
                    placeholder: "New password (min 6)",
                    text: $newPassword,
                    isSecure: true,
                    isFocused: focus == .new,
                    trailingView: { AnyView(EmptyView()) },
                    onSubmit: { focus = .confirm }
                )
                .focused($focus, equals: .new)

                MonoDivider().padding(.horizontal, Mono.S.md)

                AuthInputRow(
                    icon: "lock.fill",
                    placeholder: "Confirm password",
                    text: $confirmPassword,
                    isSecure: true,
                    isFocused: focus == .confirm,
                    trailingView: {
                        if mismatch {
                            AnyView(Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Mono.C.red)
                                .font(.system(size: 14)))
                        } else if newPassword.count >= 6 && !confirmPassword.isEmpty {
                            AnyView(Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Mono.C.accent)
                                .font(.system(size: 14)))
                        } else {
                            AnyView(EmptyView())
                        }
                    },
                    onSubmit: { if isValid { changePassword() } }
                )
                .focused($focus, equals: .confirm)
            }
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.C.surface)
                    .overlay(RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                        .strokeBorder(Mono.C.border, lineWidth: 0.5))
            )
            .padding(.horizontal, Mono.S.md)

            if let err = errorMsg {
                Text(err)
                    .font(Mono.T.mono(12, .regular))
                    .foregroundColor(Mono.C.red)
                    .padding(.horizontal, Mono.S.lg)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if success {
                Label("Password changed!", systemImage: "checkmark.circle.fill")
                    .font(Mono.T.mono(13, .semibold))
                    .foregroundColor(Mono.C.accent)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button(action: changePassword) {
                ZStack {
                    if isLoading { ProgressView().tint(Mono.C.bg).scaleEffect(0.85) }
                    else {
                        Text(success ? "Done" : "Update Password")
                            .font(Mono.T.mono(15, .semibold))
                    }
                }
                .foregroundColor(isValid || success ? Mono.C.bg : Mono.C.textDim)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(isValid || success ? Mono.C.text : Mono.C.surfaceTop)
                )
            }
            .disabled((!isValid && !success) || isLoading)
            .buttonStyle(.plain)
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .animation(.spring(duration: 0.25), value: isValid)

            Spacer()
        }
        .animation(.spring(duration: 0.25), value: errorMsg != nil)
        .animation(.spring(duration: 0.25), value: success)
        .onAppear { focus = .new }
    }

    private func changePassword() {
        guard isValid else {
            if success { dismiss(); return }
            return
        }
        if success { dismiss(); return }
        focus = nil; isLoading = true; errorMsg = nil; Haptic.medium()
        Task {
            do {
                try await SupabaseClient.shared.changePassword(to: newPassword)
                await MainActor.run { isLoading = false; success = true; Haptic.success() }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isLoading = false; errorMsg = error.localizedDescription; Haptic.medium()
                }
            }
        }
    }
}

import SwiftUI

// MARK: - Onboarding Coordinator

struct OnboardingView: View {
    @AppStorage("onboarding_done")  private var onboardingDone  = false
    @AppStorage("user_name")        private var storedName      = ""
    @AppStorage("currency_code")    private var storedCurrency  = "INR"
    @AppStorage("vault_monochrome") private var isMonochrome    = false
    @Environment(AppStore.self)     private var store

    // Local working state (committed on completion)
    @State private var step            = 0
    @State private var goingForward    = true
    @State private var nameInput       = ""
    @State private var selectedCurrency = "INR"
    @State private var goalName        = ""
    @State private var goalAmountDigits = ""
    @State private var goalIcon        = "star.fill"
    @State private var colorModeChosen = false   // false = color, true = mono

    private let totalSteps = 6

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            // Ambient gradient changes with step
            stepGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: step)

            VStack(spacing: 0) {
                // Back button row (hidden on welcome + done)
                HStack {
                    if step > 0 && step < 5 {
                        Button {
                            go(to: step - 1, forward: false)
                            Haptic.light()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Back")
                                    .font(Mono.T.mono(14, .medium))
                            }
                            .foregroundColor(Mono.C.textSec)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    } else {
                        Color.clear.frame(width: 60, height: 1)
                    }
                    Spacer()
                    // Skip buttons on steps 1, 4
                    if step == 1 {
                        skipButton { go(to: 2, forward: true) }
                    } else if step == 4 {
                        skipButton { go(to: 5, forward: true) }
                    }
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.top, 60)
                .animation(.spring(duration: 0.3), value: step)

                // Step content
                stepContent
                    .id(step)
                    .transition(stepTransition)

                Spacer(minLength: 0)

                // Progress dots (steps 0–4)
                if step < 5 {
                    OnboardingDots(current: step, total: 5)
                        .padding(.bottom, 50)
                        .transition(.opacity)
                }
            }
        }
        .animation(.spring(duration: 0.44, bounce: 0.22), value: step)
    }

    // MARK: - Step Content Router

    @ViewBuilder private var stepContent: some View {
        switch step {
        case 0: WelcomeStep { go(to: 1, forward: true) }
        case 1: NameStep(nameInput: $nameInput)  { go(to: 2, forward: true) }
        case 2: CurrencyStep(selected: $selectedCurrency) { go(to: 3, forward: true) }
        case 3: ColorModeStep(isMono: $colorModeChosen) { go(to: 4, forward: true) }
        case 4: FirstGoalStep(goalName: $goalName,
                               goalAmountDigits: $goalAmountDigits,
                               goalIcon: $goalIcon) { go(to: 5, forward: true) }
        case 5: AllDoneStep(userName: nameInput,
                             currencyCode: selectedCurrency,
                             hasGoal: !goalName.isEmpty) { completeOnboarding() }
        default: EmptyView()
        }
    }

    // MARK: - Helpers

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingForward ? .trailing : .leading)
                .combined(with: .opacity),
            removal:   .move(edge: goingForward ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    @ViewBuilder private var stepGradient: some View {
        switch step {
        case 0:
            LinearGradient(colors: [Color(white: 0.09), Mono.C.bg],
                           startPoint: .top, endPoint: .bottom)
        case 1:
            LinearGradient(colors: [Mono.C.accent.opacity(0.05), Mono.C.bg],
                           startPoint: .top, endPoint: .init(x: 0.5, y: 0.5))
        case 2:
            LinearGradient(colors: [Color(white: 0.08), Mono.C.bg],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            colorModeChosen
                ? LinearGradient(colors: [Color(white: 0.10), Mono.C.bg],
                                 startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Mono.C.accent.opacity(0.05), Mono.C.bg],
                                 startPoint: .top, endPoint: .bottom)
        case 4:
            LinearGradient(colors: [Mono.C.accent.opacity(0.04), Mono.C.bg],
                           startPoint: .topTrailing, endPoint: .bottomLeading)
        default:
            LinearGradient(colors: [Mono.C.accent.opacity(0.06), Mono.C.bg],
                           startPoint: .top, endPoint: .init(x: 0.5, y: 0.4))
        }
    }

    private func go(to newStep: Int, forward: Bool) {
        goingForward = forward
        // Tiny delay so the transition direction is committed before the id changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            step = newStep
        }
    }

    private func completeOnboarding() {
        // Commit preferences
        storedName     = nameInput
        storedCurrency = selectedCurrency
        isMonochrome   = colorModeChosen

        // Create first goal if provided
        let amount = AmountFormatter.toDoubleFromDigits(goalAmountDigits)
        if !goalName.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0 {
            let item = SavingsItem(
                name: goalName.trimmingCharacters(in: .whitespaces),
                itemDescription: "",
                icon: goalIcon,
                targetAmount: amount
            )
            store.createSavingsItem(item)
        }

        Haptic.success()
        onboardingDone = true
    }

    @ViewBuilder
    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: { action(); Haptic.light() }) {
            HStack(spacing: 3) {
                Text("Skip")
                    .font(Mono.T.mono(14, .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(Mono.C.textDim)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Dots

struct OnboardingDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(i == current ? Mono.C.text : Mono.C.surfaceTop)
                    .frame(width: i == current ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.35, bounce: 0.4), value: current)
            }
        }
    }
}

// MARK: - Step 0: Welcome

private struct WelcomeStep: View {
    let onNext: () -> Void

    @State private var logoScale:   CGFloat = 0.6
    @State private var logoOpacity: Double  = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var btnOpacity:  Double  = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Mono.G.hero)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Mono.C.borderBright.opacity(0.5), lineWidth: 0.7)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
                    .frame(width: 96, height: 96)

                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundColor(Mono.C.text)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            Spacer().frame(height: 36)

            // Title block
            VStack(spacing: 10) {
                Text("MONOTARGETS")
                    .font(Mono.T.mono(32, .bold))
                    .foregroundColor(Mono.C.text)
                    .tracking(6)

                Text("Your money, tracked.")
                    .font(Mono.T.mono(15, .regular))
                    .foregroundColor(Mono.C.textTert)

                HStack(spacing: 6) {
                    ForEach(["Goals", "Assign", "Track"], id: \.self) { word in
                        Text(word.uppercased())
                            .font(Mono.T.mono(9, .semibold))
                            .foregroundColor(Mono.C.textDim)
                            .tracking(2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Mono.C.surfaceTop)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .strokeBorder(Mono.C.border, lineWidth: 0.5)
                                    )
                            )
                    }
                }
                .padding(.top, 6)
            }
            .offset(y: titleOffset)
            .opacity(titleOpacity)

            Spacer()

            // CTA
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(Mono.T.mono(16, .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Mono.C.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(Mono.C.text)
                        .shadow(color: .white.opacity(0.12), radius: 20)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, 20)
            .opacity(btnOpacity)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.55).delay(0.1)) {
                logoScale = 1.0; logoOpacity = 1.0
            }
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.35)) {
                titleOffset = 0; titleOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                btnOpacity = 1.0
            }
        }
    }
}

// MARK: - Step 1: Name

private struct NameStep: View {
    @Binding var nameInput: String
    let onNext: () -> Void

    @State private var appeared = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: Mono.S.md)

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("What should")
                    .font(Mono.T.mono(34, .bold))
                    .foregroundColor(Mono.C.text)
                Text("we call you?")
                    .font(Mono.T.mono(34, .bold))
                    .foregroundColor(Mono.C.text)
                Text("We'll greet you on the home screen.")
                    .font(Mono.T.mono(13, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .padding(.top, 4)
            }
            .padding(.horizontal, Mono.S.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: Mono.S.xxl)

            // Input field
            VStack(alignment: .leading, spacing: 8) {
                OverlineLabel(text: "Your Name", opacity: 0.4)
                    .padding(.horizontal, 4)

                TextField("e.g. Tanay", text: $nameInput)
                    .font(Mono.T.mono(22, .semibold))
                    .foregroundColor(Mono.C.text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($focused)
                    .padding(Mono.S.md)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .fill(Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                    .strokeBorder(
                                        focused ? Mono.C.accent.opacity(0.6) : Mono.C.border,
                                        lineWidth: focused ? 1.0 : 0.5
                                    )
                            )
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: focused)
            }
            .padding(.horizontal, Mono.S.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer()

            // Continue button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(nameInput.isEmpty ? "Continue without name" : "Continue as \(nameInput)")
                        .font(Mono.T.mono(15, .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(!nameInput.isEmpty ? Mono.C.bg : Mono.C.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(!nameInput.isEmpty ? Mono.C.text : Mono.C.surfaceUp)
                        .overlay(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .strokeBorder(nameInput.isEmpty ? Mono.C.border.opacity(0.5) : .clear, lineWidth: 0.5)
                        )
                )
                .animation(.spring(duration: 0.25, bounce: 0.2), value: nameInput.isEmpty)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.3).delay(0.1)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
        }
    }
}

// MARK: - Step 2: Currency

private struct CurrencyStep: View {
    @Binding var selected: String
    let onNext: () -> Void

    @State private var appeared = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: Mono.S.md)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pick your")
                    .font(Mono.T.mono(34, .bold))
                    .foregroundColor(Mono.C.text)
                Text("currency")
                    .font(Mono.T.mono(34, .bold))
                    .foregroundColor(Mono.C.text)
                Text("You can change this in Settings anytime.")
                    .font(Mono.T.mono(13, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .padding(.top, 4)
            }
            .padding(.horizontal, Mono.S.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: Mono.S.xl)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(CurrencyInfo.all.enumerated()), id: \.element.id) { idx, cur in
                    CurrencyCell(info: cur, isSelected: selected == cur.code)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                                selected = cur.code
                            }
                            Haptic.select()
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(
                            .spring(duration: 0.45, bounce: 0.3)
                                .delay(0.08 + Double(idx) * 0.04),
                            value: appeared
                        )
                }
            }
            .padding(.horizontal, Mono.S.md)

            Spacer()

            OnboardingContinueButton(label: "Continue") { onNext(); Haptic.medium() }
                .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.25).delay(0.05)) { appeared = true }
        }
    }
}

private struct CurrencyCell: View {
    let info: CurrencyInfo
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(info.flag)
                .font(.system(size: 26))
            Text(info.symbol)
                .font(Mono.T.mono(14, .bold))
                .foregroundColor(isSelected ? Mono.C.bg : Mono.C.text)
            Text(info.code)
                .font(Mono.T.mono(9, .semibold))
                .foregroundColor(isSelected ? Mono.C.bg.opacity(0.7) : Mono.C.textTert)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                .fill(isSelected ? Mono.C.text : Mono.C.surfaceUp)
                .overlay(
                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                        .strokeBorder(
                            isSelected ? .clear : Mono.C.border,
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: isSelected ? .white.opacity(0.12) : .clear,
                    radius: 10
                )
        )
    }
}

// MARK: - Step 3: Color Mode

private struct ColorModeStep: View {
    @Binding var isMono: Bool
    let onNext: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: Mono.S.md)

            VStack(alignment: .leading, spacing: 8) {
                Text("How do you")
                    .font(Mono.T.mono(34, .bold))
                    .foregroundColor(Mono.C.text)
                Text("like it?")
                    .font(Mono.T.mono(34, .bold))
                    .foregroundColor(Mono.C.text)
                Text("You can toggle this in Settings later.")
                    .font(Mono.T.mono(13, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .padding(.top, 4)
            }
            .padding(.horizontal, Mono.S.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: Mono.S.xl)

            HStack(spacing: 12) {
                ColorModeCard(
                    title: "Color",
                    subtitle: "Green accents + glows",
                    icon: "sparkles",
                    accentColor: Mono.C.accent,
                    isSelected: !isMono
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.3)) { isMono = false }
                    Haptic.select()
                }

                ColorModeCard(
                    title: "Mono",
                    subtitle: "Pure black & white",
                    icon: "circle.lefthalf.filled",
                    accentColor: Mono.C.text,
                    isSelected: isMono
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.3)) { isMono = true }
                    Haptic.select()
                }
            }
            .padding(.horizontal, Mono.S.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer()

            OnboardingContinueButton(label: "Continue") { onNext(); Haptic.medium() }
                .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.25).delay(0.05)) { appeared = true }
        }
    }
}

private struct ColorModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                        .fill(isSelected ? accentColor : Mono.C.surfaceTop)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(Mono.T.mono(15, .semibold))
                        .foregroundColor(isSelected ? Mono.C.text : Mono.C.textSec)
                    Text(subtitle)
                        .font(Mono.T.mono(10, .regular))
                        .foregroundColor(Mono.C.textDim)
                        .multilineTextAlignment(.center)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Mono.C.textDim)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Mono.S.lg)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.G.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(
                                isSelected ? accentColor.opacity(0.6) : Mono.C.border,
                                lineWidth: isSelected ? 1.2 : 0.5
                            )
                    )
                    .shadow(
                        color: isSelected ? accentColor.opacity(0.20) : .clear,
                        radius: 14
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.28, bounce: 0.35), value: isSelected)
    }
}

// MARK: - Step 4: First Goal

private struct FirstGoalStep: View {
    @Binding var goalName: String
    @Binding var goalAmountDigits: String
    @Binding var goalIcon: String
    let onNext: () -> Void

    @State private var appeared = false
    @FocusState private var nameFocused: Bool
    @FocusState private var amtFocused: Bool

    private let quickIcons: [String] = [
        "star.fill", "car.fill", "house.fill", "airplane", "laptopcomputer",
        "iphone", "camera.fill", "gift.fill", "graduationcap.fill", "heart.fill",
        "figure.walk", "music.note", "pawprint.fill", "leaf.fill", "bolt.fill"
    ]

    private var isValid: Bool {
        !goalName.trimmingCharacters(in: .whitespaces).isEmpty
            && AmountFormatter.toDoubleFromDigits(goalAmountDigits) > 0
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: Mono.S.md)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Set your")
                        .font(Mono.T.mono(34, .bold))
                        .foregroundColor(Mono.C.text)
                    Text("first goal")
                        .font(Mono.T.mono(34, .bold))
                        .foregroundColor(Mono.C.accent)
                    Text("What are you saving for?")
                        .font(Mono.T.mono(13, .regular))
                        .foregroundColor(Mono.C.textTert)
                        .padding(.top, 4)
                }
                .padding(.horizontal, Mono.S.lg)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer().frame(height: Mono.S.xl)

                // Icon picker
                VStack(alignment: .leading, spacing: 10) {
                    OverlineLabel(text: "Pick an icon", opacity: 0.4)
                        .padding(.horizontal, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickIcons, id: \.self) { icon in
                                Button {
                                    withAnimation(.spring(duration: 0.2, bounce: 0.5)) { goalIcon = icon }
                                    Haptic.select()
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                                            .fill(goalIcon == icon ? Mono.C.text : Mono.C.surfaceUp)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                                                    .strokeBorder(goalIcon == icon ? .clear : Mono.C.border, lineWidth: 0.5)
                                            )
                                        Image(systemName: icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(goalIcon == icon ? Mono.C.bg : Mono.C.textSec)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Mono.S.lg)
                    }
                }
                .padding(.bottom, Mono.S.md)
                .opacity(appeared ? 1 : 0)

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    OverlineLabel(text: "Goal name", opacity: 0.4)
                        .padding(.horizontal, 4)

                    TextField("e.g. New MacBook", text: $goalName)
                        .font(Mono.T.mono(17, .semibold))
                        .foregroundColor(Mono.C.text)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .padding(Mono.S.md)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                .fill(Mono.C.surfaceUp)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                        .strokeBorder(nameFocused ? Mono.C.accent.opacity(0.5) : Mono.C.border, lineWidth: nameFocused ? 1.0 : 0.5)
                                )
                        )
                        .animation(.spring(duration: 0.25), value: nameFocused)
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.md)
                .opacity(appeared ? 1 : 0)

                // Amount field
                VStack(alignment: .leading, spacing: 8) {
                    OverlineLabel(text: "Target amount", opacity: 0.4)
                        .padding(.horizontal, 4)

                    HStack(spacing: 6) {
                        Text(CurrencyInfo.current.symbol)
                            .font(Mono.T.mono(20, .semibold))
                            .foregroundColor(Mono.C.textTert)
                        TextField("0", text: $goalAmountDigits)
                            .font(Mono.T.mono(22, .bold))
                            .foregroundColor(Mono.C.text)
                            .keyboardType(.numberPad)
                            .focused($amtFocused)
                    }
                    .padding(Mono.S.md)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .fill(Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                    .strokeBorder(amtFocused ? Mono.C.accent.opacity(0.5) : Mono.C.border, lineWidth: amtFocused ? 1.0 : 0.5)
                            )
                    )
                    .animation(.spring(duration: 0.25), value: amtFocused)
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.xl)
                .opacity(appeared ? 1 : 0)

                // Create button
                Button(action: onNext) {
                    HStack(spacing: 8) {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "arrow.right")
                            .font(.system(size: 15))
                        Text(isValid ? "Create Goal" : "Skip")
                            .font(Mono.T.mono(15, .semibold))
                    }
                    .foregroundColor(isValid ? Mono.C.bg : Mono.C.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(isValid ? Mono.C.accent : Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .strokeBorder(isValid ? .clear : Mono.C.border.opacity(0.5), lineWidth: 0.5)
                            )
                            .shadow(color: isValid ? Mono.C.accent.opacity(0.45) : .clear, radius: 14)
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: isValid)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, 20)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.25).delay(0.05)) { appeared = true }
        }
    }
}

// MARK: - Step 5: All Done

private struct AllDoneStep: View {
    let userName: String
    let currencyCode: String
    let hasGoal: Bool
    let onDone: () -> Void

    @State private var particles: [DoneParticle] = []
    @State private var checkScale: CGFloat = 0.3
    @State private var checkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var summaryOpacity: Double = 0
    @State private var btnOpacity: Double = 0

    private var greeting: String {
        userName.isEmpty ? "You're all set!" : "You're all set,\n\(userName)!"
    }

    private var currencyInfo: CurrencyInfo {
        CurrencyInfo.all.first { $0.code == currencyCode } ?? CurrencyInfo.all[0]
    }

    var body: some View {
        ZStack {
            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.color.opacity(p.opacity))
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
            }

            VStack(spacing: 0) {
                Spacer()

                // Big check
                ZStack {
                    Circle()
                        .fill(Mono.C.text.opacity(0.06))
                        .frame(width: 120, height: 120)
                        .scaleEffect(checkScale * 1.3)
                        .opacity(checkOpacity * 0.4)

                    ZStack {
                        Circle()
                            .fill(Mono.C.text)
                            .frame(width: 88, height: 88)
                            .shadow(color: .white.opacity(0.18), radius: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Mono.C.bg)
                    }
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
                }

                Spacer().frame(height: 32)

                Text(greeting)
                    .font(Mono.T.mono(32, .bold))
                    .foregroundColor(Mono.C.text)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                Spacer().frame(height: Mono.S.xl)

                // Summary bullets
                VStack(alignment: .leading, spacing: 10) {
                    SummaryRow(icon: "coloncurrencysign.circle.fill",
                               text: "\(currencyInfo.flag) \(currencyInfo.code) — \(currencyInfo.symbol)")
                    if hasGoal {
                        SummaryRow(icon: "target",
                                   text: "First goal created")
                    }
                    SummaryRow(icon: "lock.fill",
                               text: "All data stays on device")
                    SummaryRow(icon: "arrow.triangle.2.circlepath",
                               text: "Auto-backup when folder is set")
                }
                .padding(Mono.S.lg)
                .monoCard()
                .padding(.horizontal, Mono.S.lg)
                .opacity(summaryOpacity)
                .offset(y: summaryOpacity == 0 ? 16 : 0)

                Spacer()

                Button(action: onDone) {
                    HStack(spacing: 8) {
                        Text("Let's go")
                            .font(Mono.T.mono(17, .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(Mono.C.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(Mono.C.text)
                            .shadow(color: .white.opacity(0.14), radius: 24)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, 20)
                .opacity(btnOpacity)
            }
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        particles = (0..<28).map { _ in
            DoneParticle(
                x: CGFloat.random(in: -160...160),
                y: CGFloat.random(in: -240...240),
                size: CGFloat.random(in: 3...9),
                color: [Mono.C.text, Mono.C.accent, Mono.C.textSec].randomElement()!,
                opacity: Double.random(in: 0.3...0.9)
            )
        }
        withAnimation(.spring(duration: 0.55, bounce: 0.65).delay(0.1)) {
            checkScale = 1.0; checkOpacity = 1.0
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.45)) {
            textOpacity = 1.0
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.7)) {
            summaryOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.35).delay(1.0)) {
            btnOpacity = 1.0
        }
    }
}

private struct DoneParticle: Identifiable {
    let id = UUID()
    let x, y, size: CGFloat
    let color: Color
    let opacity: Double
}

private struct SummaryRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Mono.C.accent)
                .frame(width: 20)
            Text(text)
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textSec)
        }
    }
}

// MARK: - Shared Continue Button

private struct OnboardingContinueButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(Mono.T.mono(15, .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(Mono.C.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(Mono.C.text)
                    .shadow(color: .white.opacity(0.10), radius: 14)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Mono.S.lg)
    }
}

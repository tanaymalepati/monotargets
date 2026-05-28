import SwiftUI

// MARK: - Root Navigation

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: Tab = .home
    @State private var showAddTransaction = false
    @State private var pullOffset: CGFloat = 0
    @State private var tabBarVisible = true

    enum Tab: Int, CaseIterable {
        case home     = 0
        case goals    = 1
        case history  = 2
        case settings = 3

        var icon: String {
            switch self {
            case .home:     return "square.grid.2x2"
            case .goals:    return "target"
            case .history:  return "clock.fill"
            case .settings: return "gearshape.fill"
            }
        }
        var label: String {
            switch self {
            case .home:     return "Home"
            case .goals:    return "Goals"
            case .history:  return "History"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Mono.C.bg.ignoresSafeArea()

            // Page content via TabView with page swipe
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                        .navigationTitle("MONOTARGETS")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(Tab.home)

                NavigationStack {
                    GoalsView()
                        .navigationTitle("GOALS")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(Tab.goals)

                NavigationStack {
                    HistoryView()
                        .navigationTitle("HISTORY")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(Tab.history)

                NavigationStack {
                    SettingsView()
                        .navigationTitle("SETTINGS")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .toolbarColorScheme(.dark, for: .navigationBar)

            // Pull-down indicator (shown when dragging from top)
            if pullOffset > 10 {
                PullIndicator(offset: pullOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
            }

            // Custom tab bar
            if tabBarVisible {
                VaultTabBar(selectedTab: $selectedTab, onAdd: {
                    showAddTransaction = true
                    Haptic.medium()
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Add transaction overlay (springs up from bottom)
            if showAddTransaction {
                AddTransactionView(isPresented: $showAddTransaction)
                    .transition(.identity)   // animation is fully internal
                    .zIndex(10)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    // Only trigger pull-down from the top region
                    if value.startLocation.y < 80 && value.translation.height > 0 {
                        pullOffset = min(value.translation.height, 80)
                    }
                }
                .onEnded { value in
                    if value.startLocation.y < 80 && value.translation.height > 60 {
                        showAddTransaction = true
                        withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                            pullOffset = 0
                        }
                        Haptic.medium()
                    } else {
                        withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                            pullOffset = 0
                        }
                    }
                }
        )
        .animation(.spring(duration: 0.3, bounce: 0.2), value: tabBarVisible)
    }

}

// MARK: - Custom Tab Bar

struct VaultTabBar: View {
    @Binding var selectedTab: RootView.Tab
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Home
            TabBarItem(tab: .home, isSelected: selectedTab == .home) {
                withAnimation(.spring(duration: 0.25, bounce: 0.4)) { selectedTab = .home }
                Haptic.select()
            }
            .frame(maxWidth: .infinity)

            // Goals
            TabBarItem(tab: .goals, isSelected: selectedTab == .goals) {
                withAnimation(.spring(duration: 0.25, bounce: 0.4)) { selectedTab = .goals }
                Haptic.select()
            }
            .frame(maxWidth: .infinity)

            // Center Add button
            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Mono.C.text)
                        .frame(width: 50, height: 50)
                        .shadow(color: .white.opacity(0.12), radius: 12)
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Mono.C.bg)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            // History
            TabBarItem(tab: .history, isSelected: selectedTab == .history) {
                withAnimation(.spring(duration: 0.25, bounce: 0.4)) { selectedTab = .history }
                Haptic.select()
            }
            .frame(maxWidth: .infinity)

            // Settings
            TabBarItem(tab: .settings, isSelected: selectedTab == .settings) {
                withAnimation(.spring(duration: 0.25, bounce: 0.4)) { selectedTab = .settings }
                Haptic.select()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Mono.S.sm)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .colorScheme(.dark)
                Rectangle()
                    .fill(Mono.C.surface.opacity(0.85))
                Rectangle()
                    .fill(Mono.C.bg.opacity(0.3))
            }
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Mono.C.border),
                alignment: .top
            )
        )
    }
}

struct TabBarItem: View {
    let tab: RootView.Tab
    let isSelected: Bool
    let action: () -> Void

    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring(duration: 0.15, bounce: 0.8)) { bounceScale = 1.3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(duration: 0.25, bounce: 0.4)) { bounceScale = 1.0 }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Mono.C.text : Mono.C.textDim)
                    .scaleEffect(bounceScale)

                Text(tab.label.uppercased())
                    .font(Mono.T.mono(8, .medium))
                    .foregroundColor(isSelected ? Mono.C.textSec : Mono.C.textDim)
                    .tracking(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pull Indicator

struct PullIndicator: View {
    let offset: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(Mono.C.border)
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Mono.C.textTert)
                Text("Log Transaction")
                    .font(Mono.T.mono(11, .medium))
                    .foregroundColor(Mono.C.textTert)
            }
            .opacity(min(Double(offset) / 50, 1))
        }
        .frame(height: offset)
        .clipped()
        .animation(.spring(duration: 0.2), value: offset)
    }
}

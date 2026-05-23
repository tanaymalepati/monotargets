import SwiftUI

// MARK: - Icon Data

struct IconCategory: Identifiable {
    let id = UUID()
    let name: String
    let symbols: [String]
}

let vaultIconCategories: [IconCategory] = [
    IconCategory(name: "Finance", symbols: [
        "banknote", "banknote.fill", "creditcard", "creditcard.fill",
        "wallet.pass", "wallet.pass.fill", "dollarsign.circle", "dollarsign.circle.fill",
        "indianrupeesign.circle", "indianrupeesign.circle.fill", "indianrupeesign.square",
        "chart.bar.fill", "chart.line.uptrend.xyaxis", "arrow.up.right.circle.fill",
        "lock.fill", "lock.shield.fill", "safe.fill", "chart.pie.fill", "percent",
        "building.columns.fill", "chart.xyaxis.line", "arrow.up.arrow.down.circle.fill"
    ]),
    IconCategory(name: "Technology", symbols: [
        "laptopcomputer", "desktopcomputer", "iphone", "ipad", "applewatch",
        "airpods", "headphones", "speaker.wave.3.fill", "tv.fill", "gamecontroller.fill",
        "keyboard.fill", "mouse.fill", "cpu.fill", "memorychip.fill", "camera.fill",
        "photo.fill", "mic.fill", "display", "printer.fill", "wifi",
        "network", "externaldrive.fill", "server.rack"
    ]),
    IconCategory(name: "Transport", symbols: [
        "car.fill", "car.side.fill", "bicycle", "scooter", "airplane",
        "airplane.departure", "airplane.arrival", "bus.fill", "tram.fill",
        "ferry.fill", "fuelpump.fill", "parkingsign", "road.lanes",
        "bolt.car.fill", "map.fill", "location.fill", "figure.walk",
        "globe.americas.fill", "sailboat.fill", "car.front.waves.up.fill"
    ]),
    IconCategory(name: "Home", symbols: [
        "house.fill", "sofa.fill", "bed.double.fill", "washer.fill",
        "refrigerator.fill", "oven.fill", "lightbulb.fill", "fan.fill",
        "door.left.hand.open", "key.fill", "hammer.fill", "wrench.fill",
        "paintbrush.fill", "scissors", "archivebox.fill", "shippingbox.fill",
        "cart.fill", "bag.fill", "building.2.fill", "house.circle.fill"
    ]),
    IconCategory(name: "Food & Drink", symbols: [
        "fork.knife", "cup.and.saucer.fill", "mug.fill", "wineglass.fill",
        "fork.knife.circle.fill", "birthday.cake.fill", "popcorn.fill",
        "tray.fill", "cart.badge.plus", "basket.fill",
        "takeoutbag.and.cup.and.straw.fill", "leaf.fill", "apple.logo"
    ]),
    IconCategory(name: "Health", symbols: [
        "heart.fill", "heart.circle.fill", "figure.run", "dumbbell.fill",
        "figure.walk", "figure.yoga", "soccerball",
        "tennis.racket", "stethoscope", "pills.fill", "cross.case.fill",
        "waveform.path.ecg.rectangle.fill", "bandage.fill", "eyeglasses",
        "figure.swimming", "sportscourt.fill", "bicycle.circle.fill"
    ]),
    IconCategory(name: "Education", symbols: [
        "book.fill", "books.vertical.fill", "graduationcap.fill", "pencil",
        "doc.text.fill", "folder.fill", "envelope.fill", "briefcase.fill",
        "calendar", "clock.fill", "person.3.fill", "list.bullet.clipboard.fill",
        "checkmark.circle.fill", "square.and.pencil", "paperclip",
        "tag.fill", "rosette", "trophy.fill"
    ]),
    IconCategory(name: "Entertainment", symbols: [
        "music.note", "guitars.fill", "film.fill", "ticket.fill",
        "photo.artframe", "paintpalette.fill", "theatermasks.fill",
        "party.popper.fill", "wand.and.sparkles", "star.fill",
        "bolt.fill", "flame.fill", "sparkles", "moon.stars.fill",
        "gamecontroller.fill", "puzzlepiece.fill", "trophy.fill"
    ]),
    IconCategory(name: "Travel", symbols: [
        "mountain.2.fill", "tent.fill", "umbrella.fill", "sun.max.fill",
        "cloud.rain.fill", "snowflake", "globe.desk.fill",
        "binoculars.fill", "flag.fill", "beach.umbrella.fill",
        "tent.2.fill", "map.fill", "globe", "building.2.crop.circle.fill",
        "suitcase.fill", "figure.hiking", "photo.on.rectangle.angled"
    ]),
    IconCategory(name: "Goals", symbols: [
        "target", "scope", "flag.checkered", "checkmark.seal.fill",
        "medal.fill", "crown.fill", "diamond.fill", "gem",
        "square.stack.3d.up.fill", "cylinder.split.1x2.fill",
        "battery.100.bolt", "infinity.circle.fill",
        "arrow.up.right.circle.fill", "chart.line.uptrend.xyaxis.circle.fill"
    ]),
]

let allVaultIcons: [String] = vaultIconCategories.flatMap { $0.symbols }

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: String = "All"

    private var categories: [String] {
        ["All"] + vaultIconCategories.map { $0.name }
    }

    private var filteredIcons: [String] {
        if !searchText.isEmpty {
            return allVaultIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedCategory == "All" { return allVaultIcons }
        return vaultIconCategories.first { $0.name == selectedCategory }?.symbols ?? []
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                Mono.C.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Mono.C.textTert)

                        TextField("Search icons…", text: $searchText)
                            .font(Mono.T.body)
                            .foregroundColor(Mono.C.text)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .strokeBorder(Mono.C.border, lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.sm)

                    // Category pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                CategoryPill(
                                    label: cat,
                                    isSelected: selectedCategory == cat
                                ) {
                                    withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                                        selectedCategory = cat
                                    }
                                    Haptic.select()
                                }
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                    }
                    .padding(.bottom, Mono.S.md)

                    // Icons grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(filteredIcons, id: \.self) { symbol in
                                IconCell(
                                    symbol: symbol,
                                    isSelected: selectedIcon == symbol
                                ) {
                                    withAnimation(.spring(duration: 0.2, bounce: 0.5)) {
                                        selectedIcon = symbol
                                    }
                                    Haptic.medium()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .padding(Mono.S.md)
                    }
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(Mono.T.body)
                        .foregroundColor(Mono.C.textSec)
                }
            }
        }
    }
}

struct CategoryPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Mono.T.mono(12, .medium))
                .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Mono.C.text : Mono.C.surfaceUp)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(isSelected ? .clear : Mono.C.border, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct IconCell: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                    .fill(isSelected ? Mono.C.text : Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                            .strokeBorder(
                                isSelected ? .clear : Mono.C.border,
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: isSelected ? .white.opacity(0.15) : .clear,
                        radius: 8
                    )

                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            }
            .frame(height: 56)
            .scaleEffect(isSelected ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Inline Icon Preview Button

struct IconSelectButton: View {
    @Binding var icon: String
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
            Haptic.light()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .fill(Mono.G.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .strokeBorder(Mono.C.borderBright, lineWidth: 0.5)
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(Mono.C.text)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            IconPickerView(selectedIcon: $icon)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Mono.C.bg)
        }
    }
}

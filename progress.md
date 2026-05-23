# Vault — Savings Tracker for iOS
## Build Progress Log

---

## App Overview
A monospace, monochromatic, gamified savings tracker for iOS built in SwiftUI. True black/white aesthetic, Geist-style monospace font (using system SF Mono), squircle theming, Indian number formatting, SF Symbols icon picker, auto-backup to user folder.

---

## Architecture

```
monotargets/
├── monotargetsApp.swift         App entry + @Observable injection
├── ContentView.swift            Root navigation shell
├── Theme/
│   └── MonoTheme.swift          Design tokens: colors, typography, spacing, radius, shadows
├── Models/
│   ├── Transaction.swift        Inward / outward / assigned transactions
│   ├── SavingsItem.swift        Savings goal with icon, target amount, target date
│   └── VaultData.swift          Codable envelope for JSON persistence
├── Store/
│   └── AppStore.swift           @Observable central state + JSON persistence
├── Services/
│   └── BackupService.swift      Security-scoped folder access + auto JSON backup
├── Utilities/
│   └── Formatters.swift         Indian number formatting, date formatters
├── Components/
│   ├── AnimatedAmountText.swift  Digit-animated number display + MonoNumpad
│   ├── IconPickerView.swift      SF Symbols picker (~200 curated icons, 10 categories)
│   ├── ProgressArc.swift         Circular ring, linear bar, balance segment bar
│   └── HapticFeedback.swift      Centralized haptic feedback helper
└── Views/
    ├── RootView.swift            TabView .page swipe + custom center-add tab bar
    ├── HomeView.swift            Balance hero card + goals scroll + recent transactions
    ├── GoalsView.swift           All savings goals list + stats header
    ├── HistoryView.swift         Full transaction history with grouping + filters
    ├── GoalDetailView.swift      Detail view: progress ring, stats grid, assign action
    ├── AddTransactionView.swift  Pull-down transaction panel with numpad
    ├── CreateGoalView.swift      Create / edit savings goal full-page form
    ├── AssignFundsView.swift     Assign unassigned money to a goal
    └── SettingsView.swift        Backup folder picker, restore, stats, app info
```

---

## Feature Checklist

### Foundation
- [x] Directory structure created
- [x] MonoTheme.swift — design tokens (Mono.C, Mono.T, Mono.S, Mono.R, Mono.G)
- [x] Transaction.swift — inward/outward/assign/unassign with symbols and labels
- [x] SavingsItem.swift — savings goal with progress computed properties
- [x] VaultData.swift — Codable envelope for JSON persistence
- [x] AppStore.swift — @Observable store with JSON persistence + auto-backup
- [x] Formatters.swift — Indian number system (₹1,23,45,678) + date utils
- [x] BackupService.swift — security-scoped bookmark + timestamped JSON backups

### Components
- [x] HapticFeedback.swift — Haptic.light/medium/heavy/success/error
- [x] AnimatedAmountText.swift — per-digit bounce transition animation
- [x] AmountInputField.swift — formatted input with animated cursor + live preview
- [x] MonoNumpad — custom monochromatic numeric keypad with spring press effect
- [x] ProgressArc.swift — ProgressRing (circular), MonoProgressBar (linear), BalanceSegmentBar
- [x] IconPickerView.swift — ~200 SF Symbol icons, 10 categories, search, category filter
- [x] IconSelectButton — tap-to-open picker with preview in form

### Views
- [x] AddTransactionView.swift — pull-down panel, type toggle, quick amounts, note field
- [x] HomeView.swift — hero balance card, unassigned/assigned breakdown, goals scroll, recent
- [x] GoalsView.swift — goals list with GoalCard (progress bar, ring, date), stats header
- [x] HistoryView.swift — grouped by date (Today/Yesterday/Month), filter pills
- [x] GoalDetailView.swift — full detail with stats grid, assign/unassign, transaction history
- [x] CreateGoalView.swift — icon picker, name, description, amount numpad, date picker
- [x] AssignFundsView.swift — assign with quick %, overflow warning, animate success
- [x] SettingsView.swift — backup folder picker, manual backup, restore, data stats

### Navigation & Shell
- [x] RootView.swift — page-style TabView (swipe L/R), custom 5-item tab bar (+ in center)
- [x] Pull-down gesture from top edge → AddTransactionView slides in from top
- [x] ContentView.swift — forces dark mode, injects theme tint
- [x] monotargetsApp.swift — @State store injected with .environment(store)

---

## Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| Font | System SF Mono (`.system(design: .monospaced)`) | Geist Mono requires bundled .ttf; SF Mono is identical in spirit |
| Icons | SF Symbols (200+ curated in 10 categories) | Built-in, monochromatic, no emojis, searchable |
| Color | true black bg (0.035), white text, pure monochrome | As requested |
| Cards | `monoCard()` + `monoHeroCard()` with gradient + shadow | Layered depth with white top-shadow glow |
| Persistence | JSON in Documents dir (vault_data.json) | Accessible, readable, recoverable |
| Backup | Security-scoped URL + bookmark in UserDefaults | User-controlled folder, survives reinstalls |
| Backup format | `vault_latest.json` + timestamped snapshots | Always have latest + full history |
| Number format | Indian system (₹1,23,45,678) via custom Int/Double extension | As specified |
| State | @Observable + @Environment(AppStore.self) | Swift 6 modern pattern |
| Navigation | TabView .page + custom 5-item bar w/ center + button | Free swipe, custom aesthetic |
| Add Transaction | Pull from top edge > 60pt or nav bar + button | Discoverable + gestural |

---

## Progress Log

### May 24, 2026
- [x] Analyzed existing project (Xcode 26, iOS 26 target, PBXFileSystemSynchronizedRootGroup)
- [x] Created directory structure (Theme / Models / Store / Services / Utilities / Components / Views)
- [x] Wrote all 22 Swift files (~4050 lines total)
- [x] Fixed tab bar layout (center + button flanked by 4 tab items)
- [x] Fixed force-unwrap safety in GoalMiniCard
- [x] Removed unused @Environment(AppStore.self) in ContentView
- [x] Cleaned up accidental directory
- [x] Committed to git

---

## % Complete: 100%

---

## How to Add Geist Mono (Optional)

1. Download [Geist Mono](https://github.com/vercel/geist-font) → `GeistMono-Regular.ttf`, `GeistMono-Bold.ttf`, etc.
2. Add to `monotargets/` folder (Xcode auto-syncs)
3. Add to Info.plist: `UIAppFonts` → item → `GeistMono-Regular`
4. In `MonoTheme.swift`, replace `.system(design: .monospaced)` with:
   ```swift
   Font.custom("GeistMono-Regular", size: size).weight(weight)
   ```

## How to Use Backup

1. Open **Settings** tab
2. Tap **Backup Folder** → pick any folder via Files picker
3. From now on, every transaction, goal, or assign automatically writes:
   - `vault_latest.json` (overwritten on every change — always fresh)
   - `vault_backup_YYYYMMDD_HHMMSS.json` (timestamped snapshot)
4. To restore: tap **Restore from JSON** → pick any backup file

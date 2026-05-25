#!/bin/bash
set -e

PROJECT_ROOT="$HOME/Xcode/monotargets"
REPO_NAME="monotargets"

echo "📁 Moving to project root..."
cd "$PROJECT_ROOT"

# ──────────────────────────────────────────────
# Write .gitignore
# ──────────────────────────────────────────────
echo "✍️  Writing .gitignore..."
cat > .gitignore << 'GITIGNORE'
# Xcode
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.xcuserstate
*.xcscmblueprint

# Xcode Workspace
.idea/
*.xcworkspace/xcuserdata/
*.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods
Pods/
*.xcworkspace
!default.xcworkspace

# Carthage
Carthage/Build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output/

# macOS
.DS_Store
.AppleDouble
.LSOverride
Icon
._*
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Claude Code internal
.claude/worktrees/
.claude/projects/
GITIGNORE

# ──────────────────────────────────────────────
# Write README.md
# ──────────────────────────────────────────────
echo "✍️  Writing README.md..."
cat > README.md << 'README'
<div align="center">
  <h1>Monotargets</h1>
  <p>A true-black, monospace savings tracker for iOS. No ads. No subscriptions. No bloat.</p>
  <p>
    <img src="https://img.shields.io/badge/platform-iOS-black?style=flat-square" />
    <img src="https://img.shields.io/badge/swift-6-black?style=flat-square&logo=swift" />
    <img src="https://img.shields.io/badge/swiftui-5-black?style=flat-square" />
    <img src="https://img.shields.io/badge/license-MIT-black?style=flat-square" />
  </p>
</div>

---

## What It Does

Most savings apps are either drowning in ads, locked behind a paywall, or so bloated they feel like filing taxes just to log a purchase. Monotargets is the opposite.

It's a single-purpose, offline-first savings tracker built with a strict monochrome aesthetic and a focus on feel — smooth animations, satisfying haptics, and a progress ring that actually motivates you to fill it up.

---

## Features

**Goal Tracking**
Set a target amount, deadline, and optional photo for each savings goal. Assign and unassign funds with a progress ring that updates in real time.

**Smart ETA**
Calculates how long it'll take to fund each goal based on your actual assign history over the last 60 days — not a made-up average.

**Transaction Categories**
12 categories with a live spending breakdown in your history so you can see exactly where money goes.

**Monthly Reminders**
Per-goal reminders set to whatever day of the month works for you.

**Multi-Currency Support**
9 currencies with correct locale-aware number formatting, including Indian number format (₹1,23,45,678).

**100% Offline**
No account required. No cloud sync. Your data lives on your device and backs up to a folder of your choice.

---

## Architecture

```
monotargets/
├── monotargetsApp.swift         App entry + @Observable injection
├── ContentView.swift            Root navigation shell
├── Theme/
│   └── MonoTheme.swift          Design tokens: colors, typography, spacing, radius
├── Models/
│   ├── Transaction.swift        Inward / outward / assigned transactions
│   ├── SavingsItem.swift        Savings goal with computed progress properties
│   └── VaultData.swift          Codable envelope for JSON persistence
├── Store/
│   └── AppStore.swift           @Observable central state + JSON persistence
├── Services/
│   └── BackupService.swift      Security-scoped folder access + auto JSON backup
├── Utilities/
│   └── Formatters.swift         Indian number formatting, date formatters
├── Components/
│   ├── AnimatedAmountText.swift  Per-digit bounce transition animation
│   ├── IconPickerView.swift      SF Symbols picker (~200 icons, 10 categories)
│   ├── ProgressArc.swift         Circular ring, linear bar, balance segment bar
│   └── HapticFeedback.swift      Centralized haptic feedback helper
└── Views/
    ├── RootView.swift            TabView .page swipe + custom center-add tab bar
    ├── HomeView.swift            Balance hero card + goals scroll + recent transactions
    ├── GoalsView.swift           All savings goals + stats header
    ├── HistoryView.swift         Grouped transaction history with filters
    ├── GoalDetailView.swift      Progress ring, stats grid, assign/unassign
    ├── AddTransactionView.swift  Pull-down transaction panel with custom numpad
    ├── CreateGoalView.swift      Create/edit savings goal
    ├── AssignFundsView.swift     Assign funds with quick % shortcuts
    └── SettingsView.swift        Backup folder picker, restore, data stats
```

**Stack:** SwiftUI · Swift 6 · @Observable · SF Symbols · No third-party dependencies

---

## Backup & Restore

1. Open the **Settings** tab
2. Tap **Backup Folder** and pick any folder via the Files picker
3. Every change automatically writes `vault_latest.json` (always fresh) and a timestamped snapshot
4. To restore: tap **Restore from JSON** and pick any backup file

---

## Built With Claude Code

Monotargets was designed and shipped entirely through conversation with Claude Code — zero prior iOS experience. The animations, haptics, onboarding, and the full dark monochrome UI all came together through iterative prompting and refinement.

---

## License

MIT — use it, fork it, learn from it.
README

# ──────────────────────────────────────────────
# Git setup
# ──────────────────────────────────────────────
echo "🔧 Checking git status..."

if [ ! -d ".git" ]; then
  echo "Initializing git repo..."
  git init
  git branch -M main
fi

# Remove any old remote
git remote remove origin 2>/dev/null || true

echo "📦 Staging files..."
git add .
git add .gitignore README.md

echo "💬 Committing..."
git commit -m "Initial public release

- Goal tracking with targets, deadlines, and optional photo
- Smart ETA based on 60-day rolling assign history
- 12 transaction categories with spending breakdown
- Monthly reminders per goal
- 9-currency support with Indian number formatting
- 100% offline, no ads, no subscriptions
- Auto-backup to user-chosen folder (JSON, security-scoped)" \
  2>/dev/null || echo "Nothing new to commit, proceeding..."

# ──────────────────────────────────────────────
# Create GitHub repo and push
# ──────────────────────────────────────────────
echo "🚀 Creating GitHub repo and pushing..."
gh repo create "$REPO_NAME" \
  --public \
  --description "A true-black, monospace savings tracker for iOS. No ads. No subscriptions. Built with SwiftUI." \
  --source=. \
  --remote=origin \
  --push

echo ""
echo "✅ Done! Your repo is live at:"
gh repo view --json url -q .url

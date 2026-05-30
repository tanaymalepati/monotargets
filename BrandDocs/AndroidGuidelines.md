# Android Development Guidelines

This document outlines the strict requirements for replicating the "Mono" brand experience natively on Android.

## 1. Native Smoothness & Performance
- The Android application MUST match or exceed the 120Hz liquid-smooth performance of the iOS application.
- Use **Jetpack Compose** natively to build the UI, completely avoiding hybrid frameworks unless explicitly approved.
- Replicate the exact spring animations, `.continuous` squircle corner radii (`RoundedCornerShape` with specialized smooth curves), and gesture-driven interactions (e.g., interactive carousels with 3D scaling and rotation).
- Use Android's `HapticFeedback` constants to perfectly mirror the tactile feel of the iOS app on button presses, toggles, and swipe gestures.

## 2. Brand & Theming Translation
- Translate the `MonoTheme` strictly into a Compose `MaterialTheme` or custom design system, adhering to the `BrandStyleGuide.md`.
- Ensure the monospaced typography is achieved using a premium monospaced Google Font (e.g., JetBrains Mono, Roboto Mono, or Space Mono) and applies identical tracking/kerning values.
- Replicate the complex drop shadows and gradients. Use custom `Canvas` drawing or elevated surfaces to achieve the deep, floating 3D card effects from iOS (e.g., rendering subtle inner highlights and large, dark shadows).

## 3. Google Ecosystem Integration
- **Payments & Billing**: Deeply integrate Google Play Billing API for any subscriptions or in-app purchases. It must be a native, frictionless 1-tap checkout experience without redirecting to web views.
- **Authentication**: Implement seamless Google Sign-In (One Tap) as the primary authentication mechanism.
- **Cloud & Sync**: Utilize Firebase (Firestore, Auth, Crashlytics) or Google Cloud services as the backend standard to ensure feature parity, push notifications, and realtime data sync across platforms.

## 4. Architecture
- Follow modern Android architecture (MVVM/MVI, Coroutines, StateFlow).
- Keep the codebase modular and clean, maintaining the same rapid iteration speed and robust state management as the iOS environment.

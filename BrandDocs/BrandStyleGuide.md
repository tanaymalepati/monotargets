# Mono Theme - Brand & UI/UX Style Guide

## Overview
This style guide defines the core design language for "Mono," establishing a dark-themed, ultra-premium, modern, and haptic-rich aesthetic. It serves as the foundation for developing any new applications under this brand.

## Colors & Theming
The app fundamentally supports dynamic light/dark modes but leans heavily into a deeply immersive dark mode aesthetic.
- **Backgrounds (`bg`)**: Pitch black in dark mode (`#000000`), off-white in light mode.
- **Surfaces**: Layered surfaces (`surface`, `surfaceUp`, `surfaceTop`) use subtle variations of dark grays (`#0D0D0D`, `#141414`, `#1F1F1F`) to build depth and elevation.
- **Borders**: Thin, subtle borders (`border`, `borderBright`) use white with low opacity to separate elements cleanly without clutter.
- **Typography**: 
  - Primary text (`text`): Pure white in dark mode.
  - Secondary/Tertiary/Dim text: Graded opacities for visual hierarchy.
- **Accents**: 
  - Primary Accent: Neon Cyan/Teal (`rgb(0, 255, 193)`).
  - Negative/Destructive: Vibrant Red (`rgb(255, 0, 100)`).
  - Positive/Success: Rich Green.

## Typography
The entire application strictly uses a **Monospaced Design** (`.monospaced` system font) for all text, giving it a technical, precise, and premium feel.
- **Hero & Big Numbers**: Large, bold fonts (e.g., `56pt Bold`, `38pt Bold`).
- **Body & Titles**: Structured hierarchy (`22pt Bold` for titles, `15pt Regular` for body).
- **Overline Labels**: Small, uppercase text (`10pt Semibold`) with wide tracking (`2pt spacing`) used for subtitles and metadata.

## Spacing & Layout
A strict 8-point grid system is enforced.
- **Micro**: `4pt`, `8pt`
- **Standard**: `16pt`, `24pt`
- **Macro**: `32pt`, `48pt`, `64pt`

## Corner Radii (Squircles)
All rounded corners MUST use `.continuous` squircle styling. 
- **Cards**: `16pt` to `28pt` depending on card size.
- **Inner elements**: `12pt`.
- **Buttons & Icons**: `10pt`.
- **Pills**: `100pt` (fully rounded capsules).

## Gradients & Materials
- **Cards**: Layered linear gradients running from top-left to bottom-right, creating a metallic or glass-like sheen.
- **Progress Bars**: Neon cyan gradients for progress fills, contrasting sharply against muted backgrounds.
- **Shadows**: Heavy, deep drop shadows (`radius: 18-30`, `y: 8-14`, black with 50-65% opacity) to float elements off the pitch-black background. Inner subtle white highlights (`y: -1`) create a 3D bevel effect.

## UX Experience & Micro-Interactions
- **Haptics**: Essential to the experience. Every button press, toggle, and swipe must be accompanied by appropriate haptic feedback (`light`, `medium`, `success`).
- **Animations**: Swift, spring-based animations (`spring(duration: 0.2, bounce: 0.4)`) for all button presses and state transitions. Elements should visibly scale down (e.g., `0.96` or `0.92`) when pressed.
- **Interactive Gestures**: Swiping and scrolling should feel native and fun. E.g., horizontal carousels use dynamic 3D scaling and rotation. Focused elements are full-sized and glowing, while unfocused elements shrink and tilt away.

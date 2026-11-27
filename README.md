# Security Monitoring Companion (`SecurityCompanionDemo`)

A modern, offline-first iOS security monitoring companion application built with **SwiftUI**, **Clean Architecture**, and a dedicated, prop-driven **SwiftUI Component Library**. Designed and optimized for **iOS 17.0+** and **Xcode 16.0+**, the app delivers zone status monitoring, arm/disarm security controls, an asynchronous event history screen with offline caching, user preferences, and mock authentication. All zone telemetry and activity events are driven by simulated and mock data without requiring physical security hardware.

---

## Table of Contents

- [Assignment Objectives & Scope](#assignment-objectives--scope)
- [Key Features](#key-features)
- [Component Library Overview](#component-library-overview)
- [Technology Stack & Requirements](#technology-stack--requirements)
- [Architecture Summary](#architecture-summary)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Open, Build, and Run in Xcode](#open-build-and-run-in-xcode)
  - [Running the Verified Test Suite](#running-the-verified-test-suite)
- [Mock Data & Initial Credentials](#mock-data--initial-credentials)
- [Simulator Screenshots](#simulator-screenshots)
- [Project Documentation](#project-documentation)

---

## Assignment Objectives & Scope

This mini-project establishes a reusable, component-driven **SwiftUI Presentation Layer** anchored by a prop-driven component library, seamlessly integrated into the existing **Security Monitoring Companion** platform:

1. **Dashboard with Zone List:** Property security posture overview (Partially Armed, All Armed, All Disarmed) and a scrollable list of monitored zones.
2. **Interactive Arm / Disarm Controls:** Dedicated, callback-only toggles (`AppZoneToggle`) with per-zone loading indicators, concurrency duplicate-tap guards, and disarm confirmation dialogs.
3. **Simulated Telemetry & Mock Feed:** 5 pre-seeded persistent IoT zones with simulated sensor telemetry (door contacts, motion detectors, glass breaks, smoke/temperature sensors) and a remote mock activity event feed.
4. **Event History Screen:** Asynchronous security feed with deterministic telemetry mapping, pull-to-refresh (`.refreshable`), severity badges, and offline cache fallback.
5. **Architectural Preservation:** Preserves existing SwiftData persistence, Clean Architecture separation of concerns, domain use cases, and full automated test coverage.

---

## Key Features

- **Component-Driven Dashboard:** Composed using `AppCard`, `AppBadge`, and `AppZoneToggle` components in a clean, spacious two-tier card layout.
- **Arm / Disarm Operations:** Immediate arming; disarm operations trigger an `AppConfirmationDialog` safety prompt when enabled in user preferences.
- **Robust Asynchronous Coordination:** Loading spinners are scoped to individual zones via `isZoneLoading(_:)`. Concurrency guards safely ignore duplicate taps during in-flight operations.
- **Cold-Boot Seeding Synchronization:** `AppContainer` coordinates initial persistence bootstrap so sample data is guaranteed to render on first cold launch without an empty-state flash.
- **Event History & Offline Fallback:** Fetches telemetry via `URLSession` with structured `async/await`, caches records into SwiftData, and falls back to local cache during network failures.
- **User Settings & Safety Preferences:** Account profile, configurable disarm confirmation toggle, and session management.
- **Accessibility Considerations:** Dynamic Type scaling across components, VoiceOver-optimized control grouping, and minimum 44pt touch targets on interactive component controls (including `AppZoneToggle`, `AppButton`, and the `AppBanner` dismiss button).

---

## Component Library Overview

The presentation layer is built on a standalone, reusable, prop-driven component library located in `SecurityCompanionDemo/Presentation/Components/`, supported by a centralized design-token system in `SecurityCompanionDemo/Core/Theme/AppTheme.swift`. The library consists of **six reusable SwiftUI components** and **one centralized design-token system**:

| Component / System | Role & Responsibilities | Key Configurable Props / Tokens | Integration Sites |
| :--- | :--- | :--- | :--- |
| **`AppTheme`** *(Design Tokens)* | Central design token repository for radii, spacing scale, semantic colors, and opacities. | Tokens: `CornerRadius`, `Spacing`, `Colors`, `Opacity` | Applied across all component styling |
| **`AppCard`** *(Component)* | Reusable surface container providing elevation, padding, and optional accent borders. | `padding: CGFloat`, `cornerRadius: CGFloat`, `borderColor: Color?`, `@ViewBuilder content: () -> Content` | `ZoneCardView` (monitored zones), `EventRowView` (activity events) |
| **`AppBadge`** *(Component)* | Standardized semantic pill badge for states, sensor health, and severities. | `_ text: String`, `iconName: String?`, `style: AppBadgeStyle`, `isSmall: Bool`, `showDot: Bool` | `ZoneCardView` (status & sensor alerts), `EventRowView` (severity indicators) |
| **`AppButton`** *(Component)* | Action button supporting visual styles, loading spinners, and full-width layouts. | `_ title: String`, `iconName: String?`, `variant: AppButtonVariant`, `isLoading: Bool`, `isEnabled: Bool`, `isFullWidth: Bool`, `cornerRadius: CGFloat`, `action: () -> Void` | `LoginView` (Sign In), `ZoneDetailView` (Arm/Disarm), `SettingsView` (Sign Out), `ZoneListView` & `EventListView` (Retry) |
| **`AppBanner`** *(Component)* | Contextual alert and status notification with optional dismiss control. | `title: String?`, `message: String`, `style: AppBannerStyle`, `iconName: String?`, `onDismiss: (() -> Void)?` | `ZoneListView` (error banner), `ZoneDetailView` (error banner), `EventListView` (simulation notice & refresh error) |
| **`AppConfirmationDialog`** *(Component Modifier)* | View modifier standardizing modal confirmation dialogs for critical actions. | `title: String`, `message: String`, `confirmTitle: String`, `confirmRole: ButtonRole?`, `cancelTitle: String`, `isPresented: Binding<Bool>`, `onConfirm: () -> Void` | `ZoneListView` (disarm confirmation), `ZoneDetailView` (disarm confirmation), `SettingsView` (sign-out confirmation) |
| **`AppZoneToggle`** *(Component)* | Dedicated, prop-driven arm/disarm toggle control with loading indicator. | `isArmed: Bool`, `isLoading: Bool`, `isEnabled: Bool`, `onToggle: () -> Void` | `ZoneCardView` (zone arm/disarm control) |

---

## Technology Stack & Requirements

| Component | Specification |
| :--- | :--- |
| **Operating System** | macOS 14.0+ (Sonoma) or macOS 15.0+ (Sequoia) |
| **IDE** | Xcode 16.0+ |
| **Target Platform** | iOS 17.0+ (Simulator & Device) |
| **Language & Concurrency** | Swift 5.0 (Xcode 16.0+) with Swift Concurrency (`async/await`, `@ModelActor`, `@MainActor`, `Sendable`) |
| **UI Framework** | SwiftUI (Observation framework: `@Observable`, `@Bindable`) |
| **Persistence Engine** | SwiftData (`ModelContainer`, `ModelContext`, `@ModelActor`) |
| **Networking** | Foundation `URLSession` with structured `async/await` |
| **Testing** | XCTest (**67 automated tests: 65 unit tests across five unit test suites, plus 2 UI tests**; all 67 passed in verified test run) |
| **Dependencies** | Pure native Apple frameworks (Zero external third-party packages) |

---

## Architecture Summary

The application enforces **Clean Architecture** with strict layer separation and unidirectional data flow:

```
┌────────────────────────────────────────────────────────────────────────┐
│                           Presentation Layer                           │
│   SwiftUI Views  •  @Observable ViewModels (@MainActor)               │
│   Reusable Component Library (AppCard, AppBadge, AppZoneToggle, etc.)  │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (Calls Use Cases / Observes State)
┌───────────────────────────────────┴────────────────────────────────────┐
│                              Domain Layer                              │
│   Entities  •  Repository Protocols  •  Use Cases                      │
│          (Pure Swift • Zero External Dependencies)                     │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (Implements Protocols)
┌───────────────────────────────────┴────────────────────────────────────┐
│                               Data Layer                               │
│   SwiftData Repositories (@ModelActor) • URLSession                    │
│   DTOs & Deterministic Mappers • Persistent Cache                      │
└────────────────────────────────────────────────────────────────────────┘
```

- **Unidirectional Interaction Flow:** UI components never mutate domain models or call repositories directly. Tapping `AppZoneToggle` invokes a closure, which flows through `ZoneListView` $\rightarrow$ `ZoneListViewModel` $\rightarrow$ `ArmZoneUseCase`/`DisarmZoneUseCase` $\rightarrow$ `SwiftDataZoneRepository` $\rightarrow$ State update.
- **Mandatory Dependencies:** `ZoneListViewModel` requires non-optional use-case dependencies in its initializer, preventing runtime silent failures.
- **Composition Root:** `AppContainer` centrally configures dependencies, initializes SwiftData persistent stores, coordinates startup seeding, and dispenses ViewModels.

For comprehensive architectural specifications, persistence schemas, and concurrency models, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Getting Started

### Prerequisites
- macOS running Xcode 16.0 or newer.
- An iOS 17.0+ Simulator runtime (recommended: **iPhone 16** or **iPhone 18 Pro**).

### Open, Build, and Run in Xcode

1. Open the Xcode project:
   ```bash
   open SecurityCompanionDemo.xcodeproj
   ```
2. In the Xcode scheme selector, choose **SecurityCompanionDemo** and target your preferred iOS Simulator.
3. Press **⌘R** (or **Product > Run**) to build and launch the app.

### Running the Verified Test Suite

The test suite includes **67 automated tests: 65 unit tests across five unit test suites, plus 2 UI tests**, verifying domain use cases, ViewModels, repository caching, concurrency guards, and SwiftData persistence. All 67 tests passed in the latest verified test run.

To run all tests in Xcode:
- Press **⌘U** (or select **Product > Test**).

To run the complete test suite from the command line:
```bash
xcodebuild test \
  -scheme SecurityCompanionDemo \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

To run only the unit test suites:
```bash
xcodebuild test \
  -scheme SecurityCompanionDemo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:SecurityCompanionDemoTests \
  -only-testing:EventFeedTests \
  -only-testing:ZonePersistenceTests \
  -only-testing:SettingsAndAuthTests \
  -only-testing:EventPersistenceTests
```

---

## Mock Data & Initial Credentials

### Sample Zones (Seeded on First Launch)
The persistent SwiftData database initializes with 5 monitored zones:
1. **Front Entry & Porch:** Armed (2 sensors: Front Door Contact, Porch Motion Detector [Low Battery 18%]).
2. **Living Room:** Disarmed (3 sensors: Main Living Motion, Patio Glass Break [Offline], Ambient Temperature).
3. **Backyard & Patio:** Armed (2 sensors: Patio Sliding Contact, Yard Perimeter Motion).
4. **Master Bedroom:** Disarmed (2 sensors: Window Contact, Smoke & CO Detector [Low Battery 15%]).
5. **Garage:** Armed (2 sensors: Overhead Door Contact, Side Entry Motion [Offline]).

### Mock Authentication
The session manager (`AuthSessionManager`) defaults to authenticated on first launch. For testing sign-out/sign-in flows:
- **Email:** `alex.morgan@example.com`
- **Password:** `password123`
- **User:** Alex Morgan (Primary Administrator)

---

## Simulator Screenshots

The following screenshots document the application's core screens and component library integration:

| Screen | File Location | Description |
| :--- | :--- | :--- |
| **Security Dashboard** | `Screenshots/Security Dashboard.png` | Main dashboard displaying aggregate posture, overview metrics, and zone cards composed with `AppCard`, `AppBadge`, and `AppZoneToggle`. |
| **Zone Arm / Disarm Interaction** | `Screenshots/Zone Arm Disarm Interaction.png` | Zone card displaying the in-flight loading spinner during an arm/disarm operation. *(Note: this transient state may be added when available without delaying submission).* |
| **Disarm Confirmation Dialog** | `Screenshots/Disarm Confirmation Dialog.png` | Native confirmation action sheet presented when requesting to disarm an active security zone. |
| **Event History Screen** | `Screenshots/Activity Feed.png` | Event timeline displaying event cards composed with `AppCard` and severity-coded `AppBadge`s. |
| **System Settings** | `Screenshots/Settings.png` | Settings screen displaying the "Require Disarm Confirmation" preference toggle and account information. |
| **Login Screen** | `Screenshots/Login Screen.png` | Authentication view with credential fields and mock administrator defaults. |

---

## Project Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — Comprehensive technical architecture specification, design tokens, component library catalog, and data flow.
- [WALKTHROUGH.md](WALKTHROUGH.md) — Step-by-step evaluator testing guide.

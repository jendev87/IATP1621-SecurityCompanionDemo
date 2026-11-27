# Security Monitoring Companion — Evaluator Testing Guide

This document provides a comprehensive, step-by-step evaluator testing guide to exercise and verify all functional requirements and component interactions of the **Security Monitoring Companion (`SecurityCompanionDemo`)** on an iOS Simulator.

---

## 1. Prerequisites & Launching the App

### Objective
Build, launch, and prepare a clean baseline state of the application.

### Environment Requirements
- **macOS:** 14.0+ (Sonoma) or 15.0+ (Sequoia)
- **Xcode:** 16.0+
- **Simulator Target:** iPhone 16 or iPhone 18 Pro (iOS 17.0+)
- **Dependencies:** None (Pure native Apple SwiftUI and SwiftData frameworks)

### Steps to Perform
1. Open `SecurityCompanionDemo.xcodeproj` in Xcode.
2. Select the **SecurityCompanionDemo** scheme and target an active iOS Simulator (e.g. `iPhone 16`).
3. Press **⌘R** (or select **Product > Run**) to build and launch the application.

### Restoring Default Seed Data for a Clean Evaluation
Because the application uses persistent on-disk storage with SwiftData, user state modifications (such as arming or disarming a zone) survive application restarts and force-quits.

To reset the application to its pristine initial seed state:
1. On the Simulator, return to the Home Screen (**⌘⇧H**).
2. Long-press the **SecurityCompanionDemo** app icon and select **Remove App > Delete App**, or execute via Terminal:
   ```bash
   xcrun simctl uninstall booted com.demo.SecurityCompanionDemo
   ```
3. Re-run the application from Xcode (**⌘R**).
4. On cold launch, `AppContainer` automatically seeds the 5 default sample zones into the local SwiftData store.

---

## 2. Mock Login Flow

### Objective
Verify authentication session handling, input validation, secure entry toggling, and initial transition.

### Steps to Perform
1. By default on first launch, the session manager (`AuthSessionManager`) is pre-authenticated to streamline evaluation.
2. To test the login interface: Navigate to **Settings** (gear icon in the navigation bar) and tap **Sign Out**. Confirm sign-out on the prompt.
3. The app displays `LoginView`. For evaluator convenience, mock administrator credentials are pre-populated:
   - **Email:** `alex.morgan@example.com`
   - **Password:** `password123`
4. Tap the **eye icon** (`Image(systemName: "eye")`) inside the password field to toggle password visibility between secure masked text and plain text.
5. Clear either the email or password field and tap **Sign In**.
6. Restore the credentials and tap **Sign In**.

### Expected Result
- When credentials are blank, a validation error banner appears: *"Please enter both email and password."*
- When valid credentials are submitted, a brief loading indicator displays on the button, the session authenticates, and the view transitions immediately to the **Security Dashboard**.

---

## 3. Security Dashboard & Zone Monitoring

### Objective
Verify the root `NavigationStack`, overview security posture calculations, and component-driven zone card rendering.

### Steps to Perform
1. Observe the navigation title: **Security Dashboard**.
2. Inspect the top security overview card:
   - Title: **Partially Armed**
   - Subtitle: **3 of 5 zones actively monitored**
   - Status badge: Shield icon with semantic warning tint (orange).
3. Inspect the three overview metric cards:
   - **Total:** `5`
   - **Armed:** `3`
   - **Disarmed:** `2`
4. Inspect the quick navigation shortcuts:
   - **Security Activity Feed** (*"View live timeline & security alerts"*) with chevron.
   - **System Settings** (*"Preferences, account & security rules"*) with chevron.
5. Inspect the **MONITORED ZONES (5)** list rendered with `ZoneCardView`:
   - **Front Entry & Porch:** Armed (green `AppCard` border, `ARMED` green `AppBadge`, `LOW BATT` orange `AppBadge`, `ARMED` green `AppZoneToggle`, 2 sensors).
   - **Living Room:** Disarmed (neutral `AppCard` border, `DISARMED` neutral `AppBadge`, `OFFLINE` red `AppBadge`, `DISARMED` neutral `AppZoneToggle`, 3 sensors).
   - **Backyard & Patio:** Armed (green `AppCard` border, `ARMED` green `AppBadge`, `ARMED` green `AppZoneToggle`, 2 sensors).
   - **Master Bedroom:** Disarmed (neutral `AppCard` border, `DISARMED` neutral `AppBadge`, `LOW BATT` orange `AppBadge`, `DISARMED` neutral `AppZoneToggle`, 2 sensors).
   - **Garage:** Armed (green `AppCard` border, `ARMED` green `AppBadge`, `OFFLINE` red `AppBadge`, `ARMED` green `AppZoneToggle`, 2 sensors).
6. Perform a pull-to-refresh by dragging downward on the list.

### Expected Result
- All 5 seeded zones render cleanly with consistent padding, typography, and badges.
- Armed cards feature a subtle green accent border (`AppCard`).
- Pull-to-refresh smoothly reloads data from the local SwiftData store without UI flicker or state desynchronization.

---

## 4. Zone Details & Sensor Telemetry

### Objective
Verify programmatic navigation, detailed zone telemetry, sensor status indicators, and battery gauges.

### Steps to Perform
1. From the dashboard, tap on the **Living Room** card (tap anywhere in the upper navigation area of the card).
2. The app pushes `ZoneDetailView` onto the `NavigationStack` with the inline title **Living Room**.
3. Inspect the **Security Status & Action Card**:
   - Shield icon displays gray `shield.slash` with status text **Disarmed**.
   - Subtitle displays *"Zone disarmed • System safe"*.
   - Prominent action button displays blue **Arm Zone**.
4. Inspect the **Sensor Overview Summary** chips:
   - Displays sensor health counts: **1 Online**, **1 Offline**, **1 Low Battery**.
5. Scroll through the **Connected Sensors** list:
   - **Main Living Motion:** Type icon `figure.walk`, status badge `Online` (green), Battery **85%** (green gauge).
   - **Patio Glass Break:** Type icon `shield.lefthalf.filled`, status badge `Offline` (red), Battery **0%** (red gauge with low battery callout).
   - **Ambient Temperature:** Type icon `thermometer.medium`, status badge `Online` (green), Battery **74%** (green gauge).
6. Tap the navigation back button to return to the **Security Dashboard**.

### Expected Result
- Navigating to zone details presents full IoT telemetry without mutating the zone's armed/disarmed state.
- Sensor health warnings (offline, low battery $\le 20\%$) are visually distinct from the zone's operational security state.

---

## 5. Arm / Disarm Operations & Confirmation Behaviour

### Objective
Verify domain business rules for arming and disarming zones, scoped per-zone loading states, concurrency duplicate-tap protection, and the disarm confirmation dialog.

### Steps to Perform

#### 5.1 Direct Arming (Living Room)
1. On the dashboard, locate the **Living Room** card (currently `DISARMED`).
2. Tap the `AppZoneToggle` control on the right side of the card once.
3. Observe the scoped loading spinner inside the toggle.
4. Try tapping the toggle a second time while the spinner is active to test concurrency duplicate-tap protection.

#### 5.2 Disarm Confirmation & Cancellation (Front Entry & Porch)
1. Locate **Front Entry & Porch** (currently `ARMED`).
2. Tap its `AppZoneToggle` control once.
3. When the confirmation sheet appears:
   - Verify Dialog Title: **Disarm Zone**
   - Verify Message: *"Are you sure you want to disarm Front Entry & Porch?"*
   - Verify Actions: Red destructive **Disarm Zone** and **Cancel**.
4. Tap **Cancel**.
5. Tap the `AppZoneToggle` on **Front Entry & Porch** again.
6. This time, tap **Disarm Zone** on the confirmation sheet.

### Expected Result
- **Arming:**
  - `Living Room` displays a loading spinner during execution.
  - Duplicate taps during the in-flight operation are safely ignored.
  - Upon completion, the toggle transitions to green **ARMED**, the status badge updates to green **ARMED**, the card acquires a green border, and the dashboard metrics update to **Armed: 4**, **Disarmed: 1**.
- **Disarm Confirmation & Cancellation:**
  - Tapping Cancel dismisses the dialog with zero state change (`Front Entry & Porch` remains `ARMED`).
  - Confirming the disarm executes `DisarmZoneUseCase`, transitions the toggle and badge to **DISARMED**, removes the green border, and updates dashboard metrics to **Armed: 3**, **Disarmed: 2**.

---

## 6. Activity Feed, Pull-to-Refresh & Offline Behaviour

### Objective
Verify asynchronous telemetry fetching, deterministic mapping, pull-to-refresh, local SwiftData caching, and offline error resilience.

### Steps to Perform
1. From the dashboard, tap the **bell icon** in the top-right toolbar (or tap the **Security Activity Feed** shortcut).
2. The app pushes `EventListView` titled **Activity Feed**.
3. Inspect the overview tiles:
   - **Total**, **Critical**, **Warnings**, **Info** counts.
4. Inspect the **Simulated Activity Feed** notice banner explaining that telemetry is deterministically generated from mock REST posts (`JSONPlaceholder`).
5. Scroll through the **RECENT EVENTS** list:
   - Each event is wrapped in an `AppCard` with severity-coded border strokes (red for Critical, orange for Warning).
   - Severity is rendered via `AppBadge` with a colored indicator dot:
     - `INFO` (blue)
     - `WARNING` (orange)
     - `CRITICAL` (red)
6. **Pull-to-Refresh:** Pull down on the feed to trigger a network refresh.
7. **Offline Fallback Test:**
   - Turn off Wi-Fi on the host Mac (or enable 100% Loss in the Network Link Conditioner).
   - Pull down to refresh again.
   - Observe the transient warning banner: *"Unable to refresh events. Displaying cached events."*
   - Tap the **"X"** button on the banner to dismiss it.
   - Verify that all cached events remain fully visible and readable.
   - Re-enable your network connection.

### Expected Result
- Events load asynchronously sorted newest-first.
- Pull-to-refresh re-queries the remote endpoint and updates the persistent SwiftData cache.
- During a network failure, the application gracefully displays cached records without blanking the screen or crashing, and presents a dismissible `AppBanner`.

---

## 7. Settings & Preferences

### Objective
Verify account information display, security preference toggles, and dynamic control of the disarm confirmation requirement.

### Steps to Perform
1. From the dashboard, tap the **gear icon** in the top-right toolbar (or tap the **System Settings** shortcut).
2. The app pushes `SettingsView` titled **Settings**.
3. Review the **Account** section:
   - Name: **Alex Morgan**
   - Email: **alex.morgan@example.com**
   - Role: **Primary Administrator**
   - Property: **Oakwood Family Residence**
4. In **Security Preferences**, locate the toggle: **Require Disarm Confirmation** (enabled by default).
5. Switch **Require Disarm Confirmation** to **OFF**.
6. Tap the navigation back button to return to the **Security Dashboard**.
7. Locate an armed zone (e.g. **Backyard & Patio**) and tap its `AppZoneToggle`.
8. Return to **Settings** and switch **Require Disarm Confirmation** back to **ON**.

### Expected Result
- When the preference is switched OFF, tapping the toggle on an armed zone disarms it immediately with a single tap, completely bypassing the confirmation sheet.
- Re-enabling the preference restores the modal confirmation safety sheet on subsequent disarm attempts.
- Preferences persist immediately via `UserDefaults`.

---

## 8. Sign-Out & Persistence Verification Across App Relaunch

### Objective
Verify session teardown, credential clearing, and disk persistence of SwiftData records across application restarts.

### Steps to Perform
1. In **Settings**, scroll to the bottom section and tap **Sign Out**.
2. A confirmation dialog appears:
   - Title: **Sign Out**
   - Message: *"Are you sure you want to sign out? Your stored security data and preferences will remain intact."*
3. Tap **Sign Out**.
4. Verify the application returns to `LoginView`.
5. Tap **Sign In** to log back in.
6. On the dashboard, observe the current state of zones (e.g. the zone armed or disarmed in Step 5).
7. **Process Termination & Relaunch Test:**
   - Terminate the running application in Xcode (**⌘.** or Stop button), or force-quit the app in the Simulator via the app switcher.
   - Re-launch the app from Xcode (**⌘R**).

### Expected Result
- Signing out clears the active authentication session without deleting SQLite data.
- Re-authenticating restores the dashboard with all modified zone states and cached activity events intact.
- Terminating and relaunching the app proves that SwiftData persists all state changes to disk:
  - Zones that were armed or disarmed retain their updated states.
  - Total, Armed, and Disarmed counts accurately reflect the persisted state.
  - Seed data is not duplicated or overwritten.

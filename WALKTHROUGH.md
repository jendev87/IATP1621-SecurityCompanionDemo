# Security Monitoring Companion — Evaluator Simulator Walkthrough

This document provides an evaluator-friendly, step-by-step testing guide to exercise all functional requirements of the **Security Monitoring Companion (`SecurityCompanionDemo`)** on an iOS Simulator.

---

## Prerequisites & Launching the App

1. Open `SecurityCompanionDemo.xcodeproj` in **Xcode 16.0+**.
2. Select an iOS 17.0+ Simulator (recommended: **iPhone 16** or **iPhone 18 Pro**).
3. Press **⌘R** to build and run the application.

---

## Step 1: Mock Login Flow

### Objective
Verify authentication entry, input controls, password masking/unmasking, and login validation.

### Steps
1. Upon launch, if the app starts on the **Security Dashboard**, navigate to **Settings** (gear icon in the navigation bar) and tap **Sign Out** to return to the **Login Screen**.
2. On the **Login Screen**, observe the branding ("Security Companion"), description, and credentials form.
3. The mock credentials are pre-populated for grading convenience:
   - **Email:** `alex.morgan@example.com`
   - **Password:** `password123`
4. Tap the **eye icon** inside the password field to toggle password visibility. Verify the plain text password reveals and masks correctly.
5. Clear the email or password field and tap **Sign In**. Observe the validation error banner: *"Please enter both email and password."*
6. Restore the credentials and tap **Sign In**.
7. Observe a brief loading spinner (`ProgressView`) on the button, followed by seamless transition to the **Security Dashboard**.

---

## Step 2: Security Dashboard & Zone Monitoring

### Objective
Verify the root `NavigationStack`, aggregate security overview, and zone card status rendering.

### Steps
1. On the **Security Dashboard**, observe the top banner displaying the aggregate property state:
   - **Title:** *"Partially Armed"* (or *"All Zones Armed"* depending on current state).
   - **Subtitle:** Indicates how many zones are actively monitored (e.g., *"2 of 4 zones actively monitored"*).
   - **Status Badge:** Circular shield icon reflecting system posture.
2. Review the list of monitored zones seeded automatically on initial run:
   - **Front Entry & Porch:** Armed (Green shield icon `shield.fill`, "Armed" status badge, 2 sensors).
   - **Living Room:** Disarmed (Gray shield slash icon `shield.slash`, "Disarmed" status badge, 3 sensors).
   - **Backyard & Patio:** Armed (Green shield icon `shield.fill`, 2 sensors).
   - **Garage & Driveway:** Disarmed (Gray shield slash icon `shield.slash`, 2 sensors).
3. Pull down on the list to trigger pull-to-refresh (`.refreshable`). The dashboard reloads its state from the local SwiftData repository smoothly without UI flicker.

---

## Step 3: Zone Details & Sensor Health Telemetry

### Objective
Verify child navigation, detailed zone security controls, sensor summary chips, and battery indicators.

### Steps
1. Tap on the **Living Room** zone card from the dashboard.
2. Verify navigation pushes `ZoneDetailView` onto the `NavigationStack` with the title *"Living Room"*.
3. Inspect the **Security Control Card**:
   - Shield icon displays gray `shield.slash` with status text *"Disarmed"*.
   - Action button displays blue *"Arm Zone"*.
4. Inspect the **Sensor Overview Summary**:
   - Chips summarize sensor health: **2 Online**, **1 Attention**, **1 Low Battery**.
5. Scroll through the **Connected Sensors** list:
   - **Main Living Motion:** Type icon `figure.walk`, status badge *"Online"*, Battery **85%** (Green gauge).
   - **Patio Glass Break:** Type icon `shield.lefthalf.filled`, status badge *"Offline"*, Battery **0%** (Red warning gauge and attention callout).
   - **Ambient Temperature:** Type icon `thermometer.medium`, status badge *"Online"*, Battery **74%** (Green gauge).
6. Verify VoiceOver accessibility by inspecting the battery element: VoiceOver reads combined values such as *"Battery level, 85 percent"*.

---

## Step 4: Arm / Disarm Operations & Confirmation Behavior

### Objective
Verify domain business rules for arming and disarming zones, including safety confirmation dialogs.

### Steps
1. While still on the **Living Room** detail screen (currently Disarmed):
   - Tap **Arm Zone**.
   - Observe immediate state transition: the shield updates to green `shield.fill`, status changes to *"Armed"*, and the button changes to destructive red *"Disarm Zone"*.
2. Now test disarming with confirmation protection:
   - Tap **Disarm Zone**.
   - Because the safety preference is enabled by default, a native confirmation action sheet appears:
     - **Title:** *"Confirm Disarm"*
     - **Message:** *"Are you sure you want to disarm Living Room? Perimeter sensors will stop triggering active alarms."*
   - Tap **Cancel** to verify the zone remains Armed.
   - Tap **Disarm Zone** again, then tap **Disarm Zone** on the confirmation sheet.
   - The zone transitions back to *"Disarmed"*.
3. Tap the back button in the navigation bar to return to the **Security Dashboard**.
4. Confirm the dashboard immediately reflects the updated state and recalculates the overall status banner accordingly.

---

## Step 5: Activity Feed, Pull-to-Refresh & Error Handling

### Objective
Verify asynchronous mock API integration, deterministic mapping, pull-to-refresh, and transient error dismissals.

### Steps
1. From the dashboard toolbar, tap the **bell icon** (or the *"View Activity Feed"* shortcut button) to navigate to the **Activity Feed**.
2. Notice the feed fetches remote data from `https://jsonplaceholder.typicode.com/posts?_limit=15` via `URLSession`.
3. Review the timeline of events:
   - Events are deterministically mapped by `SecurityEventMapper` to realistic security telemetry (e.g., *"Motion sensor in Living Room triggered"*, *"Front Door Contact opened"*, *"System Armed"*, *"Sensor Offline"*).
   - Severity badges reflect the event priority: **INFO** (blue/gray), **WARNING** (orange), **CRITICAL** (red).
   - Timestamps are sorted in chronological order (newest first).
4. **Pull-to-Refresh:** Pull down on the feed to trigger a refresh. The spinner appears, fetches updated posts, and upserts them into the local SwiftData cache.
5. **Offline / Error Handling Test:**
   - Turn off Wi-Fi on your host Mac, or toggle Simulator Network Link Conditioner to 100% Loss.
   - Pull down to refresh again.
   - Observe the transient refresh error banner: *"Unable to refresh events. Displaying cached events."*
   - Notice that the existing feed remains fully visible and readable (offline fallback).
   - Tap the **"X" (Dismiss)** button on the error banner. Verify the error banner disappears cleanly while retaining the cached events.
   - Restore your network connection.

---

## Step 6: User Settings & Preference Configuration

### Objective
Inspect user account overview, toggle security preferences, and verify preference persistence.

### Steps
1. Return to the dashboard and tap the **gear icon** in the top-right toolbar to open **Settings**.
2. Review the **Account** section:
   - Displays User Name: **Alex Morgan**.
   - Email: **alex.morgan@example.com**.
   - Role badge: **Primary Administrator**.
   - Property: **Oakwood Family Residence**.
3. Inspect **Security Preferences**:
   - Locate the toggle: **"Require Disarm Confirmation"**.
   - Switch it **OFF**.
4. Test the disabled confirmation preference:
   - Navigate back to the dashboard, select any armed zone (e.g., **Front Entry & Porch**).
   - Tap **Disarm Zone**.
   - Verify the zone disarms immediately without presenting the confirmation action sheet.
5. Return to **Settings** and switch **"Require Disarm Confirmation"** back **ON**.

---

## Step 7: Sign Out & Re-Authentication

### Objective
Verify session termination, destructive confirmation dialogs, and returning to the login flow.

### Steps
1. In **Settings**, scroll to the bottom and tap **Sign Out**.
2. Observe the native confirmation dialog:
   - *"Are you sure you want to sign out? Your stored security data and preferences will remain intact."*
3. Tap **Sign Out**.
4. The application clears the active session and transitions immediately back to `LoginView`.
5. Tap **Sign In** to log back in. Verify the user returns to the dashboard with all zones, sensor telemetry, and preferences fully intact.

---

## Step 8: Persistence Verification Across App Relaunch

### Objective
Prove that SwiftData stores data to disk and that state changes survive application process termination.

### Steps
1. On the dashboard, tap **Living Room** $\rightarrow$ tap **Arm Zone** (so it becomes **Armed**).
2. Note the count of armed zones on the dashboard banner (e.g., *"3 of 4 zones actively monitored"*).
3. **Terminate the app process:**
   - In Xcode, click the **Stop (■)** button in the toolbar (or press **⌘.**), OR
   - On the Simulator, swipe up from the bottom to enter the app switcher and swipe up on **SecurityCompanionDemo** to kill the process.
4. **Relaunch the app:**
   - In Xcode, press **⌘R** to relaunch the application.
5. **Verify data integrity:**
   - The dashboard opens without requiring re-seeding.
   - **Living Room** remains **Armed**.
   - All sensors, battery readings, and cached activity feed events remain fully preserved.

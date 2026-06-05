# Arcta Example — steadpay-flutter

A fictional analytics SaaS app that demonstrates a complete `steadpay_flutter` integration. Arcta is used as the host app throughout Steadpay's example suite so you can compare SDK behaviour across platforms side by side.

## Screens

| Screen | File | Purpose |
|--------|------|---------|
| Login | `lib/login_screen.dart` | Fake login form — any credentials navigate to Home |
| Home | `lib/home_screen.dart` | Main content wrapped in `SteadpaySandbox` |
| Settings | `lib/settings_screen.dart` | Static account info screen |
| Content | `lib/arcta_content.dart` | Fake analytics dashboard — the "protected" content |

`SteadpaySandbox` lives in `home_screen.dart`. It wraps `ArctaContent` and surfaces a `DEV` badge in the bottom-right corner of the screen.

## Running

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.0+
- For iOS: macOS with Xcode 16.4.0
- For Android: Android Studio with an emulator (API 26+) or a physical device

Install dependencies from the example directory:

```sh
cd example
flutter pub get
```

### iOS Simulator

```sh
flutter run -d "iPhone 16 Pro"
```

List available simulators: `flutter devices`. Hot reload is available — press **r** in the terminal after making changes.

### Android Emulator

Start an emulator from Android Studio's AVD Manager first, then:

```sh
flutter run -d emulator-5554
```

Or let Flutter pick the only available device: `flutter run`.

### Both platforms simultaneously

```sh
flutter run -d all
```

### Physical device (iOS or Android)

```sh
flutter devices   # list connected devices
flutter run -d <device-id>
```

Flutter detects both iOS and Android devices automatically. iOS requires a trusted developer certificate (a free Apple account works).

> Physical devices can't reach `localhost`. Use ngrok (`ngrok http 3000`) to expose your local Steadpay instance and enter the ngrok URL in Live mode. The Android Emulator reaches the host machine at `10.0.2.2` — use `http://10.0.2.2:3000` instead of `localhost`.

## Testing with SteadpaySandbox

### Sandbox mode (no server needed)

1. Sign in with any credentials and navigate to Home.
2. Tap the **DEV** badge in the bottom-right corner.
3. A bottom sheet slides up showing four state pills: `active`, `warning`, `lockout`, `error`.
4. Tap any pill — the UI transitions immediately. No network calls, no rebuild.

What to verify in each state:

| State | Expected behaviour |
|-------|--------------------|
| `active` | Content renders normally; no banner, no gate |
| `warning` | Amber banner appears above content; tap **Dismiss** to hide for the session |
| `lockout` | Full-screen gate covers all content; nothing behind it is tappable |
| `error` | Content still renders (fail open); no crash |

The sheet also shows a **callback log** (last 5 invocations). Confirm `onLockout`, `onWarning`, and `onActive` fire on the correct transitions without adding `debugPrint` calls.

### Sandbox mode — what fires and what doesn't

| Transition | Callback fired |
|-----------|---------------|
| `active → warning` | `onWarning` |
| `active → lockout` | `onLockout` |
| `warning → lockout` | `onLockout` |
| `lockout → active` | `onActive` |
| `warning → active` | `onActive` |
| any → `error` | `onError` |
| same → same | nothing |

`onRecovered` is **not** fired by the sandbox — it requires the real card update flow. Test it in Live mode with a Stripe test card.

### Live mode (real Steadpay instance)

1. Start Steadpay locally (`npm run dev`) and expose it via ngrok (physical device) or use `http://10.0.2.2:3000` (Android Emulator) or `http://localhost:3000` (iOS Simulator).
2. Run `npm run seed` to create the `test-harness` tenant and seeded subscribers.
3. In the example app, tap the **DEV** badge and switch to **Live** mode in the sheet.
4. Enter:
   - **API base**: ngrok URL, `http://10.0.2.2:3000`, or `http://localhost:3000`
   - **Tenant slug**: `test-harness`
   - **Publishable key**: from the seed script output
   - **Customer ID**: one of `cus_harness_active`, `cus_harness_warning`, `cus_harness_lockout`
5. Tap **Connect** — the SDK polls the real status API.

To force a state transition mid-test, update the subscriber in Postgres:

```sql
UPDATE subscribers SET status = 'lockout'
WHERE stripe_customer_id = 'cus_harness_warning';
```

Background the app and foreground it — `WidgetsBindingObserver.didChangeAppLifecycleState` fires a poll when the app resumes and the `SteadpayController` notifies listeners.

> Flutter is the only SDK where one codebase targets both iOS and Android. After triggering a state change, verify the UI on both platforms in the same session with `flutter run -d all`.

## Integration reference

```dart
// lib/home_screen.dart
import 'package:steadpay_flutter/steadpay_flutter.dart';

SteadpaySandbox(
  onLockout: () => debugPrint('lockout'),
  onWarning: () => debugPrint('warning'),
  onActive: () => debugPrint('active'),
  child: const ArctaContent(),
)
```

For production, replace `SteadpaySandbox` with `SteadpayGate`:

```dart
import 'package:steadpay_flutter/steadpay_flutter.dart';

SteadpayGate(
  apiBase: 'https://api.steadpay.com',
  tenantSlug: 'your-slug',
  publishableKey: 'pk_live_xxx',
  customerId: currentUser.stripeCustomerId,
  onLockout: () => analytics.track('billing_lockout'),
  onRecovered: () => analytics.track('billing_recovered'),
  child: YourApp(),
)
```

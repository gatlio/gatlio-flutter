# steadpay_flutter

Flutter SDK for [Steadpay](https://steadpay.io) billing enforcement. Drop-in widget that enforces subscriber billing states natively — no WebView, no platform channels.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  steadpay_flutter:
    git:
      url: https://github.com/steadpay/steadpay-flutter.git
```

## Quick start

Wrap the authenticated portion of your app in `SteadpayGate`:

```dart
import 'package:steadpay_flutter/steadpay_flutter.dart';

SteadpayGate(
  apiBase: 'https://app.steadpay.io',
  tenantSlug: 'acme',
  customerId: currentUser.stripeCustomerId,
  publishableKey: 'pk_live_abc123',
  child: YourApp(),
)
```

When billing is current, `YourApp` renders normally. In `warning` state a dismissable banner appears above it. In `lockout` a full-screen overlay replaces all content until the card is updated.

## `SteadpayGate` — parameters

| Parameter | Type | Required | Default |
|-----------|------|----------|---------|
| `apiBase` | `String` | ✓ | — |
| `tenantSlug` | `String` | ✓ | — |
| `customerId` | `String` | ✓ | — |
| `publishableKey` | `String` | ✓ | — |
| `pollInterval` | `Duration` | | `Duration(minutes: 10)` |
| `forcedStatus` | `SteadpayStatus?` | | `null` |
| `callbacks` | `SteadpayCallbacks?` | | `null` |
| `lockoutScreen` | `LockoutScreenBuilder?` | | built-in |
| `warningBanner` | `WarningBannerBuilder?` | | built-in |
| `child` | `Widget` | ✓ | — |

## Callbacks

```dart
SteadpayGate(
  // ...
  callbacks: SteadpayCallbacks(
    onLockout: () => print('locked out'),
    onWarning: () => print('warning'),
    onActive: () => print('active'),
    onRecovered: () => print('recovered after card update'),
    onError: (err) => print('error: $err'),
  ),
  child: YourApp(),
)
```

Callbacks fire on status *transitions*, not on every poll tick. `onRecovered` fires only when a lockout resolves via the real card update flow.

## Custom enforcement UI

```dart
SteadpayGate(
  // ...
  lockoutScreen: ({required triggerCardUpdate, entitlements, required message, required cta}) =>
      MyBrandedLockout(onUpdate: triggerCardUpdate, message: message, cta: cta),
  warningBanner: ({required dismissWarning, required message}) =>
      MyBrandedBanner(message: message, onDismiss: dismissWarning),
  child: YourApp(),
)
```

## Testing your integration

### Force a state — `forcedStatus`

```dart
SteadpayGate(
  apiBase: 'https://app.steadpay.io',
  tenantSlug: 'acme',
  customerId: 'cus_test',
  publishableKey: 'pk_test_abc',
  forcedStatus: SteadpayStatus.lockout,  // no network calls
  child: YourApp(),
)
```

Remove `forcedStatus` before shipping.

### Interactive harness — `SteadpaySandbox`

`SteadpaySandbox` is a drop-in dev widget that lets you switch billing states and verify your callbacks without a real Steadpay account.

**How it works:** your content renders at full size with a small `DEV` badge anchored to the bottom-right corner as a true overlay. Tap the badge to open a control sheet; tap a state pill to switch states; tap the backdrop to dismiss the sheet.

```dart
import 'package:steadpay_flutter/steadpay_flutter.dart';

SteadpaySandbox(
  onLockout: () => print('locked out'),
  onWarning: () => print('warning'),
  onActive: () => print('active'),
  onError: (err) => print('error: $err'),
  child: YourApp(),
)
```

The sandbox accepts custom `lockoutScreen` and `warningBanner` overrides — pass them to verify your own UI and dismiss handlers:

```dart
SteadpaySandbox(
  lockoutScreen: ({required triggerCardUpdate, entitlements, required message, required cta}) =>
      MyBrandedLockout(onUpdate: triggerCardUpdate, message: message, cta: cta),
  warningBanner: ({required dismissWarning, required message}) =>
      MyBrandedBanner(message: message, onDismiss: dismissWarning),
  child: YourApp(),
)
```

**What the control sheet shows:**
- Four state pills (`active`, `warning`, `lockout`, `error`) — tap to transition
- Current-status indicator
- Callback log (last 5 invocations, newest first)
- `onRecovered` limitation note

**Callback rules:**

| Transition | Fires |
|-----------|-------|
| `active → warning` | `onWarning` |
| `active → lockout` | `onLockout` |
| `warning → lockout` | `onLockout` |
| `lockout → active` | `onActive` |
| `warning → active` | `onActive` |
| any → `error` | `onError` (first press only) |
| same → same | nothing |

**`onRecovered` is not fired by the sandbox** — it requires the real card update flow. Test it against a live Steadpay environment.

Remove `SteadpaySandbox` before shipping to production.

## Direct controller usage

For custom state management (Riverpod, Bloc, etc.):

```dart
final controller = SteadpayController(
  SteadpayConfig(
    apiBase: 'https://app.steadpay.io',
    tenantSlug: 'acme',
    customerId: currentUser.stripeCustomerId,
    publishableKey: 'pk_live_abc123',
  ),
);
controller.start();

// Listen to stateStream and dismissedStream independently
StreamBuilder<SteadpayState>(
  stream: controller.stateStream,
  builder: (context, snap) { ... },
)
```

Call `controller.dispose()` when done.

## License

MIT

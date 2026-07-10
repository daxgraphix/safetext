# SafeText

**Enterprise-Grade Offline Text Steganography Platform for Android**
_Private Messages Hidden in Plain Sight_

SafeText hides encrypted text messages inside ordinary images using LSB
steganography, so an observer sees only a normal photo. It runs 100%
offline — no login, no account, no network calls.

## Modules

### Core (original release)
Home dashboard, Encode/Decode (AES-256-GCM + Argon2id, Ghost/Armor modes), Secure History, Security Center, Settings.

### Steganography (extension)
A dedicated **Steganography** hub (`/steganography`) offering two lighter-weight sibling workflows to the core encoder:

- **LSB on Text** (`/steganography/lsb-text`) — hides plain UTF-8 text directly in an image's pixel LSBs. No encryption: fastest option, but anyone who extracts the payload can read it immediately. Backed by `core/security/lsb_steganography_service.dart`.
- **LSB with DES** (`/steganography/lsb-des`) — encrypts the message with a from-scratch, textbook-standard DES-CBC implementation (`core/security/des_crypto_service.dart`) before embedding it via the same plain-LSB engine (ciphertext bridged through base64, since the LSB frame carries text). **DES is a legacy 56-bit cipher included for interoperability/education, not real secrecy** — the UI says so explicitly, and the module is intentionally kept separate from the core AES-256-GCM encoder.

Both screens use a 2-tab layout (Encode / Decode) rather than the core module's numbered wizard, since neither needs the capacity/health scoring or Ghost/Armor mode selection.

### Password Generator (extension)
`/password-generator` — fully offline password generation via `dart:math`'s `Random.secure()` CSPRNG (`core/security/password_generator_service.dart`), with a length slider, per-class toggles (upper/lower/numbers/symbols), similar/ambiguous-character exclusion, and a transparent entropy-based strength meter (`core/security/password_strength_analyzer.dart`, Weak → Very Strong). Defaults are read from Settings. **Generated passwords are never written to History** — only a "password generated" event with length metadata is recorded.

### Caesar Cipher (extension)
`/caesar-cipher` — the classic educational substitution cipher (`core/security/caesar_cipher_service.dart`), with a shift slider (0–25), encrypt/decrypt sections, a character-shift visualization, and an explanatory card. Zero cryptographic strength by design; framed purely as a learning tool.

### Cross-cutting updates
- **Home dashboard**: added a horizontally-scrolling "More Tools" row (Steganography / Password Generator / Caesar Cipher) alongside the existing Encode/Decode cards — nothing removed.
- **Secure History**: `HistoryEntry` gained a backward-compatible `toolId` field (defaults to `'safetext'` for pre-existing records) so the same list/filter UI can render entries from every module with the right icon/label, plus a new `Tools` filter chip. As before, only metadata is ever stored — never passwords, messages, or keys.
- **Settings**: added "Password Generator Defaults" (length + character-class prefs, wired live into the generator) and "Steganography Settings" (default Ghost/Armor mode — now seeds the core Encode wizard's initial mode — and a compression warning, which the Encode Result screen's Share button now honors before handing off to `share_plus`).

## Security design

| Layer | Technology |
|---|---|
| Message confidentiality | AES-256-GCM (authenticated encryption) — core encoder only |
| Key derivation | Argon2id (OWASP-recommended params: 19 MB, 2 iterations) |
| Randomness | CSPRNG (`dart:math` `Random.secure()`) for all salts/nonces/seeds |
| Concealment | LSB steganography across RGB channels of a lossless PNG |
| Integrity | GCM auth tag + a secondary CRC32 payload checksum |
| Legacy cipher (Steganography > LSB with DES) | DES-CBC, PKCS7 padding — **56-bit, not secure by modern standards**, included for interoperability/education only |
| Educational cipher (Caesar Cipher module) | Caesar shift — **zero cryptographic strength**, learning tool only |

Two embedding **Security Modes**:
- **Ghost Mode** — bits are scattered pseudo-randomly (seeded, CSPRNG-generated)
  across the image for maximum stealth and minimal statistical footprint.
- **Armor Mode** — bits are written sequentially with 3x repetition
  (majority-vote decode) to tolerate minor recompression.

History storage is **metadata-only** — SafeText never persists a decrypted
message, a passphrase, or key material to disk.

## Getting started

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel).
2. `flutter pub get`
3. Copy `android/local.properties.example` to `android/local.properties` and
   fill in your `sdk.dir` / `flutter.sdk` paths (Android Studio does this for
   you automatically the first time you open the project).
4. `flutter run` (or `flutter build apk --release`).

> The `release` build type currently signs with the debug keystore so local
> builds work out of the box — replace `signingConfigs.release` in
> `android/app/build.gradle` with your own upload key before publishing.

## Architecture

Clean Architecture, feature-first:

```
lib/
├── app/            # App shell: MaterialApp, GoRouter, theme, top-level providers
├── core/           # Cross-cutting: constants, exceptions, crypto/stego engines, utils
│   └── security/   # CryptoService, StegoService, PayloadCodec, LsbSteganographyService,
│                    # DesCryptoService, CaesarCipherService, PasswordGeneratorService,
│                    # PasswordStrengthAnalyzer
├── data/           # Hive models (hand-written TypeAdapters), repositories, datasources
├── features/       # One folder per screen/flow:
│   ├── splash, onboarding, home, encode, decode, history, settings,
│   │   security_center                          (original release)
│   ├── steganography/                             (extension)
│   │   ├── steganography_home_screen.dart
│   │   ├── lsb_text/       (screen + provider — plain LSB, no encryption)
│   │   └── lsb_des/        (screen + provider — DES-CBC + LSB)
│   ├── password_generator/                        (extension)
│   └── caesar_cipher/                              (extension)
└── shared/         # Reusable widgets, dialogs, components
```

- **State management**: Riverpod (`StateNotifierProvider` per flow — see
  `features/encode/providers/encode_provider.dart` and
  `features/decode/providers/decode_provider.dart` for the multi-step wizard
  state machines).
- **Routing**: `go_router`, with a `ShellRoute` hosting the persistent
  bottom-navigation bar (Home / History / Security / Settings).
- **Local storage**: Hive, with hand-written `TypeAdapter`s (no
  `build_runner`/codegen step) for `HistoryEntry` and `SecuritySettings`.
- **Theming**: Material 3, tokens generated 1:1 from `DESIGN.md`, with full
  dark (primary) and light (companion) `ThemeData`s.

## Routes

| Path | Screen |
|---|---|
| `/` | Splash |
| `/onboarding` | Onboarding |
| `/home`, `/history`, `/security`, `/settings` | Bottom-nav shell tabs |
| `/encode`, `/encode/result` | Core Encode wizard + result |
| `/decode`, `/decode/result` | Core Decode + message viewer |
| `/steganography` | Steganography hub (choose LSB on Text / LSB with DES) |
| `/steganography/lsb-text` | LSB on Text (Encode/Decode tabs) |
| `/steganography/lsb-des` | LSB with DES (Encrypt+Embed / Decode+Decrypt tabs) |
| `/password-generator` | Password Generator |
| `/caesar-cipher` | Caesar Cipher |

## Native Android security surface

`MainActivity.kt` exposes a small platform channel
(`com.safetext.app/security`) used by the Settings screen to:
- Toggle `FLAG_SECURE` at runtime (blocks screenshots + hides the app from
  the recent-apps switcher preview) — wired to the **Block Screenshots**
  setting.
- Run a best-effort root heuristic for the Security Center (UX signal only,
  not a hard trust boundary).

## Known simplifications / next steps

- **Font**: `AppTextStyles`/`AppTheme` reference the `Inter` font family by
  name, matching `DESIGN.md`, but no font files are bundled in this
  deliverable (kept dependency-free / offline-buildable). Flutter will
  gracefully fall back to the platform default font until you add the
  actual `Inter-*.ttf` files under `assets/fonts/` and register them in the
  `flutter.fonts:` section of `pubspec.yaml`, e.g.:
  ```yaml
  flutter:
    fonts:
      - family: Inter
        fonts:
          - asset: assets/fonts/Inter-Regular.ttf
          - asset: assets/fonts/Inter-Medium.ttf
            weight: 500
          - asset: assets/fonts/Inter-SemiBold.ttf
            weight: 600
          - asset: assets/fonts/Inter-Bold.ttf
            weight: 700
  ```
- Tamper/APK-integrity verification (`Integrity Verification` in the
  original spec) is stubbed — wiring up Play Integrity API or a signature
  hash check is a natural v1.1 addition.
- App icon is a placeholder generated shield mark; swap in final brand
  assets before release.
- No automated test suite is included yet; `core/security` (crypto_service,
  stego_service, payload_codec) is the highest-value target for unit tests
  given it has zero Flutter/widget dependencies.

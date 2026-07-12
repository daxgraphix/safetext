# SafeText

**Enterprise-Grade Offline Privacy & Steganography Platform**
_Private Messages Hidden in Plain Sight_

SafeText is a high-security vault designed to hide encrypted data within ordinary images and manage sensitive QR codes without ever touching the cloud. It features a hardware-anchored security model, mandatory biometric/PIN protection, and "local-first" data sovereignty.

## 🛡️ Security Architecture

SafeText employs a multi-layered "Defense-in-Depth" strategy:

1.  **Hardware Binding**: The application generates a unique `device_binding_id` stored in the device's Secure Enclave (Android Keystore / iOS Keychain). Data cannot be decrypted if moved to another device.
2.  **Hardware-Anchored Encryption**: All local databases (Hive) are encrypted using **AES-256**. The encryption keys are stored in the device's TEE (Trusted Execution Environment) via `DeviceSecurityService`.
3.  **Mandatory Security Gate**: Access is guarded by a unified `SecurityGateDialog`. 
    *   **Cold Start**: Authentication is required immediately after the Splash screen.
    *   **App Resumption**: The app automatically locks when moved to the background, requiring PIN or Biometrics (Fingerprint/FaceID) to resume.
4.  **Screenshot Blocking**: Uses native `FLAG_SECURE` to prevent screen captures and hide app content from the "Recent Apps" switcher.
5.  **No-Cloud Policy**: 100% offline. No analytics, no accounts, and no network permissions.

## 🚀 Core Features

### 1. Steganography (The "Ghost" Engine)
Hides encrypted payloads inside image pixels using Least Significant Bit (LSB) embedding.
- **Ghost Mode**: Pseudo-random bit scattering for maximum stealth and statistical invisibility.
- **Armor Mode**: Sequential embedding with 3x redundancy to survive minor image compression.

### 2. QR Vault
A secure environment for managing sensitive QR codes (2FA seeds, crypto keys).
- **Secure Generation**: Create QR codes from sensitive text with optional AES-256-GCM encryption.
- **Encrypted Scanner**: Scan and decrypt secure QR codes directly within the vault.
- **Blur Protection**: Vault content is obscured until authenticated.

### 3. Dcode & Multi-Cipher
Manual encryption/decryption tools supporting:
- **AES-256-GCM**: Industry-standard authenticated encryption.
- **DES-CBC**: Legacy support for interoperability.
- **Caesar Cipher**: Educational tool for basic substitution.

### 4. Password Generator
CSPRNG-based offline password generation with an entropy-based strength meter. Defaults are configurable in Settings.

### 5. Secure History
An audit log of all cryptographic operations.
- **Metadata Only**: Stores operation types and timestamps; never stores your messages, keys, or passwords.
- **Auto-Expiry**: Optional automatic wiping of old logs after a set period.

## 📱 Screen Flows

- **Splash**: Performs integrity checks and hardware-key retrieval.
- **Onboarding**: Mandatory 2-step PIN setup with confirmation.
- **App Shell**: A persistent bottom-nav container hosting:
    - **Home**: Quick access to Encode, Decode, and Tools.
    - **History**: Searchable audit log of past actions.
    - **Security Center**: Privacy audits and "Root/Jailbreak" detection.
    - **Settings**: Global toggles for Screenshot Blocking, Auto-Clear Clipboard, and Dark Mode.
- **Encode/Decode Wizards**: Multi-step flows for embedding/extracting data.

## 🛠️ Technical Stack

- **Framework**: Flutter (Clean Architecture / Feature-first)
- **State Management**: Riverpod
- **Database**: Hive (AES Encrypted)
- **Native**: Kotlin (MethodChannels for `FLAG_SECURE` and Root Detection)
- **Crypto**: `cryptography` package (AES-256-GCM, Argon2id)

## 🏁 Getting Started

1.  **Environment**: Ensure Flutter (Stable) is installed.
2.  **Dependencies**: Run `flutter pub get`.
3.  **Native Setup**: 
    - Android: Update `local.properties` with your SDK paths.
    - iOS: Run `pod install` in the `ios` directory.
4.  **Run**: `flutter run`

---
*SafeText is designed for users who require total digital sovereignty. Your data is your own.*

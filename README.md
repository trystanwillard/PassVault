# PassVault

<img src="PassVault/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="120" alt="PassVault app icon">

An iOS password manager built with SwiftUI, using Face ID/Touch ID authentication
and Keychain-backed secure storage.

## Features

- Biometric (Face ID/Touch ID) or device passcode authentication, with automatic
  idle-timeout locking and re-lock on backgrounding
- Passwords stored in iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`),
  excluded from iCloud sync and encrypted backups
- Built-in strong password generator
- Encrypted backup export/import (AES-GCM)

## Known limitations / next steps

- Backup key derivation currently uses HKDF; should be replaced with a proper
  password-based KDF (PBKDF2/scrypt/Argon2) for resistance to offline brute-force
  attacks on exported backup files
- Password generation should be moved to explicit `SecRandomCopyBytes` calls for
  guaranteed CSPRNG behavior, for consistency with the salt generation already
  used in backup encryption
- Copied passwords remain on the system pasteboard indefinitely; should set an
  expiration (auto-clear after ~30-60 seconds)
- Entry metadata (site, username) is currently stored via `UserDefaults`; a more
  hardened design would keep this in Keychain as well

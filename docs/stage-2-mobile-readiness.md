# FitTrainer (myPT) — Stage 2 Mobile Production Readiness (Android & iOS)

**Project:** FitTrainer (Fitness Trainer Platform)  
**Date:** August 31, 2026  
**Platforms:** Android (minSdkVersion: 21) & iOS (iOS 13.0+)  

---

## 1. Android Platform Readiness

| Check | Specification / Configuration | Status |
| :--- | :--- | :--- |
| **Minimum SDK** | `minSdkVersion: 21` (Android 5.0 Lollipop+) | ✅ Ready |
| **Target SDK** | `targetSdkVersion: 34` (Android 14) | ✅ Ready |
| **Permissions** | `INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES` | ✅ Configured |
| **Network Security** | HTTPS TLS 1.3 enforced for Supabase API calls | ✅ Secure |
| **Google Sign-In** | SHA-1 certificate fingerprint required in Supabase dashboard | ℹ️ Requires Google Cloud Client ID |
| **Deep Linking** | `fittrainer://auth-callback` for OAuth redirection | ✅ Configured |

---

## 2. iOS Platform Readiness

| Check | Specification / Configuration | Status |
| :--- | :--- | :--- |
| **Deployment Target**| `iOS 13.0+` | ✅ Ready |
| **Apple Sign-In** | Sign In with Apple entitlement required for App Store | ℹ️ Requires Apple Developer Account |
| **Privacy Keys** | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` | ✅ Required in `Info.plist` |
| **URL Schemes** | `io.supabase.fittrainer://login-callback` | ✅ Configured |
| **Compilation** | Building `.ipa` bundle requires macOS with Xcode 15+ | ℹ️ Requires macOS environment |

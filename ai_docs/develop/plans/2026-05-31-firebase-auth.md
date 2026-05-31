# Plan: Firebase Authentication (Email + Google)

**Created:** 2026-05-31  
**Orchestration:** `orch-2026-05-31-firebase-auth`  
**Status:** 🟢 Ready  
**Goal:** Production-ready Firebase Auth with email/password and Google sign-in, gated app entry, and profile integration.

## Project Context

| Item | Current state |
|------|----------------|
| App | `SummerDrift` — `lib/main.dart` → `HomeShell` (4 tabs) |
| Firebase | `firebase_core` initialized via `lib/core/firebase/firebase_initializer.dart` |
| Config | `lib/firebase_options.dart` + `android/app/google-services.json` (project `cursor-hackat`) |
| Auth packages | **Not present** — need `firebase_auth`, `google_sign_in`, state management |
| Google OAuth | `google-services.json` has **empty `oauth_client`** — Console + SHA setup required |
| Profile tab | Placeholder at `lib/screens/profile_screen.dart` |
| State mgmt | None — introduce `provider` for auth stream (minimal, fits scope) |

## Tasks Overview

| ID | Task | Priority | Complexity | Dependencies |
|----|------|----------|------------|--------------|
| AUTH-001 | Firebase Console & platform prerequisites | Critical | Moderate | — |
| AUTH-002 | Dependencies & project structure | High | Simple | AUTH-001 |
| AUTH-003 | Auth repository & error mapping | High | Moderate | AUTH-002 |
| AUTH-004 | Auth state provider & root `AuthGate` | High | Moderate | AUTH-003 |
| AUTH-005 | Email/password sign-in & sign-up UI | High | Moderate | AUTH-004 |
| AUTH-006 | Google Sign-In integration | High | Complex | AUTH-004, AUTH-001 |
| AUTH-007 | Password reset & account recovery UX | Medium | Simple | AUTH-005 |
| AUTH-008 | Profile screen & sign-out | Medium | Simple | AUTH-004 |
| AUTH-009 | Tests & verification | High | Moderate | AUTH-005, AUTH-006, AUTH-008 |

**Total tasks:** 9

## Dependencies Graph

```
AUTH-001 ──┬──► AUTH-002 ──► AUTH-003 ──► AUTH-004 ──┬──► AUTH-005 ──► AUTH-007
           │                                          ├──► AUTH-006
           └──────────────────────────────────────────├──► AUTH-008
                                                        └──► AUTH-009 (after 005, 006, 008)
```

## Progress

- ⏳ AUTH-001: Firebase Console & platform prerequisites (Pending)
- ⏳ AUTH-002: Dependencies & project structure (Pending)
- ⏳ AUTH-003: Auth repository & error mapping (Pending)
- ⏳ AUTH-004: Auth state provider & root AuthGate (Pending)
- ⏳ AUTH-005: Email/password sign-in & sign-up UI (Pending)
- ⏳ AUTH-006: Google Sign-In integration (Pending)
- ⏳ AUTH-007: Password reset & account recovery UX (Pending)
- ⏳ AUTH-008: Profile screen & sign-out (Pending)
- ⏳ AUTH-009: Tests & verification (Pending)

---

## Task Details

### AUTH-001: Firebase Console & platform prerequisites

**Priority:** Critical | **Complexity:** Moderate | **Dependencies:** None

**Scope:**
- Firebase Console (`cursor-hackat`): enable **Email/Password** and **Google** sign-in providers.
- Android: add debug (and release) **SHA-1/SHA-256** fingerprints; re-download `google-services.json` so `oauth_client` is populated.
- iOS (if targeting): ensure `GoogleService-Info.plist`, URL schemes, and bundle ID `com.example.summerActivity` align with Firebase app.
- Document manual steps in plan notes or `ai_docs/develop/features/` if Console access is user-only.

**Files affected:**
- `android/app/google-services.json` (regenerated)
- `ios/Runner/GoogleService-Info.plist` (if iOS in scope)
- Optional: `firebase.json` / `flutterfire configure` refresh

**Acceptance criteria:**
- [ ] Email/Password and Google providers enabled in Firebase Authentication.
- [ ] `google-services.json` contains non-empty `oauth_client` entries for Android.
- [ ] `flutter run` on Android initializes Firebase without auth-related native errors.

**Suggested agent:** worker (with user handoff for Console) + documenter for setup checklist

---

### AUTH-002: Dependencies & project structure

**Priority:** High | **Complexity:** Simple | **Dependencies:** AUTH-001

**Scope:**
- Add to `pubspec.yaml`: `firebase_auth`, `google_sign_in`, `provider`.
- Create folder layout under `lib/`:
  - `lib/features/auth/domain/` — repository interface, `AppUser` model
  - `lib/features/auth/data/` — `FirebaseAuthRepository`
  - `lib/features/auth/presentation/` — screens, widgets, providers
  - `lib/features/auth/auth.dart` — barrel export (optional)

**Files affected:**
- `pubspec.yaml`, `pubspec.lock`
- New `lib/features/auth/**`

**Acceptance criteria:**
- [ ] Packages resolve with `flutter pub get`.
- [ ] No analyzer errors from new imports.
- [ ] Structure matches layered separation (data / domain / presentation).

**Suggested agent:** worker

---

### AUTH-003: Auth repository & error mapping

**Priority:** High | **Complexity:** Moderate | **Dependencies:** AUTH-002

**Scope:**
- `AuthRepository` interface: `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signOut`, `sendPasswordResetEmail`, `authStateChanges`, `currentUser`.
- `FirebaseAuthRepository` implementing Firebase Auth + `GoogleSignIn`.
- Map `FirebaseAuthException` codes to user-facing messages (Russian copy to match existing UI: «маршрут», «профиль», etc.).
- Do not leak internal exception strings in UI.

**Files affected:**
- `lib/features/auth/domain/auth_repository.dart`
- `lib/features/auth/domain/app_user.dart`
- `lib/features/auth/domain/auth_failure.dart`
- `lib/features/auth/data/firebase_auth_repository.dart`

**Acceptance criteria:**
- [ ] Repository unit-testable via interface (mock Firebase in tests).
- [ ] All auth operations return `Result`/`Either`-style errors or throw mapped `AuthFailure` — pick one pattern and use consistently.
- [ ] `AppUser` exposes `uid`, `email`, `displayName`, `photoUrl`, `emailVerified`.

**Suggested agent:** worker → test-writer (repository tests)

---

### AUTH-004: Auth state provider & root AuthGate

**Priority:** High | **Complexity:** Moderate | **Dependencies:** AUTH-003

**Scope:**
- `ChangeNotifier` or `Provider` wrapping `authStateChanges()` stream.
- `AuthGate` widget: shows splash/loading while resolving initial auth; routes to `HomeShell` if signed in, else auth flow.
- Wire in `main.dart`: `MultiProvider` + `AuthGate` as `home` (replace direct `HomeShell`).
- Preserve existing `SummerDriftApp` theme.

**Files affected:**
- `lib/main.dart`
- `lib/features/auth/presentation/auth_gate.dart`
- `lib/features/auth/presentation/auth_controller.dart` (or `auth_notifier.dart`)

**Acceptance criteria:**
- [ ] Cold start: signed-out user never sees `HomeShell` until authenticated.
- [ ] Signed-in user lands on `HomeShell` without flashing login on slow networks (loading state).
- [ ] Sign-out from anywhere updates gate and returns to auth screens.

**Suggested agent:** worker

---

### AUTH-005: Email/password sign-in & sign-up UI

**Priority:** High | **Complexity:** Moderate | **Dependencies:** AUTH-004

**Scope:**
- `AuthScreen` with tabs or toggle: Sign In / Sign Up.
- Validated fields: email format, password min length (≥8), confirm password on sign-up.
- Loading states, disabled submit while in-flight, inline error from `AuthFailure`.
- Styling: `AppColors`, `AppTextStyles`, Material 3 — consistent with `RouletteScreen` / `ProfileScreen`.

**Files affected:**
- `lib/features/auth/presentation/auth_screen.dart`
- `lib/features/auth/presentation/widgets/` (form fields, primary button)

**Acceptance criteria:**
- [ ] New user can register with email/password and reach `HomeShell`.
- [ ] Existing user can sign in with correct credentials.
- [ ] Wrong password / email in use / weak password show localized, actionable errors.
- [ ] Forms prevent double-submit.

**Suggested agent:** worker → reviewer (UI consistency)

---

### AUTH-006: Google Sign-In integration

**Priority:** High | **Complexity:** Complex | **Dependencies:** AUTH-004, AUTH-001

**Scope:**
- `signInWithGoogle()` in repository: `GoogleSignIn` → credential → `FirebaseAuth.signInWithCredential`.
- “Continue with Google” on `AuthScreen`.
- Handle `account-exists-with-different-credential` and user cancellation gracefully.
- Platform: Android uses updated `google-services.json`; iOS adds `CFBundleURLTypes` if building for iOS.

**Files affected:**
- `lib/features/auth/data/firebase_auth_repository.dart`
- `lib/features/auth/presentation/auth_screen.dart`
- `android/app/src/main/AndroidManifest.xml` (if needed)
- `ios/Runner/Info.plist` (if iOS in scope)

**Acceptance criteria:**
- [ ] Google sign-in completes on Android debug build with configured SHA.
- [ ] Cancelled Google flow does not crash; user stays on auth screen.
- [ ] First-time Google user lands on `HomeShell` with profile photo/name when available.

**Suggested agent:** worker (blocked until AUTH-001 oauth clients exist)

---

### AUTH-007: Password reset & account recovery UX

**Priority:** Medium | **Complexity:** Simple | **Dependencies:** AUTH-005

**Scope:**
- “Forgot password?” → dialog or bottom sheet → email field → `sendPasswordResetEmail`.
- Success/error snackbars in Russian.
- Optional: banner on profile if `!emailVerified` with “Resend verification” (`sendEmailVerification`) — recommended for production.

**Files affected:**
- `lib/features/auth/presentation/forgot_password_dialog.dart` (or inline)
- Repository method already from AUTH-003

**Acceptance criteria:**
- [ ] Valid registered email receives reset link (Firebase sends email).
- [ ] Unknown email shows safe message (avoid email enumeration if policy requires; Firebase default is acceptable for MVP).
- [ ] UI returns to sign-in after success.

**Suggested agent:** worker

---

### AUTH-008: Profile screen & sign-out

**Priority:** Medium | **Complexity:** Simple | **Dependencies:** AUTH-004

**Scope:**
- Replace `ProfileScreen` placeholder with signed-in user info (avatar, display name, email).
- Sign-out button → `AuthRepository.signOut()` → `AuthGate` shows auth flow.
- Guest-only features: none — profile requires auth.

**Files affected:**
- `lib/screens/profile_screen.dart` (or move to `lib/features/auth/presentation/profile_screen.dart` and update `home_shell.dart` import)

**Acceptance criteria:**
- [ ] Profile shows current `AppUser` data.
- [ ] Sign out clears session and navigates to auth UI.
- [ ] Tab state resets appropriately after sign-out (no stale PII on other tabs).

**Suggested agent:** worker

---

### AUTH-009: Tests & verification

**Priority:** High | **Complexity:** Moderate | **Dependencies:** AUTH-005, AUTH-006, AUTH-008

**Scope:**
- Unit tests: `AuthFailure` mapping, repository with `FirebaseAuth`/`GoogleSignIn` mocks (`firebase_auth_mocks` or manual fakes).
- Widget tests: `AuthGate` (loading / authed / unauthed), auth form validation.
- Manual test plan: email sign-up, sign-in, wrong password, Google, sign-out, password reset.

**Files affected:**
- `test/features/auth/**`
- Update `test/widget_test.dart` if it assumes counter/home without auth

**Acceptance criteria:**
- [ ] `flutter test` passes.
- [ ] `flutter analyze` clean on touched files.
- [ ] Manual checklist documented in completion report.

**Suggested agent:** test-writer → test-runner → documenter (report)

---

## Architecture Decisions

1. **Firebase Auth as source of truth** — No custom JWT/session storage; use `FirebaseAuth.instance.authStateChanges()` for session lifecycle.

2. **Layered feature module** — `lib/features/auth/` with domain (interfaces, models), data (Firebase impl), presentation (UI + Provider). Keeps `lib/screens/` for app shells; auth is a vertical feature.

3. **Provider for auth state** — Lightweight `provider` + `ChangeNotifier` or `StreamProvider` on `authStateChanges`. Avoid introducing Riverpod/Bloc unless project standard changes later.

4. **Auth gate at root** — Single `AuthGate` in `MaterialApp.home` rather than per-tab checks; all routes behind authentication by default.

5. **Repository abstraction** — `AuthRepository` interface enables testing and future swap (e.g. mock auth in integration tests).

6. **User-facing copy in Russian** — Match existing nav labels («профиль», etc.) for errors and buttons.

7. **Google Sign-In depends on Console** — Empty `oauth_client` in current `google-services.json` is a hard blocker for AUTH-006; AUTH-001 must complete first.

8. **Email verification (soft production)** — Send verification on sign-up; show non-blocking banner in profile until verified; do not block `HomeShell` unless product requires it.

9. **Security** — No passwords in logs; use Firebase rules for backend data (out of scope unless Firestore added later); min password length 8; rely on Firebase rate limiting for auth endpoints.

10. **iOS bundle ID note** — `firebase_options.dart` uses `com.example.summerActivity` for iOS; align with Xcode project before shipping iOS Google Sign-In.

## Execution Strategy

| Phase | Tasks | Parallel? |
|-------|-------|-----------|
| 1 — Prerequisites | AUTH-001 | User + worker |
| 2 — Foundation | AUTH-002 → AUTH-003 → AUTH-004 | Sequential |
| 3 — Features | AUTH-005, AUTH-006, AUTH-008 | 005/008 after 004; 006 after 001+004 |
| 4 — Polish | AUTH-007 | After AUTH-005 |
| 5 — Quality | AUTH-009 | Last |

**Subagents:** worker (implementation), test-writer + test-runner (AUTH-009), reviewer (after AUTH-005/006), security-auditor (AUTH-003, AUTH-006), documenter (completion report).

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Empty Android OAuth clients | AUTH-001: SHA fingerprints + regenerate config |
| iOS Google Sign-In misconfiguration | Defer iOS testing until plist/URL schemes verified |
| No state management precedent | Single `AuthController` + documented pattern |
| `widget_test` assumes old home | Update in AUTH-009 |
| Email enumeration on reset | Use Firebase default messaging; document product choice |

## Out of Scope (follow-up issues)

- Firestore user profile documents / display name edit
- Apple Sign-In, phone auth, anonymous auth
- Biometric re-auth
- Deep linking from password-reset email into app
- Production release signing (release SHA for Google)

---

**Execute:** `/orchestrate execute orch-2026-05-31-firebase-auth`

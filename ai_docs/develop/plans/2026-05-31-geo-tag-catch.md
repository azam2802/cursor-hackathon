# Plan: Geo-Tag Catch (AR-Тайники)

**Created:** 2026-05-31  
**Orchestration:** `orch-2026-05-31-17-55-geo-tag`  
**Status:** ✅ Completed  
**Goal:** Build the "Geo-Tag Catch" feature on `lib/screens/geo_tag_screen.dart` — a park/forest game where one player hides a virtual cache (photo or text) at real GPS coordinates and others must physically walk there, then use an AR camera view to "open" it.

## Concept

> «Игра для парков и лесов. Один человек оставляет виртуальный тайник (фото или сообщение) на конкретных GPS-координатах, остальные должны физически дойти до этого места с телефоном, чтобы тайник «открылся».»

A game for parks and forests. One person leaves a virtual cache (a photo or message) at specific GPS coordinates; others must physically walk to that location with their phone for the cache to "open".

## Project Context

| Item | Current state |
|------|----------------|
| App | `SummerDrift` — `lib/main.dart` → `AuthWrapper` → `HomeShell` (4 tabs), tab index 2 = `GeoTagScreen` («тайники») |
| Target screen | `lib/screens/geo_tag_screen.dart` — **placeholder mockup, fully replaceable** |
| Design system | `lib/theme/app_colors.dart` (`AppColors.mint`, `geoBg`…), `lib/theme/app_text_styles.dart` (`display`/`body`), Material 3, Russian labels |
| Firebase | `firebase_core` + `firebase_auth` initialized via `lib/core/firebase/firebase_initializer.dart`; project `cursor-hackat` |
| Auth | `lib/core/auth/auth_service.dart`; current user via `FirebaseAuth.instance.currentUser` (owner of caches) |
| Service layout | Convention: services live under `lib/core/<domain>/`, screens under `lib/screens/` |
| State mgmt | Plain `StatefulWidget` + `StreamBuilder`/`setState` — **keep this**, no new state lib |
| Packages now | `firebase_core`, `firebase_auth`, `google_sign_in`, `google_fonts`, `cupertino_icons` |
| Missing for feature | GPS, permissions, camera, compass, Firestore, Storage, image capture |

## Key Technical Decision — AR Approach

Full geospatial ARCore anchoring (`ar_flutter_plugin`, ARCore Geospatial API) is heavy, Android/iOS-fragile, and largely unmaintained for current Flutter SDKs. It is **not** justified here.

**Recommended (pragmatic) AR = live camera preview + GPS proximity + compass-bearing overlay:**
- `camera` renders the live viewfinder.
- `geolocator` provides current position and distance/bearing to the cache.
- `flutter_compass` (magnetometer/heading) rotates a directional arrow + cache "pin" overlaid on the camera feed so the cache appears to "sit" in a direction in the real world.
- When the user is within the **open radius** (default **20 m**, configurable 15–25 m), the cache becomes openable in the AR view and reveals its photo/message.

This delivers the required "camera AR to find/open the cache" UX, works reliably on Android (primary), degrades gracefully, and avoids a fragile native AR dependency. ARCore anchoring is recorded as an out-of-scope follow-up.

## Tasks Overview

| ID | Task | Priority | Complexity | Dependencies |
|----|------|----------|------------|--------------|
| GEO-001 | Dependencies & platform permission config | Critical | Moderate | — |
| GEO-002 | Cache data model + Firestore/Storage repository | High | Moderate | GEO-001 |
| GEO-003 | Location/permission service + proximity logic | High | Moderate | GEO-001 |
| GEO-004 | Compass/sensor service + camera AR overlay view | High | Complex | GEO-001, GEO-003 |
| GEO-005 | Create-cache flow | High | Moderate | GEO-002, GEO-003 |
| GEO-006 | Find / nearby caches list + navigation flow | High | Moderate | GEO-002, GEO-003 |
| GEO-007 | AR proximity "open" interaction | High | Complex | GEO-004, GEO-006 |
| GEO-008 | `geo_tag_screen` integration + theming + security rules | Medium | Moderate | GEO-005, GEO-006, GEO-007 |
| GEO-009 | Tests & verification | Medium | Moderate | GEO-005, GEO-006, GEO-007, GEO-008 |

**Total tasks:** 9

## Dependencies Graph

```
GEO-001 ──┬──► GEO-002 ──┬─────────────► GEO-005 ──┐
          │              │                          │
          ├──► GEO-003 ──┼──► GEO-004 ──► GEO-007 ──┼──► GEO-008 ──► GEO-009
          │              │                          │
          │              └─────────────► GEO-006 ───┘
          └──────────────────────────────► (GEO-004 also needs GEO-003)
```

## Progress

- ✅ GEO-001: Dependencies & platform permission config (Completed)
- ✅ GEO-002: Cache data model + Firestore/Storage repository (Completed)
- ✅ GEO-003: Location/permission service + proximity logic (Completed)
- ✅ GEO-004: Compass/sensor service + camera AR overlay view (Completed)
- ✅ GEO-005: Create-cache flow (Completed)
- ✅ GEO-006: Find / nearby caches list + navigation flow (Completed)
- ✅ GEO-007: AR proximity "open" interaction (Completed)
- ✅ GEO-008: geo_tag_screen integration + theming + security rules (Completed)
- ✅ GEO-009: Tests & verification (Completed)

---

## Task Details

### GEO-001: Dependencies & platform permission config

**Priority:** Critical | **Complexity:** Moderate | **Dependencies:** None

**Scope:**
- Add to `pubspec.yaml` (resolve latest compatible with Dart `^3.11.5`):
  - `geolocator` — GPS position, distance & bearing helpers.
  - `permission_handler` — runtime permission requests/state.
  - `camera` — live camera preview for AR view.
  - `flutter_compass` — device heading for the AR direction overlay.
  - `cloud_firestore` — cache documents.
  - `firebase_storage` — cache photos.
  - `image_picker` — capture/select a photo when creating a cache.
- Android (`android/app/src/main/AndroidManifest.xml`): add `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA` (and `INTERNET` if missing). Confirm `minSdkVersion` meets `camera`/Firebase (≥ 21, bump if needed in `android/app/build.gradle`).
- iOS (`ios/Runner/Info.plist`): add `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` (Russian-friendly copy).
- Document any Firebase Console steps needed (enable Firestore in Native mode, enable Storage bucket) in plan notes.

**Files affected:**
- `pubspec.yaml`, `pubspec.lock`
- `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle` (if minSdk bump)
- `ios/Runner/Info.plist`

**Acceptance criteria:**
- [ ] `flutter pub get` resolves all new packages with no version conflicts.
- [ ] `flutter analyze` clean (no unresolved imports).
- [ ] Android manifest declares location + camera permissions; iOS Info.plist has all 3 usage strings.
- [ ] App still builds and launches on Android.
- [ ] Firestore & Storage confirmed enabled in the `cursor-hackat` Firebase project (noted if user must do it).

**Suggested agent:** worker (+ user handoff for Firebase Console) → documenter (setup checklist)

---

### GEO-002: Cache data model + Firestore/Storage repository

**Priority:** High | **Complexity:** Moderate | **Dependencies:** GEO-001

**Scope:**
- Create `GeoCache` model: `id`, `ownerId`, `ownerName`, `lat`, `lng`, `title`, `message`, `photoUrl` (nullable), `createdAt`, `openedBy: List<String>`.
- `fromFirestore` / `toMap` serialization (use `GeoPoint` or raw lat/lng; store `createdAt` as `Timestamp`).
- `CacheRepository` under `lib/core/geo/`:
  - `createCache(...)` → uploads optional photo to Storage (`caches/{uid}/{cacheId}.jpg`), writes Firestore doc in collection `caches`.
  - `nearbyCaches(...)` / `watchCaches()` → stream of caches (MVP: stream all, filter by distance client-side; document geohash/bbox optimization as follow-up).
  - `markOpened(cacheId, uid)` → `arrayUnion` on `openedBy`.
  - `deleteCache(cacheId)` (owner only) — optional.
- Keep repository UI-agnostic and testable (inject `FirebaseFirestore`/`FirebaseStorage`).

**Files affected:**
- `lib/core/geo/models/geo_cache.dart`
- `lib/core/geo/cache_repository.dart`

**Acceptance criteria:**
- [ ] `GeoCache` round-trips through `toMap`/`fromFirestore` without data loss.
- [ ] `createCache` writes a doc and (when a photo is given) returns a working `photoUrl`.
- [ ] `watchCaches`/`nearbyCaches` emits caches as a stream usable by `StreamBuilder`.
- [ ] `markOpened` appends the uid without duplicates.
- [ ] Repository compiles with no analyzer errors and is unit-testable via injected instances.

**Suggested agent:** worker → test-writer (repository tests) → security-auditor (data access)

---

### GEO-003: Location/permission service + proximity logic

**Priority:** High | **Complexity:** Moderate | **Dependencies:** GEO-001

**Scope:**
- `LocationService` under `lib/core/geo/`:
  - Request & check location permission (`permission_handler` / `geolocator.checkPermission`), handle denied/permanently-denied/service-disabled with clear states.
  - `currentPosition()` and `positionStream()` (with `LocationSettings` accuracy `high`, distanceFilter ~2 m).
  - `distanceBetween(...)` and `bearingBetween(...)` helpers (wrap `Geolocator.distanceBetween`/`bearingBetween`).
  - `isWithinOpenRadius(distance)` using a single source-of-truth constant `kOpenRadiusMeters = 20`.
- Define proximity tiers for UI copy (e.g. «далеко» / «близко» / «можно открыть»).

**Files affected:**
- `lib/core/geo/location_service.dart`
- `lib/core/geo/geo_constants.dart` (open radius, accuracy thresholds)

**Acceptance criteria:**
- [ ] Permission flow returns a typed result; denied/permanently-denied surfaces an actionable message (with "open settings" path).
- [ ] `positionStream` emits updates as the device moves (verified via mock/manual).
- [ ] Distance & bearing helpers return correct values for known coordinate pairs (unit-tested).
- [ ] `isWithinOpenRadius` true at ≤ 20 m, false beyond — driven by `kOpenRadiusMeters`.

**Suggested agent:** worker → test-writer (distance/bearing tests)

---

### GEO-004: Compass/sensor service + camera AR overlay view

**Priority:** High | **Complexity:** Complex | **Dependencies:** GEO-001, GEO-003

**Scope:**
- `CompassService` wrapping `flutter_compass` heading stream (handle null/no-sensor devices gracefully).
- Reusable `ArCameraView` widget under `lib/screens/geo_tag/`:
  - Initialize `CameraController` (back camera), show live preview filling the viewport; dispose correctly on navigation away / app lifecycle.
  - Overlay layer combining: device heading (compass) + bearing-to-cache (GEO-003) → render a directional arrow and a floating cache "pin/bubble" that rotates toward the target as the phone turns.
  - Show live distance badge and a crosshair, reusing the existing mockup's visual language (`AppColors.mint`, bubble + triangle tail, crosshair) so it matches `geo_tag_screen.dart`.
  - Handle camera permission denied + camera-unavailable fallback (static gradient placeholder).
- This task delivers the AR view shell + sensor plumbing; the "open" gating/reveal is GEO-007.

**Files affected:**
- `lib/core/geo/compass_service.dart`
- `lib/screens/geo_tag/ar_camera_view.dart`
- `lib/screens/geo_tag/widgets/ar_overlay.dart` (arrow, pin bubble, crosshair, distance badge)

**Acceptance criteria:**
- [ ] Live camera preview renders on a physical Android device and disposes without leaks when leaving the screen.
- [ ] Direction arrow/pin rotates correctly as the phone rotates (combines heading + target bearing).
- [ ] Distance badge updates live from the position stream.
- [ ] Camera/sensor unavailable or permission-denied shows a styled fallback, never a crash.
- [ ] Visuals use `AppColors`/`AppTextStyles` and match existing design tokens.

**Suggested agent:** worker → reviewer (UI + lifecycle correctness)

---

### GEO-005: Create-cache flow («Спрятать тайник»)

**Priority:** High | **Complexity:** Moderate | **Dependencies:** GEO-002, GEO-003

**Scope:**
- `CreateCacheSheet`/screen: capture current GPS (GEO-003), show coordinates + accuracy, enforce a minimum accuracy before allowing save.
- Inputs: `title` (required), `message` (text) and/or photo (optional via `image_picker` — camera or gallery). At least one of message/photo required.
- On save: call `CacheRepository.createCache` (uploads photo, writes doc with `ownerId = currentUser.uid`); show progress + success/error in Russian; close and refresh list.
- Validation, loading state, double-submit prevention.

**Files affected:**
- `lib/screens/geo_tag/create_cache_sheet.dart`
- `lib/screens/geo_tag/widgets/` (form fields, photo picker tile)

**Acceptance criteria:**
- [ ] User can create a cache at their current location with a title + message and optional photo.
- [ ] New cache appears in Firestore with correct owner, coords, timestamp, and photo URL when provided.
- [ ] Saving is blocked without location fix or required fields; errors shown in Russian.
- [ ] No double-submit; UI returns to the list after success.

**Suggested agent:** worker → reviewer (UI consistency)

---

### GEO-006: Find / nearby caches list + navigation flow («Найти тайник»)

**Priority:** High | **Complexity:** Moderate | **Dependencies:** GEO-002, GEO-003

**Scope:**
- Nearby list view: `StreamBuilder` over `CacheRepository.watchCaches`, compute live distance from current position, sort ascending, format distance («38 м» / «1.2 км»).
- Each list item: title, owner, distance, opened/unopened state (reuse `_StepCard`-style visual), tap → cache detail / navigate state.
- "Navigate" state for a selected cache: large distance readout + compass bearing indicator (pre-AR), updating live; a clear CTA «Открыть в AR» that becomes enabled within the open radius (handing off to GEO-007).
- Empty state («Поблизости тайников нет») and loading/error states, all themed.

**Files affected:**
- `lib/screens/geo_tag/nearby_caches_view.dart`
- `lib/screens/geo_tag/widgets/cache_list_card.dart`

**Acceptance criteria:**
- [ ] Caches are listed sorted by real distance from the user, updating as they move.
- [ ] Distance formatting matches design (meters under 1 km, km above).
- [ ] Already-opened caches are visually distinguished from new ones.
- [ ] Empty/loading/error states render with `AppColors`/`AppTextStyles`.
- [ ] «Открыть в AR» CTA is disabled until within `kOpenRadiusMeters`.

**Suggested agent:** worker → reviewer

---

### GEO-007: AR proximity "open" interaction

**Priority:** High | **Complexity:** Complex | **Dependencies:** GEO-004, GEO-006

**Scope:**
- Wire the `ArCameraView` (GEO-004) to a selected target cache: feed bearing/distance to the overlay.
- Gating: while distance > open radius, overlay shows guidance («Подойдите ближе — 38 м») and the open action is locked; within radius, surface a glowing "tap to open" affordance on the cache pin.
- On open: call `CacheRepository.markOpened`, animate a reveal, and present the cache contents — photo (from `photoUrl`) and/or message — in a themed card/overlay.
- Owners viewing their own cache and re-opening previously opened caches handled gracefully.

**Files affected:**
- `lib/screens/geo_tag/ar_find_screen.dart` (hosts `ArCameraView` + open logic)
- `lib/screens/geo_tag/widgets/cache_reveal_card.dart`

**Acceptance criteria:**
- [ ] Beyond the open radius the cache cannot be opened; clear "get closer" guidance shows live distance.
- [ ] Within `kOpenRadiusMeters`, the user can tap to "open" in the camera view.
- [ ] Opening reveals the stored photo/message and records the user in `openedBy`.
- [ ] Re-opening an already-opened cache shows contents without duplicate writes.
- [ ] Reveal animation/contents themed with `AppColors`/`AppTextStyles`.

**Suggested agent:** worker → reviewer

---

### GEO-008: `geo_tag_screen` integration + theming polish + security rules

**Priority:** Medium | **Complexity:** Moderate | **Dependencies:** GEO-005, GEO-006, GEO-007

**Scope:**
- Replace the placeholder `GeoTagScreen` with a real screen wiring the two flows: a header/segmented toggle or FAB for «Спрятать» (GEO-005) and a default «Найти» list (GEO-006) → AR (GEO-007).
- Keep `GeoTagScreen` as the public widget used by `home_shell.dart` (no nav changes needed); manage role/sub-view state with `StatefulWidget` + `setState`.
- Handle no-permission and no-auth states at the screen level with friendly prompts.
- Visual polish pass: background `AppColors.geoBg`, mint accents, Righteous/Nunito text, consistent radii/badges; ensure SafeArea and bottom-nav spacing.
- Add/adjust **Firestore & Storage security rules**: only authenticated users read caches; only the owner writes/deletes their cache doc and photo; `openedBy` updatable by any authed user via `arrayUnion` only. Document rules in plan/report (and `firestore.rules`/`storage.rules` if present).

**Files affected:**
- `lib/screens/geo_tag_screen.dart` (full rewrite)
- `firestore.rules`, `storage.rules` (or documented snippet for Console)

**Acceptance criteria:**
- [ ] Tab 2 («тайники») opens the new feature; create and find/AR flows reachable from one screen.
- [ ] No regressions to `HomeShell` navigation or other tabs.
- [ ] Permission/auth-missing states show themed guidance, no crashes.
- [ ] Security rules restrict writes to owners and reads to authed users (documented & applied).
- [ ] UI matches SummerDrift design tokens; `flutter analyze` clean.

**Suggested agent:** worker → reviewer → security-auditor (rules)

---

### GEO-009: Tests & verification

**Priority:** Medium | **Complexity:** Moderate | **Dependencies:** GEO-005, GEO-006, GEO-007, GEO-008

**Scope:**
- Unit tests: `GeoCache` serialization, distance/bearing helpers, `isWithinOpenRadius`, distance formatting.
- Repository tests with `fake_cloud_firestore` (or injected fakes) for create/watch/markOpened.
- Widget tests: nearby list rendering & sorting, open-CTA gating by distance, create-form validation (mock services).
- Manual device checklist: permission prompts, create cache, walk-in proximity, AR open + reveal, opened-state persistence.
- `flutter analyze` clean on all touched files.

**Files affected:**
- `test/core/geo/**`, `test/screens/geo_tag/**`
- `pubspec.yaml` dev dep: `fake_cloud_firestore` (and `mocktail`/`plugin_platform_interface` mocks as needed)

**Acceptance criteria:**
- [ ] `flutter test` passes.
- [ ] `flutter analyze` reports no new issues.
- [ ] Manual proximity/AR checklist documented in the completion report.

**Suggested agent:** test-writer → test-runner → documenter

---

## Architecture Decisions

1. **Pragmatic camera-overlay AR, not ARCore anchoring** — `camera` + `geolocator` + `flutter_compass` overlay gives the required AR find/open UX with reliable Android support and no fragile native AR dependency. Full geospatial ARCore is an out-of-scope follow-up.
2. **Services in `lib/core/geo/`, UI in `lib/screens/geo_tag/`** — matches the existing `lib/core/<domain>/` + `lib/screens/` convention (as used by auth).
3. **Plain `StatefulWidget` + `StreamBuilder`/`setState`** — no new state-management library, consistent with the current app.
4. **Firestore + Storage** — `caches` collection for metadata, Storage for photos; client-side distance filtering for MVP, geohash/bbox queries noted as a scaling follow-up.
5. **Single open-radius source of truth** — `kOpenRadiusMeters = 20` (15–25 m acceptable) in `geo_constants.dart`, reused by list gating and AR open logic.
6. **Owner = `FirebaseAuth.instance.currentUser`** — caches always have an authenticated owner; reads require auth, writes restricted to owner; `openedBy` via `arrayUnion`.
7. **Graceful degradation** — missing camera/compass/permission/location never crash; each surfaces a themed fallback or actionable prompt.
8. **Russian UI copy** — all labels/errors in Russian to match («тайники», «Спрятать тайник», «Найти», «Подойдите ближе», «Открыть в AR»).

## Execution Strategy

| Phase | Tasks | Parallel? |
|-------|-------|-----------|
| 1 — Foundation | GEO-001 | First (blocks all) |
| 2 — Data & sensors | GEO-002, GEO-003 | Parallel after GEO-001 |
| 3 — Building blocks | GEO-004 (needs 003), GEO-005, GEO-006 | 005/006 parallel; 004 alongside |
| 4 — AR open | GEO-007 | After 004 + 006 |
| 5 — Integrate & polish | GEO-008 | After 005/006/007 |
| 6 — Quality | GEO-009 | Last |

**Subagents:** worker (implementation), test-writer + test-runner (GEO-002/003/009), reviewer (GEO-004–008 UI/lifecycle), security-auditor (GEO-002, GEO-008 rules), documenter (completion report + Firebase/permission setup checklist).

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| GPS drift in tree cover (parks/forests) | High-accuracy settings; 15–25 m open radius; show accuracy and require a reasonable fix before save/open |
| Compass jitter / no magnetometer | Smooth heading; null-safe fallback to distance-only navigation |
| Camera lifecycle leaks / black preview | Dispose on lifecycle + route change; styled fallback when unavailable |
| Reading all caches doesn't scale | MVP client-side filter; geohash/bbox query as follow-up issue |
| Firestore/Storage not enabled in Console | GEO-001 verifies/enables; document manual step |
| Photo upload cost/size | Compress via `image_picker` quality/maxWidth before upload |
| Spoofed GPS lets remote "open" | Accept for MVP (game, not security-critical); note in issues |

## Out of Scope (follow-up issues)

- True ARCore/ARKit geospatial anchoring of caches in 3D space.
- Geohash/bounding-box server-side proximity queries & pagination.
- Map view of caches, cache categories, expiry, comments/reactions.
- Leaderboards / gamification of finds.
- Anti-GPS-spoofing measures.
- Offline caching of cache metadata.

---

**Execute:** `/orchestrate execute orch-2026-05-31-17-55-geo-tag`

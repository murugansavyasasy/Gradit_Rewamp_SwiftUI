# Gradit – Project Structure

SwiftUI + MVVM, feature-based folders, `@Observable` view models, async/await networking.
The Xcode project uses synchronized folders, so any file added under `Gradit/` is picked up automatically.

```
Gradit/
├── App/                    Entry point, root view, navigation, dependency container
│   ├── GraditApp.swift
│   ├── RootView.swift      TabView + one NavigationStack per tab
│   ├── AppRouter.swift     AppTab, Route enum, navigation paths
│   └── AppDependencies.swift
├── Core/
│   ├── Config/             AppConfig (base URLs, version, environment)
│   ├── Networking/         APIClient, Endpoint, HTTPMethod, APIError
│   ├── Extensions/         View+, String+
│   └── Utilities/          AppLogger (OSLog), LoadState
├── DesignSystem/
│   ├── Theme.swift         Colors, spacing, radius, typography tokens
│   └── Components/         PrimaryButton, ErrorStateView, ...
├── Models/                 Codable domain models (User)
├── Services/               API-facing services + protocol + mock
├── Features/
│   ├── Home/               HomeView + HomeViewModel
│   └── Settings/           SettingsView
└── Resources/              Assets.xcassets (strings catalogs, fonts go here)

GraditTests/Features/       View model unit tests (Swift Testing)
```

## Adding a feature
1. Create `Features/<Name>/` with `<Name>View.swift` and `<Name>ViewModel.swift`.
2. Put API calls in a `Services/<Name>Service.swift` behind a protocol (with a mock).
3. Register the service in `AppDependencies`.
4. Add pushable screens as cases on `Route` in `AppRouter.swift`.

## Notes
- Default actor isolation is `MainActor` (project setting), so models/networking value types are marked `nonisolated`.
- Change the base URLs in `Core/Config/AppConfig.swift`.

## Auth flow (`Features/Auth/`)
Built from the design canvas › 01 Common › Sign in.

```
RootView ── switch AuthSession.state
  .restoring     → LaunchView (restores "Keep me signed in" from Keychain)
  .signedOut     → AuthFlowView (NavigationStack)
                     Login ─► Forgot password ─► OTP ─► Create password
  .choosingRole  → RoleSelectView (only when the account has 2+ roles)
  .signedIn      → MainTabView
```

- `Session/AuthSession` – single source of truth; tokens in Keychain, last role in UserDefaults.
- `Services/AuthService` – live API (placeholder endpoints) + `MockAuthService` (used in DEBUG via `AppConfig.useMockServices`).
- Face ID / Touch ID: enabled automatically after a password sign-in; toggle off in Settings.
- Demo (mock): any ID + password of 6+ characters; OTP `000000` fails, any other 6 digits passes.
- Design tokens (colours, Plus Jakarta Sans, radii) live in `DesignSystem/Theme.swift`.

## Role dashboards (`Features/Dashboard/`)
Built from the design canvas › 02 Management App › Home and 03 Parent / Student App › Home.

| Role (UserRole) | Dashboard | Bottom tabs |
|---|---|---|
| management | `ManagementDashboardView` | Home · Attendance · Messages · Notices · Profile |
| faculty | `FacultyDashboardView` | Home · Attendance · Messages · Notices · Profile |
| parent | `LearnerDashboardView(role: .parent)` (student switcher, fees) | Home · Academics · Campus · Chat · Me |
| student | `LearnerDashboardView(role: .student)` | Home · Academics · Campus · Chat · Me |

- `RootView` → `MainTabView` → `RoleTabShell(role: session.currentRole)` → `RoleDashboardView`.
- One NavigationStack per tab (`AppRouter.path(for:)`); the custom tab bar hides on pushed screens.
- Data: `DashboardServiceProtocol` → `DashboardService` (live, placeholder endpoints) /
  `MockDashboardService` (DEBUG via `AppConfig.useMockServices`, previews, tests).
- Menu tiles and links push `Route.feature(...)`; screens not built yet show `FeaturePlaceholderView`.

## First launch (`Features/Onboarding/`)
```
GraditApp init → OnboardingStore (UserDefaults, read synchronously — no flash)
RootView
  hasCompletedOnboarding == false → OnboardingFlowView: CountrySelectionView → OnboardingView (4 pages) → Login
  hasCompletedOnboarding == true  → existing auth switch (restore / Login / role select / dashboards)
```
- Keys: `hasCompletedOnboarding` (Bool), `selectedCountryCode` (ISO code). Never reset by sign-in or sign-out.
- Skip and Get started both call `OnboardingStore.completeOnboarding()`.
- A fresh install clears any Keychain tokens left from a previous install, so the flow ends on Login.
- Country can be changed later in Settings › Country. No country-specific API address exists yet;
  `AppConfig.baseURL` is unchanged.

## Profile & Settings (`Features/Profile/`, `Features/Settings/`)
Design: 01 Common › Profile and Settings.
- Me tab (Parent/Student) and Profile tab (Faculty/Management) root = `ProfileView`.
- Pushed with `Route.profile(ProfileRoute)` on the same tab stack: Edit profile, Change password,
  Notification settings (`SettingsView`), Help & FAQ, Privacy policy, Terms, Country, and the
  Forgot password → OTP → Create password screens reused from sign-in.
- `ProfileStore` (owned by `RoleTabShell`, one per role) holds the profile and notification
  preferences; `ProfileServiceProtocol` → `ProfileService` (live, placeholder endpoints) /
  `MockProfileService` (DEBUG, previews, tests).
- Log out → `AuthSession.signOut()`; Switch role → `AuthSession.switchRole()`;
  Clear cache → `CacheCleaner` (URLCache, tmp and Caches folders only).

## Events (`Features/Events/`)
Design: canvas › 12 Events (Management & Teachers, Students & Parents).

| Role | Entry (Events tile / Campus tab) | Screens |
|---|---|---|
| management, faculty | `StaffEventListView` | My events (tabs Upcoming · Ongoing · Past · Drafts · Cancelled) → `CreateEventView` (edit / duplicate, date sheet, preview, published) → `StaffEventDetailView` (remind, export, cancel, delete, attendees) → `AddEventMediaView` → `ManageGalleryView` |
| parent, student | `LearnerEventsView` (list + calendar; also the Campus tab root) | `LearnerEventDetailView` (RSVP + guests, add to calendar, share) → `EventGalleryView` → full-screen viewer (zoom, video, share, save to Photos) |

- Routing: `Route.event(EventRoute)`; `.feature(.events)` → `EventsEntryView` (role-aware); Home's "… has ended" prompt pushes
  `.event(.addMedia(eventID:source: .home))`; `.feature(.eventMedia)` resolves the latest completed event without a gallery.
- `AppRouter.pop(_:)` was added so the Published screens can leave Create / Add media and open the event.
- Data: `EventServiceProtocol` → `EventService` (live, placeholder endpoints incl. multipart upload) / `MockEventService`
  (stateful in-memory store seeded from the design; dates are relative to today so every state is visible).
- Dates are real `Date`s formatted by `EventFormat`; statuses (upcoming / ongoing / completed) are derived from them.
- Media: `PhotosPicker` (photos JPG/PNG/HEIC ≤ 10 MB, videos MP4/MOV ≤ 200 MB, 100 per upload), camera via
  `EventCameraPicker`; downloads use add-only Photos access (`PhotoLibrarySaver`); "Add to calendar" uses
  `EKEventEditViewController` (no calendar permission needed on iOS 17+).
- Info.plist keys added: `NSPhotoLibraryAddUsageDescription`, `NSMicrophoneUsageDescription` (video with sound);
  camera text now mentions event galleries.
- Tests: `GraditTests/Features/EventsTests.swift`.

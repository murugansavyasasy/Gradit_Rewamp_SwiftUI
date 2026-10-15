"""Small in-place edits to existing Gradit files for the role dashboards.

Run from the repository root (the folder containing Gradit.xcodeproj):
    python3 apply_dashboard_edits.py
Each edit is skipped if it has already been applied.
"""
from pathlib import Path


def edit(path, old, new, marker):
    p = Path(path)
    s = p.read_text(encoding="utf-8")
    if marker in s:
        print(f"skip  {path} (already applied)")
        return
    if old not in s:
        raise SystemExit(f"FAIL  {path}: anchor not found:\n{old}")
    p.write_text(s.replace(old, new, 1), encoding="utf-8")
    print(f"edit  {path}")


# 1. Extra colours used by the dashboards (from the design files).
edit(
    "Gradit/DesignSystem/Theme.swift",
    "        static let errorBackground = Color(hex: 0xFCECEB)\n",
    "        static let errorBackground = Color(hex: 0xFCECEB)\n"
    "\n"
    "        // Dashboard accents\n"
    "        static let blue800 = Color(hex: 0x173A9C)\n"
    "        static let amber800 = Color(hex: 0x8A4E05)\n"
    "        static let red700 = Color(hex: 0xA82C27)\n"
    "        static let red800 = Color(hex: 0x7A2420)\n"
    "        static let amberBorder = Color(hex: 0xE9C98F)\n"
    "        static let blueBorder = Color(hex: 0x9DB1E8)\n"
    "        static let blueBorderLight = Color(hex: 0xB7C6EF)\n"
    "        static let divider = Color(hex: 0xEEF1F5)\n",
    "static let amber800",
)

# 2. Short college name for the dashboard header ("UCE Chennai").
edit(
    "Gradit/Features/Auth/Models/AuthModels.swift",
    "nonisolated struct College: Codable, Identifiable, Hashable, Sendable {\n"
    "    let id: String\n"
    "    let name: String\n"
    "}\n",
    "nonisolated struct College: Codable, Identifiable, Hashable, Sendable {\n"
    "    let id: String\n"
    "    let name: String\n"
    "    /// e.g. \"UCE Chennai\" — shown in the dashboard header when present.\n"
    "    var shortName: String? = nil\n"
    "}\n",
    "var shortName: String?",
)

# 3. Mock (DEBUG only) account gets all four roles so every dashboard can be tried.
edit(
    "Gradit/Features/Auth/Services/AuthService.swift",
    "        roles: [.parent, .student],\n"
    "        colleges: [College(id: \"c-1\", name: \"University College of Engineering, Chennai\")]\n",
    "        roles: [.parent, .student, .faculty, .management],\n"
    "        colleges: [College(id: \"c-1\", name: \"University College of Engineering, Chennai\", shortName: \"UCE Chennai\")]\n",
    "roles: [.parent, .student, .faculty, .management]",
)

# 4. Expose the selected college from the session.
edit(
    "Gradit/Features/Auth/Session/AuthSession.swift",
    "    var preferredRole: UserRole? {\n",
    "    var currentCollege: College? {\n"
    "        if case .signedIn(_, _, let college) = state { college } else { nil }\n"
    "    }\n"
    "\n"
    "    var preferredRole: UserRole? {\n",
    "var currentCollege: College?",
)

# 5. Architecture notes.
p = Path("ARCHITECTURE.md")
s = p.read_text(encoding="utf-8")
if "## Role dashboards" not in s:
    s += """
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
- Shared pieces: `DesignSystem/Components/DashboardPrimitives.swift`, `Features/Dashboard/Components/`.
"""
    p.write_text(s, encoding="utf-8")
    print("edit  ARCHITECTURE.md")
else:
    print("skip  ARCHITECTURE.md (already applied)")

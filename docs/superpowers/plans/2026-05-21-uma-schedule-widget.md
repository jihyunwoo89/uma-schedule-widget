# 우마무스메 스케줄 위젯 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS WidgetKit app showing Korean-server Umamusume schedule (Champions Meeting, League of Heroes, gacha pickups) across size-specific home & lock-screen widgets, driven by a remote JSON with bundled fallback.

**Architecture:** Mirrors the sibling `../lckwidget` app — XcodeGen project + SPM `UmaCore` package (all models/logic/views) + thin WidgetKit extension + thin app target. Data comes from a remote `ScheduleDocument` JSON fetched by `ScheduleRepository` (TTL cache in an App Group, stale fallback, then bundled JSON). A `ScheduleStateResolver` turns the document + a `WidgetVariant`/`DetailLevel` into a `WidgetState` the SwiftUI widget views render.

**Tech Stack:** Swift 5.10, iOS 17+, SwiftUI, WidgetKit, Swift Package Manager, XcodeGen, App Groups (UserDefaults + file cache), BackgroundTasks.

**Reference spec:** `docs/superpowers/specs/2026-05-21-uma-schedule-widget-design.md`
**Reference implementation to copy patterns from:** `../lckwidget` (paths given inline per task).

---

## Conventions (apply to every task)

- Working directory: `/Users/damienjee/Desktop/claude_dev/uma_schedule_widget`
- Core unit tests run with: `cd Core && swift test`
- Run a single test: `cd Core && swift test --filter <TestClass>/<testMethod>`
- All Core types are `Codable, Sendable` (and `Hashable` for widget payloads).
- Identifiers: bundle prefix `com.damienjee`, app bundle `com.damienjee.umaschedule`, widget bundle `com.damienjee.umaschedule.widgets`, App Group `group.com.damienjee.umaschedule`, BGTask id `com.damienjee.umaschedule.refresh`.
- Dates in JSON are ISO-8601 (decoder uses `.iso8601`). All in-app date math uses `Calendar.current` / KST is implicit in the source data.
- Commit after every task with the message shown in its final step.

---

## File Structure

```
uma_schedule_widget/
├── project.yml                              # XcodeGen config (Task 0.1)
├── Core/
│   ├── Package.swift                        # SPM manifest (Task 0.2)
│   ├── Sources/UmaCore/
│   │   ├── UmaCore.swift                    # package marker (Task 0.2)
│   │   ├── Models/
│   │   │   ├── TrackCondition.swift         # Task 1.1
│   │   │   ├── EventPhase.swift             # Task 1.2
│   │   │   ├── Events.swift                 # CM / LoH / Gacha (Task 1.3)
│   │   │   ├── ScheduleDocument.swift       # Task 1.4
│   │   │   ├── EventCard.swift              # EventCard/Category/Status/DetailLevel (Task 1.5)
│   │   │   └── UserPrefs.swift              # Task 1.6
│   │   ├── Logic/
│   │   │   ├── ScheduledEvent.swift         # phase-transition protocol+ext (Task 3.1)
│   │   │   ├── CountdownFormatter.swift      # Task 3.2
│   │   │   └── EventCardFactory.swift        # build EventCards (Task 3.3)
│   │   ├── Cache/
│   │   │   ├── AppGroupStore.swift          # Task 2.1 (copied)
│   │   │   ├── ScheduleFallback.swift       # FallbackProviding + bundle (Task 2.2)
│   │   │   └── TrackImageCache.swift        # download + file cache (Task 6.4)
│   │   ├── DataSource/
│   │   │   ├── RemoteScheduleClient.swift   # Task 2.3
│   │   │   ├── ScheduleEndpoint.swift       # remote URL constant (Task 2.3)
│   │   │   └── ScheduleRepository.swift     # TTL + fallback (Task 2.4)
│   │   ├── Widgets/
│   │   │   ├── WidgetVariant.swift          # WidgetVariant (Task 4.1)
│   │   │   ├── WidgetEntry.swift            # WidgetEntry/WidgetState (Task 4.2)
│   │   │   └── ScheduleStateResolver.swift  # Task 4.3
│   │   ├── Localization/
│   │   │   ├── L.swift                      # Task 5.1
│   │   │   └── Bundle+UmaCore.swift         # Task 5.1
│   │   ├── DesignSystem/
│   │   │   ├── Typography.swift             # Task 6.1 (copied)
│   │   │   ├── Color+Hex.swift              # Task 6.1 (copied)
│   │   │   ├── CategoryBadge.swift          # Task 6.2
│   │   │   ├── CourseDiagramView.swift      # fallback track art (Task 6.3)
│   │   │   └── TrackImageView.swift         # cached image or diagram (Task 6.4)
│   │   ├── UI/
│   │   │   ├── widget views (Tasks 7.x)
│   │   │   └── app views (Tasks 9.x)
│   │   └── Resources/
│   │       ├── en.lproj/Localizable.strings # Task 5.2
│   │       ├── ko.lproj/Localizable.strings # Task 5.2
│   │       ├── schedule_fallback.json       # Task 2.2
│   │       └── PrivacyInfo.xcprivacy        # Task 10.1
│   └── Tests/UmaCoreTests/                  # tests per task
├── App/
│   ├── UmaScheduleApp.swift                 # Task 9.1
│   ├── RootView.swift                       # Task 9.2
│   ├── BackgroundRefreshTask.swift          # Task 9.4
│   ├── Info.plist                           # Task 0.1
│   └── UmaSchedule.entitlements             # Task 0.1
├── Widgets/
│   ├── ScheduleTimelineProvider.swift       # Task 8.1
│   ├── WidgetPreferenceApplier.swift        # Task 8.1
│   ├── UmaWidgetBundle.swift                # Task 8.4
│   ├── HomeWidgets.swift / LockWidgets.swift # Tasks 8.2-8.3
│   ├── Info.plist                           # Task 0.1
│   └── UmaWidgets.entitlements              # Task 0.1
├── scripts/
│   └── generate-fallback.sh                 # Task 10.2
└── docs/                                    # spec + this plan + store assets
```

---

# Phase 0 — Project scaffold

### Task 0.1: XcodeGen project, Info.plists, entitlements

**Files:**
- Create: `project.yml`
- Create: `App/Info.plist`, `App/UmaSchedule.entitlements`
- Create: `Widgets/Info.plist`, `Widgets/UmaWidgets.entitlements`

- [ ] **Step 1: Write `project.yml`**

```yaml
name: UmaSchedule
options:
  bundleIdPrefix: com.damienjee
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "5.10"
    DEVELOPMENT_TEAM: "4SBX5T4LW8"
    CODE_SIGN_STYLE: Automatic
    TARGETED_DEVICE_FAMILY: "1"
packages:
  UmaCore:
    path: Core
targets:
  UmaSchedule:
    type: application
    platform: iOS
    sources:
      - path: App
    dependencies:
      - target: UmaWidgets
        embed: true
      - package: UmaCore
    info:
      path: App/Info.plist
      properties:
        CFBundleShortVersionString: "1.0"
        CFBundleVersion: "1"
        CFBundleDisplayName: 우마 스케줄
        CFBundleLocalizations: [en, ko]
        ITSAppUsesNonExemptEncryption: false
        UILaunchScreen: {}
        UIBackgroundModes: [fetch, processing]
        BGTaskSchedulerPermittedIdentifiers:
          - com.damienjee.umaschedule.refresh
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
    entitlements:
      path: App/UmaSchedule.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.damienjee.umaschedule
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.damienjee.umaschedule
        TARGETED_DEVICE_FAMILY: "1"
  UmaWidgets:
    type: app-extension
    platform: iOS
    sources:
      - path: Widgets
    dependencies:
      - package: UmaCore
    info:
      path: Widgets/Info.plist
      properties:
        CFBundleShortVersionString: "1.0"
        CFBundleVersion: "1"
        CFBundleDisplayName: 우마 스케줄
        CFBundleLocalizations: [en, ko]
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
    entitlements:
      path: Widgets/UmaWidgets.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.damienjee.umaschedule
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.damienjee.umaschedule.widgets
        TARGETED_DEVICE_FAMILY: "1"
```

- [ ] **Step 2: Write `App/Info.plist`** (minimal — XcodeGen merges `info.properties`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict/></plist>
```

- [ ] **Step 3: Write `Widgets/Info.plist`** — identical minimal stub as Step 2.

- [ ] **Step 4: Write `App/UmaSchedule.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>com.apple.security.application-groups</key>
  <array><string>group.com.damienjee.umaschedule</string></array>
</dict></plist>
```

- [ ] **Step 5: Write `Widgets/UmaWidgets.entitlements`** — identical content to Step 4.

- [ ] **Step 6: Commit**

```bash
git add project.yml App/Info.plist App/UmaSchedule.entitlements Widgets/Info.plist Widgets/UmaWidgets.entitlements
git commit -m "chore: scaffold XcodeGen project, Info.plists, entitlements"
```

> Note: `xcodegen generate` is run later (Task 8.5) once sources exist. The Core package builds independently via `swift test` throughout Phases 1–7.

### Task 0.2: SPM package manifest + marker

**Files:**
- Create: `Core/Package.swift`
- Create: `Core/Sources/UmaCore/UmaCore.swift`
- Create: `Core/Sources/UmaCore/Resources/.gitkeep`
- Create: `Core/Tests/UmaCoreTests/.gitkeep`

- [ ] **Step 1: Write `Core/Package.swift`**

```swift
// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "UmaCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UmaCore", targets: ["UmaCore"])
    ],
    targets: [
        .target(
            name: "UmaCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "UmaCoreTests",
            dependencies: ["UmaCore"]
        )
    ]
)
```

- [ ] **Step 2: Write `Core/Sources/UmaCore/UmaCore.swift`**

```swift
// UmaCore — shared models, data layer, design system, and widget views for the
// Umamusume schedule widget. Imported by both the app and the widget extension.
public enum UmaCore {
    public static let version = "1.0"
}
```

- [ ] **Step 3: Create empty resource/test placeholder files**

```bash
mkdir -p Core/Sources/UmaCore/Resources Core/Tests/UmaCoreTests
touch Core/Sources/UmaCore/Resources/.gitkeep Core/Tests/UmaCoreTests/.gitkeep
```

- [ ] **Step 4: Verify the package builds**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Core/Package.swift Core/Sources/UmaCore/UmaCore.swift Core/Sources/UmaCore/Resources/.gitkeep Core/Tests/UmaCoreTests/.gitkeep
git commit -m "chore: add UmaCore SPM package skeleton"
```

---

# Phase 1 — Core models

### Task 1.1: TrackCondition + Surface

**Files:**
- Create: `Core/Sources/UmaCore/Models/TrackCondition.swift`
- Test: `Core/Tests/UmaCoreTests/TrackConditionTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class TrackConditionTests: XCTestCase {
    func test_summary_formatsCourseSurfaceDistance() {
        let t = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf, direction: "좌", imageURL: nil)
        XCTAssertEqual(t.summary, "도쿄 · 잔디 2400m")
    }

    func test_summary_dirtUsesDirtLabel() {
        let t = TrackCondition(racecourse: "오이", distanceMeters: 2000, surface: .dirt, direction: nil, imageURL: nil)
        XCTAssertEqual(t.summary, "오이 · 더트 2000m")
    }

    func test_codableRoundTrip() throws {
        let t = TrackCondition(racecourse: "한신", distanceMeters: 1600, surface: .turf, direction: "우",
                               imageURL: URL(string: "https://x/y.png"))
        let data = try JSONEncoder().encode(t)
        let back = try JSONDecoder().decode(TrackCondition.self, from: data)
        XCTAssertEqual(t, back)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter TrackConditionTests`
Expected: FAIL — cannot find `TrackCondition` in scope.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum Surface: String, Codable, Sendable {
    case turf
    case dirt

    /// Korean display label. "잔디" (grass) for turf, "더트" for dirt.
    public var koLabel: String {
        switch self {
        case .turf: return "잔디"
        case .dirt: return "더트"
        }
    }
}

public struct TrackCondition: Codable, Hashable, Sendable {
    public var racecourse: String   // 경마장: "도쿄"/"나카야마"/"한신"...
    public var distanceMeters: Int  // 거리: 2400
    public var surface: Surface     // 바바: turf(잔디)/dirt(더트)
    public var direction: String?   // 방향: 좌/우/직선
    public var imageURL: URL?       // 마장 이미지(원격). nil이면 코스 도식 fallback.

    public init(racecourse: String, distanceMeters: Int, surface: Surface,
                direction: String? = nil, imageURL: URL? = nil) {
        self.racecourse = racecourse
        self.distanceMeters = distanceMeters
        self.surface = surface
        self.direction = direction
        self.imageURL = imageURL
    }

    /// One-line widget summary: "도쿄 · 잔디 2400m".
    public var summary: String {
        "\(racecourse) · \(surface.koLabel) \(distanceMeters)m"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter TrackConditionTests`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Models/TrackCondition.swift Core/Tests/UmaCoreTests/TrackConditionTests.swift
git commit -m "feat: add TrackCondition model with summary formatting"
```

### Task 1.2: EventPhase + PhaseKind

**Files:**
- Create: `Core/Sources/UmaCore/Models/EventPhase.swift`
- Test: `Core/Tests/UmaCoreTests/EventPhaseTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class EventPhaseTests: XCTestCase {
    func test_codableRoundTrip() throws {
        let p = EventPhase(kind: .round1, label: "라운드1", date: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder().encode(p)
        let back = try JSONDecoder().decode(EventPhase.self, from: data)
        XCTAssertEqual(p, back)
    }

    func test_phaseKind_decodesFromRawString() throws {
        let json = #"{"kind":"round2","label":"결승","date":0}"#.data(using: .utf8)!
        let p = try JSONDecoder().decode(EventPhase.self, from: json)
        XCTAssertEqual(p.kind, .round2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter EventPhaseTests`
Expected: FAIL — cannot find `EventPhase`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum PhaseKind: String, Codable, Sendable {
    case open      // 오픈/사전등록
    case round1    // 라운드1 (리그/예선)
    case round2    // 라운드2 (결승)
    case ended     // 종료
}

public struct EventPhase: Codable, Hashable, Sendable {
    public var kind: PhaseKind
    public var label: String   // 표시명: "라운드1", "결승"
    public var date: Date      // 단계 시작 시각

    public init(kind: PhaseKind, label: String, date: Date) {
        self.kind = kind
        self.label = label
        self.date = date
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter EventPhaseTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Models/EventPhase.swift Core/Tests/UmaCoreTests/EventPhaseTests.swift
git commit -m "feat: add EventPhase model"
```

### Task 1.3: ChampionsMeeting / LeagueOfHeroes / GachaBanner

**Files:**
- Create: `Core/Sources/UmaCore/Models/Events.swift`
- Test: `Core/Tests/UmaCoreTests/EventsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class EventsTests: XCTestCase {
    private let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)

    func test_championsMeeting_roundTrip() throws {
        let cm = ChampionsMeeting(
            id: "cm-2026-06", name: "리브르(LIBRA)", track: track,
            phases: [EventPhase(kind: .round1, label: "라운드1", date: Date(timeIntervalSince1970: 100))]
        )
        let data = try JSONEncoder().encode(cm)
        XCTAssertEqual(try JSONDecoder().decode(ChampionsMeeting.self, from: data), cm)
    }

    func test_gachaBanner_roundTrip() throws {
        let b = GachaBanner(id: "g1", type: .trainee, featured: ["오구리 캡"],
                            startDate: Date(timeIntervalSince1970: 0),
                            endDate: Date(timeIntervalSince1970: 1000))
        let data = try JSONEncoder().encode(b)
        XCTAssertEqual(try JSONDecoder().decode(GachaBanner.self, from: data), b)
    }

    func test_bannerType_rawValues() {
        XCTAssertEqual(BannerType.trainee.rawValue, "trainee")
        XCTAssertEqual(BannerType.supportCard.rawValue, "supportCard")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter EventsTests`
Expected: FAIL — cannot find `ChampionsMeeting`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public struct ChampionsMeeting: Codable, Hashable, Sendable {
    public var id: String
    public var name: String          // "리브르(LIBRA)" 등 미팅명
    public var track: TrackCondition
    public var phases: [EventPhase]  // 오픈→라운드1→라운드2→종료

    public init(id: String, name: String, track: TrackCondition, phases: [EventPhase]) {
        self.id = id; self.name = name; self.track = track; self.phases = phases
    }
}

public struct LeagueOfHeroes: Codable, Hashable, Sendable {
    public var id: String
    public var season: String        // 시즌/회차명
    public var track: TrackCondition
    public var phases: [EventPhase]

    public init(id: String, season: String, track: TrackCondition, phases: [EventPhase]) {
        self.id = id; self.season = season; self.track = track; self.phases = phases
    }
}

public enum BannerType: String, Codable, Sendable {
    case trainee      // 육성마
    case supportCard  // 서포트카드
}

public struct GachaBanner: Codable, Hashable, Sendable {
    public var id: String
    public var type: BannerType
    public var featured: [String]    // 픽업 대상명
    public var startDate: Date
    public var endDate: Date

    public init(id: String, type: BannerType, featured: [String], startDate: Date, endDate: Date) {
        self.id = id; self.type = type; self.featured = featured
        self.startDate = startDate; self.endDate = endDate
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter EventsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Models/Events.swift Core/Tests/UmaCoreTests/EventsTests.swift
git commit -m "feat: add ChampionsMeeting, LeagueOfHeroes, GachaBanner models"
```

### Task 1.4: ScheduleDocument

**Files:**
- Create: `Core/Sources/UmaCore/Models/ScheduleDocument.swift`
- Test: `Core/Tests/UmaCoreTests/ScheduleDocumentTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class ScheduleDocumentTests: XCTestCase {
    func test_decodesFromJSONWithISO8601Dates() throws {
        let json = """
        {
          "version": 1,
          "updatedAt": "2026-05-20T00:00:00Z",
          "server": "kr",
          "championsMeetings": [],
          "leagueOfHeroes": [],
          "gachaBanners": []
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let doc = try decoder.decode(ScheduleDocument.self, from: json)
        XCTAssertEqual(doc.version, 1)
        XCTAssertEqual(doc.server, "kr")
        XCTAssertTrue(doc.championsMeetings.isEmpty)
    }

    func test_emptyDocumentHelper() {
        XCTAssertEqual(ScheduleDocument.empty.server, "kr")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter ScheduleDocumentTests`
Expected: FAIL — cannot find `ScheduleDocument`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public struct ScheduleDocument: Codable, Hashable, Sendable {
    public var version: Int
    public var updatedAt: Date
    public var server: String
    public var championsMeetings: [ChampionsMeeting]
    public var leagueOfHeroes: [LeagueOfHeroes]
    public var gachaBanners: [GachaBanner]

    public init(version: Int, updatedAt: Date, server: String,
                championsMeetings: [ChampionsMeeting], leagueOfHeroes: [LeagueOfHeroes],
                gachaBanners: [GachaBanner]) {
        self.version = version
        self.updatedAt = updatedAt
        self.server = server
        self.championsMeetings = championsMeetings
        self.leagueOfHeroes = leagueOfHeroes
        self.gachaBanners = gachaBanners
    }

    public static let empty = ScheduleDocument(
        version: 1, updatedAt: Date(timeIntervalSince1970: 0), server: "kr",
        championsMeetings: [], leagueOfHeroes: [], gachaBanners: []
    )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter ScheduleDocumentTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Models/ScheduleDocument.swift Core/Tests/UmaCoreTests/ScheduleDocumentTests.swift
git commit -m "feat: add ScheduleDocument root model"
```

### Task 1.5: EventCard / EventCategory / EventStatus / DetailLevel

**Files:**
- Create: `Core/Sources/UmaCore/Models/EventCard.swift`
- Test: `Core/Tests/UmaCoreTests/EventCardTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class EventCardTests: XCTestCase {
    func test_roundTrip() throws {
        let card = EventCard(
            category: .championsMeeting, title: "리브르(LIBRA)",
            track: TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf),
            phaseLabel: "라운드1까지", targetDate: Date(timeIntervalSince1970: 5000), status: .upcoming
        )
        let data = try JSONEncoder().encode(card)
        XCTAssertEqual(try JSONDecoder().decode(EventCard.self, from: data), card)
    }

    func test_categoryRawValues() {
        XCTAssertEqual(EventCategory.championsMeeting.rawValue, "championsMeeting")
        XCTAssertEqual(EventCategory.leagueOfHeroes.rawValue, "leagueOfHeroes")
        XCTAssertEqual(EventCategory.gacha.rawValue, "gacha")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter EventCardTests`
Expected: FAIL — cannot find `EventCard`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum EventCategory: String, Codable, Hashable, Sendable {
    case championsMeeting
    case leagueOfHeroes
    case gacha
}

public enum EventStatus: String, Codable, Hashable, Sendable {
    case upcoming   // 시작 전 — targetDate까지 카운트다운
    case active     // 진행 중 — targetDate는 종료일
    case ended      // 종료
}

public enum DetailLevel: String, Codable, Hashable, Sendable {
    case overview   // Small
    case brief      // Medium
    case detailed   // Large
}

public struct EventCard: Codable, Hashable, Sendable {
    public var category: EventCategory
    public var title: String              // 미팅명 / 시즌명 / 픽업 대상
    public var track: TrackCondition?     // gacha는 nil
    public var phaseLabel: String         // "라운드1까지" / "진행중" / "오픈까지"
    public var targetDate: Date           // d-day 기준일
    public var status: EventStatus

    public init(category: EventCategory, title: String, track: TrackCondition?,
                phaseLabel: String, targetDate: Date, status: EventStatus) {
        self.category = category
        self.title = title
        self.track = track
        self.phaseLabel = phaseLabel
        self.targetDate = targetDate
        self.status = status
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter EventCardTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Models/EventCard.swift Core/Tests/UmaCoreTests/EventCardTests.swift
git commit -m "feat: add EventCard derived model + category/status/detail enums"
```

### Task 1.6: UserPrefs (category visibility/order, font, locale)

**Files:**
- Create: `Core/Sources/UmaCore/Models/UserPrefs.swift`
- Test: `Core/Tests/UmaCoreTests/UserPrefsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class UserPrefsTests: XCTestCase {
    func test_default_showsAllCategoriesInDefaultOrder() {
        let p = UserPrefs.default
        XCTAssertEqual(p.categoryOrder, [.championsMeeting, .leagueOfHeroes, .gacha])
        XCTAssertEqual(p.fontTheme, .system)
        XCTAssertEqual(p.localeOverride, .system)
        XCTAssertTrue(p.notifyBeforePhase)
    }

    func test_backwardCompatDecode_missingFieldsUseDefaults() throws {
        let json = "{}".data(using: .utf8)!
        let p = try JSONDecoder().decode(UserPrefs.self, from: json)
        XCTAssertEqual(p.categoryOrder, [.championsMeeting, .leagueOfHeroes, .gacha])
        XCTAssertEqual(p.fontTheme, .system)
    }

    func test_roundTrip() throws {
        var p = UserPrefs.default
        p.fontTheme = .mono
        p.localeOverride = .ko
        p.categoryOrder = [.gacha, .championsMeeting, .leagueOfHeroes]
        let data = try JSONEncoder().encode(p)
        XCTAssertEqual(try JSONDecoder().decode(UserPrefs.self, from: data), p)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter UserPrefsTests`
Expected: FAIL — cannot find `UserPrefs`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum AppLocale: String, Codable, CaseIterable, Sendable {
    case system, ko, en
}

public enum FontTheme: String, Codable, CaseIterable, Sendable {
    case system, rounded, mono, serif
}

public struct UserPrefs: Hashable, Codable, Sendable {
    public var categoryOrder: [EventCategory]   // 표시 순서 (목록에 없는 카테고리는 숨김)
    public var notifyBeforePhase: Bool          // 단계 시작 전 알림
    public var localeOverride: AppLocale
    public var fontTheme: FontTheme

    public init(categoryOrder: [EventCategory] = [.championsMeeting, .leagueOfHeroes, .gacha],
                notifyBeforePhase: Bool = true,
                localeOverride: AppLocale = .system,
                fontTheme: FontTheme = .system) {
        self.categoryOrder = categoryOrder
        self.notifyBeforePhase = notifyBeforePhase
        self.localeOverride = localeOverride
        self.fontTheme = fontTheme
    }

    public static let `default` = UserPrefs()

    /// Backward-compat decode — every field optional with a default so older blobs
    /// (and the `{}` first-launch case) decode cleanly.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.categoryOrder = try c.decodeIfPresent([EventCategory].self, forKey: .categoryOrder)
            ?? [.championsMeeting, .leagueOfHeroes, .gacha]
        self.notifyBeforePhase = try c.decodeIfPresent(Bool.self, forKey: .notifyBeforePhase) ?? true
        self.localeOverride = try c.decodeIfPresent(AppLocale.self, forKey: .localeOverride) ?? .system
        self.fontTheme = try c.decodeIfPresent(FontTheme.self, forKey: .fontTheme) ?? .system
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter UserPrefsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Models/UserPrefs.swift Core/Tests/UmaCoreTests/UserPrefsTests.swift
git commit -m "feat: add UserPrefs with category order, font, locale, notify prefs"
```

---

# Phase 2 — Cache + data source

### Task 2.1: AppGroupStore (TTL envelope + stale read)

**Files:**
- Create: `Core/Sources/UmaCore/Cache/AppGroupStore.swift`
- Test: `Core/Tests/UmaCoreTests/AppGroupStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class AppGroupStoreTests: XCTestCase {
    private func makeStore(now: Date) -> AppGroupStore {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return AppGroupStore(defaults: defaults, clock: { now })
    }

    func test_readWithinTTL_returnsValue() throws {
        let t0 = Date(timeIntervalSince1970: 0)
        let store = makeStore(now: t0)
        try store.write([1, 2, 3], forKey: "k", ttl: 100)
        XCTAssertEqual(store.read([Int].self, forKey: "k"), [1, 2, 3])
    }

    func test_readPastTTL_returnsNil_butStaleReadReturnsValue() throws {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        var now = Date(timeIntervalSince1970: 0)
        let store = AppGroupStore(defaults: defaults, clock: { now })
        try store.write(["x"], forKey: "k", ttl: 10)
        now = Date(timeIntervalSince1970: 50)
        XCTAssertNil(store.read([String].self, forKey: "k"))
        let stale = store.readAllowingStale([String].self, forKey: "k")
        XCTAssertEqual(stale?.value, ["x"])
        XCTAssertTrue(stale?.isStale ?? false)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter AppGroupStoreTests`
Expected: FAIL — cannot find `AppGroupStore`.

- [ ] **Step 3: Write the implementation** (faithful copy of `../lckwidget/Core/Sources/LCKCore/Cache/AppGroupStore.swift`, suite renamed)

```swift
import Foundation

public struct CachedValue<Value> {
    public let value: Value
    public let isStale: Bool
}

public final class AppGroupStore: @unchecked Sendable {
    public static let suiteName = "group.com.damienjee.umaschedule"

    private let defaults: UserDefaults
    private let clock: @Sendable () -> Date
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults, clock: @escaping @Sendable () -> Date = Date.init) {
        self.defaults = defaults
        self.clock = clock
    }

    public static func shared() -> AppGroupStore {
        let suite = UserDefaults(suiteName: suiteName) ?? .standard
        return AppGroupStore(defaults: suite)
    }

    private struct Envelope<T: Codable>: Codable {
        let value: T
        let writtenAt: Date
        let ttl: TimeInterval
    }

    public func write<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval) throws {
        let envelope = Envelope(value: value, writtenAt: clock(), ttl: ttl)
        defaults.set(try encoder.encode(envelope), forKey: key)
    }

    public func read<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key),
              let envelope = try? decoder.decode(Envelope<T>.self, from: data) else { return nil }
        let age = clock().timeIntervalSince(envelope.writtenAt)
        return age <= envelope.ttl ? envelope.value : nil
    }

    public func readAllowingStale<T: Codable>(_ type: T.Type, forKey key: String) -> CachedValue<T>? {
        guard let data = defaults.data(forKey: key),
              let envelope = try? decoder.decode(Envelope<T>.self, from: data) else { return nil }
        let age = clock().timeIntervalSince(envelope.writtenAt)
        return CachedValue(value: envelope.value, isStale: age > envelope.ttl)
    }

    public func remove(forKey key: String) { defaults.removeObject(forKey: key) }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter AppGroupStoreTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Cache/AppGroupStore.swift Core/Tests/UmaCoreTests/AppGroupStoreTests.swift
git commit -m "feat: add AppGroupStore TTL cache with stale-read fallback"
```

### Task 2.2: Bundled fallback (ScheduleFallback + schedule_fallback.json)

**Files:**
- Create: `Core/Sources/UmaCore/Cache/ScheduleFallback.swift`
- Create: `Core/Sources/UmaCore/Resources/schedule_fallback.json`
- Test: `Core/Tests/UmaCoreTests/ScheduleFallbackTests.swift`

- [ ] **Step 1: Write the bundled JSON `Core/Sources/UmaCore/Resources/schedule_fallback.json`** (seed sample so the widget renders before first network success)

```json
{
  "version": 1,
  "updatedAt": "2026-05-20T00:00:00Z",
  "server": "kr",
  "championsMeetings": [
    {
      "id": "cm-2026-06",
      "name": "리브르(LIBRA)",
      "track": { "racecourse": "도쿄", "distanceMeters": 2400, "surface": "turf", "direction": "좌" },
      "phases": [
        { "kind": "open",   "label": "오픈",    "date": "2026-06-01T00:00:00Z" },
        { "kind": "round1", "label": "라운드1", "date": "2026-06-13T00:00:00Z" },
        { "kind": "round2", "label": "라운드2", "date": "2026-06-20T00:00:00Z" },
        { "kind": "ended",  "label": "종료",    "date": "2026-06-21T00:00:00Z" }
      ]
    }
  ],
  "leagueOfHeroes": [
    {
      "id": "loh-2026-s3",
      "season": "시즌 3",
      "track": { "racecourse": "나카야마", "distanceMeters": 2000, "surface": "turf", "direction": "우" },
      "phases": [
        { "kind": "open",   "label": "오픈",   "date": "2026-06-05T00:00:00Z" },
        { "kind": "round1", "label": "본선",   "date": "2026-06-10T00:00:00Z" },
        { "kind": "ended",  "label": "종료",   "date": "2026-06-12T00:00:00Z" }
      ]
    }
  ],
  "gachaBanners": [
    {
      "id": "g-2026-06-01",
      "type": "trainee",
      "featured": ["오구리 캡"],
      "startDate": "2026-06-02T00:00:00Z",
      "endDate": "2026-06-16T00:00:00Z"
    },
    {
      "id": "g-2026-06-02",
      "type": "supportCard",
      "featured": ["키타산 블랙"],
      "startDate": "2026-06-02T00:00:00Z",
      "endDate": "2026-06-16T00:00:00Z"
    }
  ]
}
```

- [ ] **Step 2: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class ScheduleFallbackTests: XCTestCase {
    func test_loadsBundledDocument() throws {
        let doc = try ScheduleFallback.production.load()
        XCTAssertEqual(doc.server, "kr")
        XCTAssertFalse(doc.championsMeetings.isEmpty)
        XCTAssertFalse(doc.gachaBanners.isEmpty)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd Core && swift test --filter ScheduleFallbackTests`
Expected: FAIL — cannot find `ScheduleFallback`.

- [ ] **Step 4: Write the implementation**

```swift
import Foundation

public protocol ScheduleProviding: Sendable {
    func load() throws -> ScheduleDocument
}

public enum ScheduleFallbackError: Error {
    case resourceNotFound(String)
}

public struct ScheduleFallback: Sendable {
    private let bundle: Bundle
    private let resourceName: String

    public init(bundle: Bundle, resourceName: String) {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    public static var production: ScheduleFallback {
        ScheduleFallback(bundle: .module, resourceName: "schedule_fallback")
    }

    public func load() throws -> ScheduleDocument {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ScheduleFallbackError.resourceNotFound(resourceName)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScheduleDocument.self, from: try Data(contentsOf: url))
    }
}

extension ScheduleFallback: ScheduleProviding {}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd Core && swift test --filter ScheduleFallbackTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Core/Sources/UmaCore/Cache/ScheduleFallback.swift Core/Sources/UmaCore/Resources/schedule_fallback.json Core/Tests/UmaCoreTests/ScheduleFallbackTests.swift
git commit -m "feat: add bundled schedule fallback loader + seed JSON"
```

### Task 2.3: RemoteScheduleClient + endpoint

**Files:**
- Create: `Core/Sources/UmaCore/DataSource/ScheduleEndpoint.swift`
- Create: `Core/Sources/UmaCore/DataSource/RemoteScheduleClient.swift`
- Test: `Core/Tests/UmaCoreTests/RemoteScheduleClientTests.swift`

- [ ] **Step 1: Write the failing test** (inject a transport closure so no real network is hit)

```swift
import XCTest
@testable import UmaCore

final class RemoteScheduleClientTests: XCTestCase {
    func test_fetch_decodesDocument() async throws {
        let json = """
        {"version":2,"updatedAt":"2026-05-20T00:00:00Z","server":"kr",
         "championsMeetings":[],"leagueOfHeroes":[],"gachaBanners":[]}
        """.data(using: .utf8)!
        let client = RemoteScheduleClient(transport: { _ in (json, 200) })
        let doc = try await client.fetch()
        XCTAssertEqual(doc.version, 2)
    }

    func test_fetch_non200Throws() async {
        let client = RemoteScheduleClient(transport: { _ in (Data(), 503) })
        do { _ = try await client.fetch(); XCTFail("should throw") }
        catch { /* expected */ }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter RemoteScheduleClientTests`
Expected: FAIL — cannot find `RemoteScheduleClient`.

- [ ] **Step 3: Write `ScheduleEndpoint.swift`**

```swift
import Foundation

/// Remote schedule source. The JSON file is hand-maintained and hosted (GitHub raw by
/// default). Update this URL when the hosting location is finalized (spec §9).
public enum ScheduleEndpoint {
    public static let url = URL(string: "https://raw.githubusercontent.com/damienjee/uma-schedule-data/main/schedule.json")!
}
```

- [ ] **Step 4: Write `RemoteScheduleClient.swift`**

```swift
import Foundation

public enum RemoteScheduleError: Error {
    case badStatus(Int)
}

public struct RemoteScheduleClient: Sendable {
    /// (URL) -> (body, statusCode). Injectable so tests avoid the network.
    public typealias Transport = @Sendable (URL) async throws -> (Data, Int)

    private let url: URL
    private let transport: Transport

    public init(url: URL = ScheduleEndpoint.url, transport: @escaping Transport) {
        self.url = url
        self.transport = transport
    }

    /// Production transport over URLSession.
    public static func live(url: URL = ScheduleEndpoint.url) -> RemoteScheduleClient {
        RemoteScheduleClient(url: url) { url in
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (data, code)
        }
    }

    public func fetch() async throws -> ScheduleDocument {
        let (data, code) = try await transport(url)
        guard (200...299).contains(code) else { throw RemoteScheduleError.badStatus(code) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScheduleDocument.self, from: data)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd Core && swift test --filter RemoteScheduleClientTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Core/Sources/UmaCore/DataSource/ScheduleEndpoint.swift Core/Sources/UmaCore/DataSource/RemoteScheduleClient.swift Core/Tests/UmaCoreTests/RemoteScheduleClientTests.swift
git commit -m "feat: add RemoteScheduleClient with injectable transport"
```

### Task 2.4: ScheduleRepository (TTL → stale → bundle)

**Files:**
- Create: `Core/Sources/UmaCore/DataSource/ScheduleRepository.swift`
- Test: `Core/Tests/UmaCoreTests/ScheduleRepositoryTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class ScheduleRepositoryTests: XCTestCase {
    private func store(now: Date) -> AppGroupStore {
        AppGroupStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!, clock: { now })
    }
    private func doc(version: Int) -> ScheduleDocument {
        ScheduleDocument(version: version, updatedAt: Date(timeIntervalSince1970: 0), server: "kr",
                         championsMeetings: [], leagueOfHeroes: [], gachaBanners: [])
    }
    private struct StubFallback: ScheduleProviding {
        let document: ScheduleDocument
        func load() throws -> ScheduleDocument { document }
    }

    func test_freshNetwork_isCachedAndReturned() async throws {
        let now = Date(timeIntervalSince1970: 0)
        let s = store(now: now)
        let client = RemoteScheduleClient(transport: { _ in
            (try! JSONEncoder.iso.encode(self.doc(version: 7)), 200)
        })
        let repo = ScheduleRepository(client: client, store: s, fallback: StubFallback(document: doc(version: 0)), clock: { now })
        let result = try await repo.current()
        XCTAssertEqual(result.version, 7)
        // Second call within TTL serves cache (transport would 500 if hit)
        let repo2 = ScheduleRepository(client: RemoteScheduleClient(transport: { _ in (Data(), 500) }),
                                       store: s, fallback: StubFallback(document: doc(version: 0)), clock: { now })
        XCTAssertEqual(try await repo2.current().version, 7)
    }

    func test_networkFails_servesStaleCache() async throws {
        var now = Date(timeIntervalSince1970: 0)
        let s = AppGroupStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!, clock: { now })
        // Seed cache via a successful fetch
        let okClient = RemoteScheduleClient(transport: { _ in (try! JSONEncoder.iso.encode(self.doc(version: 3)), 200) })
        _ = try await ScheduleRepository(client: okClient, store: s, fallback: StubFallback(document: doc(version: 0)), clock: { now }).current()
        // Advance past TTL, network now fails → stale cache (version 3) served
        now = Date(timeIntervalSince1970: ScheduleRepository.ttl + 10)
        let failRepo = ScheduleRepository(client: RemoteScheduleClient(transport: { _ in throw RemoteScheduleError.badStatus(500) }),
                                          store: s, fallback: StubFallback(document: doc(version: 99)), clock: { now })
        XCTAssertEqual(try await failRepo.current().version, 3)
    }

    func test_noCacheAndNetworkFails_usesBundleFallback() async throws {
        let now = Date(timeIntervalSince1970: 0)
        let s = store(now: now)
        let repo = ScheduleRepository(client: RemoteScheduleClient(transport: { _ in throw RemoteScheduleError.badStatus(500) }),
                                      store: s, fallback: StubFallback(document: doc(version: 42)), clock: { now })
        XCTAssertEqual(try await repo.current().version, 42)
    }
}

extension JSONEncoder {
    static var iso: JSONEncoder { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter ScheduleRepositoryTests`
Expected: FAIL — cannot find `ScheduleRepository`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public final class ScheduleRepository: @unchecked Sendable {
    public static let cacheKey = "cache.schedule.v1"
    /// Schedule changes day-to-day at most; 6h keeps it fresh without chasing.
    public static let ttl: TimeInterval = 6 * 3600

    private let client: RemoteScheduleClient
    private let store: AppGroupStore
    private let fallback: ScheduleProviding
    private let clock: @Sendable () -> Date

    public init(client: RemoteScheduleClient, store: AppGroupStore,
                fallback: ScheduleProviding, clock: @escaping @Sendable () -> Date = Date.init) {
        self.client = client
        self.store = store
        self.fallback = fallback
        self.clock = clock
    }

    public static func makeLive() -> ScheduleRepository {
        ScheduleRepository(client: .live(), store: .shared(), fallback: ScheduleFallback.production)
    }

    public func current() async throws -> ScheduleDocument {
        let now = clock()
        if let cached = store.readAllowingStale(ScheduleDocument.self, forKey: Self.cacheKey), !cached.isStale {
            return cached.value
        }
        do {
            let doc = try await client.fetch()
            try? store.write(doc, forKey: Self.cacheKey, ttl: Self.ttl)
            return doc
        } catch {
            if let stale = store.readAllowingStale(ScheduleDocument.self, forKey: Self.cacheKey) {
                return stale.value
            }
            return try fallback.load()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter ScheduleRepositoryTests`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/DataSource/ScheduleRepository.swift Core/Tests/UmaCoreTests/ScheduleRepositoryTests.swift
git commit -m "feat: add ScheduleRepository with TTL cache, stale + bundle fallback"
```

---

# Phase 3 — Phase resolution & card derivation

### Task 3.1: ScheduledEvent protocol (next-phase / status)

**Files:**
- Create: `Core/Sources/UmaCore/Logic/ScheduledEvent.swift`
- Test: `Core/Tests/UmaCoreTests/ScheduledEventTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class ScheduledEventTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
    private func cm() -> ChampionsMeeting {
        ChampionsMeeting(id: "x", name: "리브르", track: TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf),
            phases: [
                EventPhase(kind: .open,   label: "오픈",    date: d(100)),
                EventPhase(kind: .round1, label: "라운드1", date: d(200)),
                EventPhase(kind: .round2, label: "라운드2", date: d(300)),
                EventPhase(kind: .ended,  label: "종료",    date: d(400)),
            ])
    }

    func test_beforeOpen_nextPhaseIsOpen_statusUpcoming() {
        let r = cm().resolution(now: d(50))
        XCTAssertEqual(r.nextPhase?.kind, .open)
        XCTAssertEqual(r.status, .upcoming)
    }

    func test_betweenOpenAndRound1_nextPhaseIsRound1() {
        let r = cm().resolution(now: d(150))
        XCTAssertEqual(r.nextPhase?.kind, .round1)
        XCTAssertEqual(r.status, .active)   // event has started (past open) but not ended
    }

    func test_afterEnded_statusEnded_noNextPhase() {
        let r = cm().resolution(now: d(500))
        XCTAssertNil(r.nextPhase)
        XCTAssertEqual(r.status, .ended)
    }

    func test_targetDate_isNextPhaseDate_whenUpcoming() {
        XCTAssertEqual(cm().resolution(now: d(150)).targetDate, d(200))
    }

    func test_targetDate_isEndDate_whenNoUpcomingPhaseButNotEnded() {
        // between round2 (300) and ended (400): next phase is `ended` → target is end date
        XCTAssertEqual(cm().resolution(now: d(350)).targetDate, d(400))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter ScheduledEventTests`
Expected: FAIL — cannot find member `resolution`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

/// The result of evaluating a phased event at a moment in time.
public struct PhaseResolution: Equatable, Sendable {
    public let nextPhase: EventPhase?   // first phase with date > now (nil after the last)
    public let status: EventStatus
    public let targetDate: Date         // the date the d-day counts toward
}

/// Anything with an ordered `phases` array. Provides next-phase / status / target-date.
public protocol ScheduledEvent {
    var phases: [EventPhase] { get }
}

public extension ScheduledEvent {
    func resolution(now: Date) -> PhaseResolution {
        let sorted = phases.sorted { $0.date < $1.date }
        let next = sorted.first { $0.date > now }
        let firstStart = sorted.first?.date
        let endDate = sorted.last?.date

        let status: EventStatus
        if let end = endDate, now >= end {
            status = .ended
        } else if let start = firstStart, now >= start {
            status = .active
        } else {
            status = .upcoming
        }

        // Target the next upcoming phase; if none remain but not ended, target the end.
        let target = next?.date ?? endDate ?? now
        return PhaseResolution(nextPhase: next, status: status, targetDate: target)
    }
}

extension ChampionsMeeting: ScheduledEvent {}
extension LeagueOfHeroes: ScheduledEvent {}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter ScheduledEventTests`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Logic/ScheduledEvent.swift Core/Tests/UmaCoreTests/ScheduledEventTests.swift
git commit -m "feat: add ScheduledEvent phase resolution (next phase, status, target)"
```

### Task 3.2: CountdownFormatter (d-day) + phase-label strings

**Files:**
- Create: `Core/Sources/UmaCore/Logic/CountdownFormatter.swift`
- Test: `Core/Tests/UmaCoreTests/CountdownFormatterTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class CountdownFormatterTests: XCTestCase {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func d(_ s: String) -> Date {
        let f = ISO8601DateFormatter(); return f.date(from: s)!
    }

    func test_daysUntil_sameDay_isZero() {
        XCTAssertEqual(CountdownFormatter.daysUntil(d("2026-06-01T20:00:00Z"), from: d("2026-06-01T08:00:00Z"), calendar: cal), 0)
    }

    func test_daysUntil_nextDay_isOne() {
        XCTAssertEqual(CountdownFormatter.daysUntil(d("2026-06-02T01:00:00Z"), from: d("2026-06-01T23:00:00Z"), calendar: cal), 1)
    }

    func test_ddayLabel_today() {
        XCTAssertEqual(CountdownFormatter.ddayLabel(days: 0), "D-DAY")
    }

    func test_ddayLabel_future() {
        XCTAssertEqual(CountdownFormatter.ddayLabel(days: 5), "D-5")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter CountdownFormatterTests`
Expected: FAIL — cannot find `CountdownFormatter`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum CountdownFormatter {
    /// Whole calendar days between `origin` and `target` (start-of-day to start-of-day).
    public static func daysUntil(_ target: Date, from origin: Date, calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: origin)
        let b = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// "D-DAY" when 0, "D-n" otherwise. (Negative clamps to D-DAY.)
    public static func ddayLabel(days: Int) -> String {
        days <= 0 ? "D-DAY" : "D-\(days)"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter CountdownFormatterTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Logic/CountdownFormatter.swift Core/Tests/UmaCoreTests/CountdownFormatterTests.swift
git commit -m "feat: add CountdownFormatter for d-day labels"
```

### Task 3.3: EventCardFactory (events → EventCards)

**Files:**
- Create: `Core/Sources/UmaCore/Logic/EventCardFactory.swift`
- Test: `Core/Tests/UmaCoreTests/EventCardFactoryTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class EventCardFactoryTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }

    private func doc() -> ScheduleDocument {
        let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)
        let cm = ChampionsMeeting(id: "cm", name: "리브르", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(100)),
            EventPhase(kind: .round1, label: "라운드1", date: d(300)),
            EventPhase(kind: .ended, label: "종료", date: d(500)),
        ])
        let loh = LeagueOfHeroes(id: "loh", season: "시즌3", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(200)),
            EventPhase(kind: .ended, label: "종료", date: d(600)),
        ])
        let g1 = GachaBanner(id: "g1", type: .trainee, featured: ["오구리 캡"], startDate: d(150), endDate: d(450))
        return ScheduleDocument(version: 1, updatedAt: d(0), server: "kr",
                                championsMeetings: [cm], leagueOfHeroes: [loh], gachaBanners: [g1])
    }

    func test_championsCard_phaseLabelAndTarget() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(50))!
        XCTAssertEqual(card.category, .championsMeeting)
        XCTAssertEqual(card.title, "리브르")
        XCTAssertEqual(card.phaseLabel, "오픈까지")
        XCTAssertEqual(card.targetDate, d(100))
        XCTAssertEqual(card.status, .upcoming)
        XCTAssertEqual(card.track?.racecourse, "도쿄")
    }

    func test_endedChampions_isSkipped_returnsNilWhenAllEnded() {
        let card = EventCardFactory.championsCard(doc().championsMeetings, now: d(999))
        XCTAssertNil(card)
    }

    func test_majorAuto_picksNearerOfCMandLoH() {
        // now=50: CM open at 100, LoH open at 200 → CM nearer
        let card = EventCardFactory.majorCard(doc(), now: d(50))!
        XCTAssertEqual(card.category, .championsMeeting)
    }

    func test_gachaCard_activeBannerShowsEndCountdownLabel() {
        // now=200: g1 active (150..450) → phaseLabel "종료까지", target endDate
        let card = EventCardFactory.gachaCard(doc().gachaBanners, now: d(200))!
        XCTAssertEqual(card.category, .gacha)
        XCTAssertEqual(card.title, "오구리 캡")
        XCTAssertEqual(card.status, .active)
        XCTAssertEqual(card.phaseLabel, "종료까지")
        XCTAssertEqual(card.targetDate, d(450))
        XCTAssertNil(card.track)
    }

    func test_gachaCard_upcomingBannerShowsStartCountdown() {
        let card = EventCardFactory.gachaCard(doc().gachaBanners, now: d(100))!
        XCTAssertEqual(card.status, .upcoming)
        XCTAssertEqual(card.phaseLabel, "시작까지")
        XCTAssertEqual(card.targetDate, d(150))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter EventCardFactoryTests`
Expected: FAIL — cannot find `EventCardFactory`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum EventCardFactory {

    // MARK: Champions Meeting

    /// The soonest non-ended Champions Meeting as a card, or nil if all are ended/empty.
    public static func championsCard(_ meetings: [ChampionsMeeting], now: Date) -> EventCard? {
        let candidate = meetings
            .map { ($0, $0.resolution(now: now)) }
            .filter { $0.1.status != .ended }
            .sorted { $0.1.targetDate < $1.1.targetDate }
            .first
        guard let (cm, r) = candidate else { return nil }
        return EventCard(
            category: .championsMeeting,
            title: cm.name,
            track: cm.track,
            phaseLabel: phaseLabel(for: r),
            targetDate: r.targetDate,
            status: r.status
        )
    }

    // MARK: League of Heroes

    public static func leagueCard(_ leagues: [LeagueOfHeroes], now: Date) -> EventCard? {
        let candidate = leagues
            .map { ($0, $0.resolution(now: now)) }
            .filter { $0.1.status != .ended }
            .sorted { $0.1.targetDate < $1.1.targetDate }
            .first
        guard let (loh, r) = candidate else { return nil }
        return EventCard(
            category: .leagueOfHeroes,
            title: loh.season,
            track: loh.track,
            phaseLabel: phaseLabel(for: r),
            targetDate: r.targetDate,
            status: r.status
        )
    }

    // MARK: Gacha

    /// Active banner (now within start..end) preferred; else the soonest upcoming.
    public static func gachaCard(_ banners: [GachaBanner], now: Date) -> EventCard? {
        let active = banners
            .filter { now >= $0.startDate && now < $0.endDate }
            .sorted { $0.endDate < $1.endDate }
            .first
        if let b = active {
            return EventCard(category: .gacha, title: b.featured.joined(separator: ", "),
                             track: nil, phaseLabel: "종료까지", targetDate: b.endDate, status: .active)
        }
        let upcoming = banners
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first
        if let b = upcoming {
            return EventCard(category: .gacha, title: b.featured.joined(separator: ", "),
                             track: nil, phaseLabel: "시작까지", targetDate: b.startDate, status: .upcoming)
        }
        return nil
    }

    // MARK: Major auto (CM + LoH, nearer target wins; gacha excluded)

    public static func majorCard(_ doc: ScheduleDocument, now: Date) -> EventCard? {
        [championsCard(doc.championsMeetings, now: now), leagueCard(doc.leagueOfHeroes, now: now)]
            .compactMap { $0 }
            .min { $0.targetDate < $1.targetDate }
    }

    // MARK: Helpers

    /// Phase label like "오픈까지" / "라운드1까지" / "진행중". Uses the next phase's label,
    /// or "진행중" when the only thing left is the implicit end.
    private static func phaseLabel(for r: PhaseResolution) -> String {
        if let next = r.nextPhase, next.kind != .ended {
            return "\(next.label)까지"
        }
        return r.status == .active ? "진행중" : "종료까지"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter EventCardFactoryTests`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Logic/EventCardFactory.swift Core/Tests/UmaCoreTests/EventCardFactoryTests.swift
git commit -m "feat: add EventCardFactory deriving cards from schedule events"
```

---

# Phase 4 — Widget state resolver

### Task 4.1: WidgetVariant + DetailLevel mapping

**Files:**
- Create: `Core/Sources/UmaCore/Widgets/WidgetVariant.swift`
- Test: `Core/Tests/UmaCoreTests/WidgetVariantTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class WidgetVariantTests: XCTestCase {
    func test_categoriesForVariant() {
        XCTAssertEqual(WidgetVariant.championsOnly.categories, [.championsMeeting])
        XCTAssertEqual(WidgetVariant.loHOnly.categories, [.leagueOfHeroes])
        XCTAssertEqual(WidgetVariant.pickupOnly.categories, [.gacha])
        XCTAssertEqual(WidgetVariant.championsLoH.categories, [.championsMeeting, .leagueOfHeroes])
        XCTAssertEqual(WidgetVariant.allSchedule.categories, [.championsMeeting, .leagueOfHeroes, .gacha])
    }

    func test_majorAutoVariantIsAutoSelect() {
        XCTAssertTrue(WidgetVariant.majorAuto.isMajorAuto)
        XCTAssertFalse(WidgetVariant.championsLoH.isMajorAuto)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter WidgetVariantTests`
Expected: FAIL — cannot find `WidgetVariant`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum WidgetVariant: String, Codable, Sendable {
    case majorAuto      // 챔미·LoH 중 임박 자동 전환 (L1/M1/S1, lock)
    case allSchedule    // 챔미+LoH+픽업 전체 (L2)
    case championsLoH   // 챔미+LoH 동시 (M2)
    case championsOnly  // 챔미만 (S2)
    case loHOnly        // LoH만 (S3)
    case pickupOnly     // 픽업만 (M3/S4)

    /// `true` for variants that auto-pick the nearer of CM/LoH instead of listing fixed categories.
    public var isMajorAuto: Bool { self == .majorAuto }

    /// Fixed category set for non-auto variants (used to assemble cards in order).
    public var categories: [EventCategory] {
        switch self {
        case .majorAuto:     return [.championsMeeting, .leagueOfHeroes]
        case .allSchedule:   return [.championsMeeting, .leagueOfHeroes, .gacha]
        case .championsLoH:  return [.championsMeeting, .leagueOfHeroes]
        case .championsOnly: return [.championsMeeting]
        case .loHOnly:       return [.leagueOfHeroes]
        case .pickupOnly:    return [.gacha]
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter WidgetVariantTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Widgets/WidgetVariant.swift Core/Tests/UmaCoreTests/WidgetVariantTests.swift
git commit -m "feat: add WidgetVariant with category mapping"
```

### Task 4.2: WidgetEntry + WidgetState

**Files:**
- Create: `Core/Sources/UmaCore/Widgets/WidgetEntry.swift`
- Test: `Core/Tests/UmaCoreTests/WidgetEntryTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import WidgetKit
@testable import UmaCore

final class WidgetEntryTests: XCTestCase {
    func test_roundTrip_contentState() throws {
        let card = EventCard(category: .gacha, title: "오구리 캡", track: nil,
                             phaseLabel: "종료까지", targetDate: Date(timeIntervalSince1970: 10), status: .active)
        let entry = WidgetEntry(date: Date(timeIntervalSince1970: 0), state: .content([card]),
                                detailLevel: .brief, fontTheme: .mono)
        let data = try JSONEncoder().encode(entry)
        XCTAssertEqual(try JSONDecoder().decode(WidgetEntry.self, from: data), entry)
    }

    func test_decode_missingDetailLevelDefaultsOverview() throws {
        let json = #"{"date":0,"state":{"idle":{}},"fontTheme":"system"}"#.data(using: .utf8)!
        // Robust against older encodings without detailLevel.
        let entry = try JSONDecoder().decode(WidgetEntry.self, from: json)
        XCTAssertEqual(entry.detailLevel, .overview)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter WidgetEntryTests`
Expected: FAIL — cannot find `WidgetEntry`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation
import WidgetKit

public enum WidgetState: Codable, Hashable, Sendable {
    case content([EventCard])   // variant/사이즈에 맞는 1~3개 카드
    case idle                   // 예정 이벤트 없음
    case noData                 // 원격/번들 모두 실패
}

public struct WidgetEntry: TimelineEntry, Codable, Hashable, Sendable {
    public let date: Date
    public let state: WidgetState
    public let detailLevel: DetailLevel
    public let fontTheme: FontTheme

    public init(date: Date, state: WidgetState, detailLevel: DetailLevel = .overview, fontTheme: FontTheme = .system) {
        self.date = date
        self.state = state
        self.detailLevel = detailLevel
        self.fontTheme = fontTheme
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try c.decode(Date.self, forKey: .date)
        self.state = try c.decode(WidgetState.self, forKey: .state)
        self.detailLevel = try c.decodeIfPresent(DetailLevel.self, forKey: .detailLevel) ?? .overview
        self.fontTheme = try c.decodeIfPresent(FontTheme.self, forKey: .fontTheme) ?? .system
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter WidgetEntryTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Widgets/WidgetEntry.swift Core/Tests/UmaCoreTests/WidgetEntryTests.swift
git commit -m "feat: add WidgetEntry + WidgetState"
```

### Task 4.3: ScheduleStateResolver

**Files:**
- Create: `Core/Sources/UmaCore/Widgets/ScheduleStateResolver.swift`
- Test: `Core/Tests/UmaCoreTests/ScheduleStateResolverTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class ScheduleStateResolverTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
    private func doc() -> ScheduleDocument {
        let track = TrackCondition(racecourse: "도쿄", distanceMeters: 2400, surface: .turf)
        let cm = ChampionsMeeting(id: "cm", name: "리브르", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(100)),
            EventPhase(kind: .ended, label: "종료", date: d(500)),
        ])
        let loh = LeagueOfHeroes(id: "loh", season: "시즌3", track: track, phases: [
            EventPhase(kind: .open, label: "오픈", date: d(200)),
            EventPhase(kind: .ended, label: "종료", date: d(600)),
        ])
        let g = GachaBanner(id: "g", type: .trainee, featured: ["오구리 캡"], startDate: d(150), endDate: d(450))
        return ScheduleDocument(version: 1, updatedAt: d(0), server: "kr",
                                championsMeetings: [cm], leagueOfHeroes: [loh], gachaBanners: [g])
    }

    func test_majorAuto_returnsSingleNearerCard() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .majorAuto, now: d(50))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.category, .championsMeeting)
    }

    func test_allSchedule_returnsThreeCardsInOrder() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .allSchedule, now: d(50))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.map(\.category), [.championsMeeting, .leagueOfHeroes, .gacha])
    }

    func test_pickupOnly_returnsGachaCard() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .pickupOnly, now: d(200))
        guard case let .content(cards) = state else { return XCTFail("expected content") }
        XCTAssertEqual(cards.map(\.category), [.gacha])
    }

    func test_noEventsLeft_returnsIdle() {
        let state = ScheduleStateResolver.resolve(document: doc(), variant: .allSchedule, now: d(9999))
        XCTAssertEqual(state, .idle)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter ScheduleStateResolverTests`
Expected: FAIL — cannot find `ScheduleStateResolver`.

- [ ] **Step 3: Write the implementation**

```swift
import Foundation

public enum ScheduleStateResolver {

    /// Build the widget state for a variant from the schedule document at `now`.
    public static func resolve(document: ScheduleDocument, variant: WidgetVariant, now: Date) -> WidgetState {
        let cards: [EventCard]
        if variant.isMajorAuto {
            cards = [EventCardFactory.majorCard(document, now: now)].compactMap { $0 }
        } else {
            cards = variant.categories.compactMap { card(for: $0, document: document, now: now) }
        }
        return cards.isEmpty ? .idle : .content(cards)
    }

    private static func card(for category: EventCategory, document: ScheduleDocument, now: Date) -> EventCard? {
        switch category {
        case .championsMeeting: return EventCardFactory.championsCard(document.championsMeetings, now: now)
        case .leagueOfHeroes:   return EventCardFactory.leagueCard(document.leagueOfHeroes, now: now)
        case .gacha:            return EventCardFactory.gachaCard(document.gachaBanners, now: now)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter ScheduleStateResolverTests`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/Widgets/ScheduleStateResolver.swift Core/Tests/UmaCoreTests/ScheduleStateResolverTests.swift
git commit -m "feat: add ScheduleStateResolver mapping variant+doc to state"
```

---

# Phase 5 — Localization

### Task 5.1: L.swift + Bundle+UmaCore

**Files:**
- Create: `Core/Sources/UmaCore/Localization/L.swift`
- Create: `Core/Sources/UmaCore/Localization/Bundle+UmaCore.swift`
- Test: `Core/Tests/UmaCoreTests/LocalizationTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class LocalizationTests: XCTestCase {
    func test_everyKeyHasKoAndEnValue() {
        for key in L.Key.allCases {
            let ko = L.string(key, locale: Locale(identifier: "ko"))
            let en = L.string(key, locale: Locale(identifier: "en"))
            XCTAssertNotEqual(ko, key.rawValue, "missing ko for \(key.rawValue)")
            XCTAssertNotEqual(en, key.rawValue, "missing en for \(key.rawValue)")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter LocalizationTests`
Expected: FAIL — cannot find `L`.

- [ ] **Step 3: Write `Bundle+UmaCore.swift`**

```swift
import Foundation

public extension Bundle {
    /// The UmaCore SPM resource bundle, exposed for app + widget targets (e.g. widget
    /// gallery `.configurationDisplayName`/`.description` localized via the SYSTEM locale).
    static let umaCore: Bundle = .module
}
```

- [ ] **Step 4: Write `L.swift`** (keys cover settings, widget gallery, states, categories)

```swift
import Foundation

public enum L {
    nonisolated(unsafe) public static var currentLocale: Locale? = nil

    public enum Key: String, CaseIterable, Sendable {
        // Categories
        case categoryChampions = "category.champions"
        case categoryLoH       = "category.loh"
        case categoryPickup    = "category.pickup"

        // Widget states
        case stateIdleTitle   = "state.idle.title"
        case stateIdleBody    = "state.idle.body"
        case stateNoDataTitle = "state.nodata.title"
        case stateNoDataBody  = "state.nodata.body"

        // Pickup labels
        case pickupTrainee     = "pickup.trainee"
        case pickupSupportCard = "pickup.support_card"

        // Settings
        case settingsTitle              = "settings.title"
        case settingsSectionCategories  = "settings.section.categories"
        case settingsSectionFont        = "settings.section.font"
        case settingsSectionLanguage    = "settings.section.language"
        case settingsSectionNotify      = "settings.section.notify"
        case settingsRowNotifyBefore    = "settings.row.notify_before"
        case settingsValueFontSystem    = "settings.value.font.system"
        case settingsValueFontRounded   = "settings.value.font.rounded"
        case settingsValueFontMono      = "settings.value.font.mono"
        case settingsValueFontSerif     = "settings.value.font.serif"
        case settingsValueLanguageSystem = "settings.value.language.system"
        case settingsValueLanguageKo    = "settings.value.language.ko"
        case settingsValueLanguageEn    = "settings.value.language.en"
        case settingsRowDataSource      = "settings.row.data_source"
        case settingsRowRefresh         = "settings.row.refresh"

        // Legal
        case legalDisclaimer = "legal.disclaimer"

        // Widget gallery (per widget)
        case galleryL1Title = "gallery.l1.title"
        case galleryL1Desc  = "gallery.l1.desc"
        case galleryL2Title = "gallery.l2.title"
        case galleryL2Desc  = "gallery.l2.desc"
        case galleryM1Title = "gallery.m1.title"
        case galleryM1Desc  = "gallery.m1.desc"
        case galleryM2Title = "gallery.m2.title"
        case galleryM2Desc  = "gallery.m2.desc"
        case galleryM3Title = "gallery.m3.title"
        case galleryM3Desc  = "gallery.m3.desc"
        case galleryS1Title = "gallery.s1.title"
        case galleryS1Desc  = "gallery.s1.desc"
        case galleryS2Title = "gallery.s2.title"
        case galleryS2Desc  = "gallery.s2.desc"
        case galleryS3Title = "gallery.s3.title"
        case galleryS3Desc  = "gallery.s3.desc"
        case galleryS4Title = "gallery.s4.title"
        case galleryS4Desc  = "gallery.s4.desc"
        case galleryLockRectTitle = "gallery.lock_rect.title"
        case galleryLockRectDesc  = "gallery.lock_rect.desc"
        case galleryLockCircTitle = "gallery.lock_circ.title"
        case galleryLockCircDesc  = "gallery.lock_circ.desc"
    }

    public static func string(_ key: Key, locale: Locale? = nil) -> String {
        let effective = locale ?? currentLocale
        let bundle = Bundle.module
        if let effective, let lprojPath = bundle.path(forResource: effective.languageCode ?? "en", ofType: "lproj"),
           let localized = Bundle(path: lprojPath) {
            return NSLocalizedString(key.rawValue, tableName: nil, bundle: localized, value: key.rawValue, comment: "")
        }
        return NSLocalizedString(key.rawValue, tableName: nil, bundle: bundle, value: key.rawValue, comment: "")
    }
}
```

- [ ] **Step 5: Run test to verify it fails for a new reason**

Run: `cd Core && swift test --filter LocalizationTests`
Expected: FAIL — strings files don't exist yet (every key returns its rawValue). This drives Task 5.2.

- [ ] **Step 6: Commit (code only; strings land in 5.2)**

```bash
git add Core/Sources/UmaCore/Localization/L.swift Core/Sources/UmaCore/Localization/Bundle+UmaCore.swift Core/Tests/UmaCoreTests/LocalizationTests.swift
git commit -m "feat: add L localization key enum + resolver (strings follow)"
```

### Task 5.2: Localizable.strings (ko + en)

**Files:**
- Create: `Core/Sources/UmaCore/Resources/ko.lproj/Localizable.strings`
- Create: `Core/Sources/UmaCore/Resources/en.lproj/Localizable.strings`

- [ ] **Step 1: Write `ko.lproj/Localizable.strings`**

```
"category.champions" = "챔피언스 미팅";
"category.loh" = "리그 오브 히어로즈";
"category.pickup" = "픽업";

"state.idle.title" = "예정된 일정 없음";
"state.idle.body" = "새 일정이 등록되면 표시됩니다";
"state.nodata.title" = "일정을 불러올 수 없어요";
"state.nodata.body" = "잠시 후 다시 시도해주세요";

"pickup.trainee" = "육성마";
"pickup.support_card" = "서포트카드";

"settings.title" = "설정";
"settings.section.categories" = "표시 카테고리";
"settings.section.font" = "글꼴";
"settings.section.language" = "언어";
"settings.section.notify" = "알림";
"settings.row.notify_before" = "단계 시작 전 알림";
"settings.value.font.system" = "시스템";
"settings.value.font.rounded" = "둥근";
"settings.value.font.mono" = "모노";
"settings.value.font.serif" = "세리프";
"settings.value.language.system" = "시스템";
"settings.value.language.ko" = "한국어";
"settings.value.language.en" = "English";
"settings.row.data_source" = "데이터 출처";
"settings.row.refresh" = "지금 새로고침";

"legal.disclaimer" = "본 앱은 비공식 일정 안내 앱이며 카카오게임즈/Cygames와 무관합니다.";

"gallery.l1.title" = "주요 이벤트 (상세)";
"gallery.l1.desc" = "다음 챔피언스 미팅·리그 오브 히어로즈를 마장 이미지와 함께 상세히";
"gallery.l2.title" = "전체 일정";
"gallery.l2.desc" = "챔피언스 미팅·리그 오브 히어로즈·픽업 다음 일정 전부";
"gallery.m1.title" = "주요 이벤트 (간략)";
"gallery.m1.desc" = "다음 챔피언스 미팅·리그 오브 히어로즈를 간략히";
"gallery.m2.title" = "챔미 + LoH";
"gallery.m2.desc" = "챔피언스 미팅과 리그 오브 히어로즈 다음 일정 동시 표시";
"gallery.m3.title" = "픽업";
"gallery.m3.desc" = "다음 육성마·서포트카드 픽업 일정";
"gallery.s1.title" = "주요 이벤트 (개요)";
"gallery.s1.desc" = "다음 챔미·LoH 중 가장 임박한 일정";
"gallery.s2.title" = "챔피언스 미팅";
"gallery.s2.desc" = "다음 챔피언스 미팅 일정만";
"gallery.s3.title" = "리그 오브 히어로즈";
"gallery.s3.desc" = "다음 리그 오브 히어로즈 일정만";
"gallery.s4.title" = "픽업";
"gallery.s4.desc" = "다음 픽업 일정만";
"gallery.lock_rect.title" = "다음 일정";
"gallery.lock_rect.desc" = "가장 임박한 이벤트를 잠금화면에";
"gallery.lock_circ.title" = "D-day";
"gallery.lock_circ.desc" = "다음 이벤트까지 남은 일수";
```

- [ ] **Step 2: Write `en.lproj/Localizable.strings`**

```
"category.champions" = "Champions Meeting";
"category.loh" = "League of Heroes";
"category.pickup" = "Pickup";

"state.idle.title" = "No upcoming events";
"state.idle.body" = "New schedules will appear here";
"state.nodata.title" = "Couldn't load schedule";
"state.nodata.body" = "Please try again shortly";

"pickup.trainee" = "Trainee";
"pickup.support_card" = "Support Card";

"settings.title" = "Settings";
"settings.section.categories" = "Categories";
"settings.section.font" = "Font";
"settings.section.language" = "Language";
"settings.section.notify" = "Notifications";
"settings.row.notify_before" = "Notify before phase starts";
"settings.value.font.system" = "System";
"settings.value.font.rounded" = "Rounded";
"settings.value.font.mono" = "Mono";
"settings.value.font.serif" = "Serif";
"settings.value.language.system" = "System";
"settings.value.language.ko" = "한국어";
"settings.value.language.en" = "English";
"settings.row.data_source" = "Data source";
"settings.row.refresh" = "Refresh now";

"legal.disclaimer" = "Unofficial schedule app. Not affiliated with Kakao Games / Cygames.";

"gallery.l1.title" = "Major Event (Detailed)";
"gallery.l1.desc" = "Next Champions Meeting / League of Heroes with track image";
"gallery.l2.title" = "Full Schedule";
"gallery.l2.desc" = "Next Champions Meeting, League of Heroes and pickup";
"gallery.m1.title" = "Major Event (Brief)";
"gallery.m1.desc" = "Next Champions Meeting / League of Heroes, brief";
"gallery.m2.title" = "CM + LoH";
"gallery.m2.desc" = "Next Champions Meeting and League of Heroes together";
"gallery.m3.title" = "Pickup";
"gallery.m3.desc" = "Next trainee / support card pickup";
"gallery.s1.title" = "Major Event (Overview)";
"gallery.s1.desc" = "Nearest of Champions Meeting / League of Heroes";
"gallery.s2.title" = "Champions Meeting";
"gallery.s2.desc" = "Next Champions Meeting only";
"gallery.s3.title" = "League of Heroes";
"gallery.s3.desc" = "Next League of Heroes only";
"gallery.s4.title" = "Pickup";
"gallery.s4.desc" = "Next pickup only";
"gallery.lock_rect.title" = "Next Event";
"gallery.lock_rect.desc" = "Most imminent event on your lock screen";
"gallery.lock_circ.title" = "D-day";
"gallery.lock_circ.desc" = "Days until the next event";
```

- [ ] **Step 3: Run the localization test to verify it now passes**

Run: `cd Core && swift test --filter LocalizationTests`
Expected: PASS — every key resolves in both ko and en.

- [ ] **Step 4: Commit**

```bash
git add Core/Sources/UmaCore/Resources/ko.lproj/Localizable.strings Core/Sources/UmaCore/Resources/en.lproj/Localizable.strings
git commit -m "feat: add ko/en Localizable.strings"
```

---

# Phase 6 — Design system & track image

### Task 6.1: Typography + Color+Hex (copied)

**Files:**
- Create: `Core/Sources/UmaCore/DesignSystem/Typography.swift`
- Create: `Core/Sources/UmaCore/DesignSystem/Color+Hex.swift`
- Test: `Core/Tests/UmaCoreTests/ColorHexTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftUI
@testable import UmaCore

final class ColorHexTests: XCTestCase {
    func test_parsesSixDigitHex() {
        XCTAssertNotNil(Color(hex: "#1E88E5"))
        XCTAssertNotNil(Color(hex: "1E88E5"))
    }
    func test_invalidHexReturnsNil() {
        XCTAssertNil(Color(hex: "xyz"))
    }
    func test_fontDesignMapping() {
        XCTAssertEqual(Typography.fontDesign(for: .mono), .monospaced)
        XCTAssertEqual(Typography.fontDesign(for: .serif), .serif)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter ColorHexTests`
Expected: FAIL — cannot find `Color(hex:)` / `Typography`.

- [ ] **Step 3: Write `Typography.swift`** (adapted copy of `../lckwidget/.../DesignSystem/Typography.swift`)

```swift
import SwiftUI

public enum Typography {
    public enum Token: CaseIterable, Hashable, Sendable {
        case title, headline, body, caption, monoCaption
    }

    nonisolated(unsafe) public static var currentTheme: FontTheme = .system

    public static func font(for token: Token, theme: FontTheme? = nil) -> Font {
        let design = fontDesign(for: theme ?? currentTheme)
        switch token {
        case .title:       return .system(size: 28, weight: .bold,     design: design)
        case .headline:    return .system(size: 17, weight: .semibold, design: design)
        case .body:        return .system(size: 15, weight: .regular,  design: design)
        case .caption:     return .system(size: 12, weight: .medium,   design: design)
        case .monoCaption: return .system(size: 11, weight: .semibold, design: .monospaced)
        }
    }

    public static func systemFont(size: CGFloat, weight: Font.Weight = .regular, theme: FontTheme? = nil) -> Font {
        .system(size: size, weight: weight, design: fontDesign(for: theme ?? currentTheme))
    }

    public static func fontDesign(for theme: FontTheme) -> Font.Design {
        switch theme {
        case .system:  return .default
        case .rounded: return .rounded
        case .mono:    return .monospaced
        case .serif:   return .serif
        }
    }
}

public extension View {
    func font(_ token: Typography.Token) -> some View { self.font(Typography.font(for: token)) }
}
```

- [ ] **Step 4: Write `Color+Hex.swift`**

```swift
import SwiftUI

public extension Color {
    /// Parse "#RRGGBB" or "RRGGBB". Returns nil for malformed input.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255,
                  opacity: 1)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd Core && swift test --filter ColorHexTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Core/Sources/UmaCore/DesignSystem/Typography.swift Core/Sources/UmaCore/DesignSystem/Color+Hex.swift Core/Tests/UmaCoreTests/ColorHexTests.swift
git commit -m "feat: add Typography + Color hex parsing"
```

### Task 6.2: CategoryBadge (icon + color + label)

**Files:**
- Create: `Core/Sources/UmaCore/DesignSystem/CategoryBadge.swift`
- Test: `Core/Tests/UmaCoreTests/CategoryStyleTests.swift`

- [ ] **Step 1: Write the failing test** (test the pure style mapping; the View itself is build-verified)

```swift
import XCTest
@testable import UmaCore

final class CategoryStyleTests: XCTestCase {
    func test_sfSymbolPerCategory() {
        XCTAssertEqual(EventCategory.championsMeeting.sfSymbol, "trophy.fill")
        XCTAssertEqual(EventCategory.leagueOfHeroes.sfSymbol, "flag.checkered.2.crossed")
        XCTAssertEqual(EventCategory.gacha.sfSymbol, "sparkles")
    }
    func test_localizedLabelKey() {
        XCTAssertEqual(EventCategory.championsMeeting.labelKey, .categoryChampions)
        XCTAssertEqual(EventCategory.gacha.labelKey, .categoryPickup)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter CategoryStyleTests`
Expected: FAIL — no member `sfSymbol`.

- [ ] **Step 3: Write the implementation**

```swift
import SwiftUI

public extension EventCategory {
    var sfSymbol: String {
        switch self {
        case .championsMeeting: return "trophy.fill"
        case .leagueOfHeroes:   return "flag.checkered.2.crossed"
        case .gacha:            return "sparkles"
        }
    }
    var accentHex: String {
        switch self {
        case .championsMeeting: return "#E8B923"  // gold
        case .leagueOfHeroes:   return "#3F8EFC"  // blue
        case .gacha:            return "#E0567A"  // pink
        }
    }
    var labelKey: L.Key {
        switch self {
        case .championsMeeting: return .categoryChampions
        case .leagueOfHeroes:   return .categoryLoH
        case .gacha:            return .categoryPickup
        }
    }
    var accentColor: Color { Color(hex: accentHex) ?? .accentColor }
}

/// Small pill: category icon + localized name.
public struct CategoryBadge: View {
    public let category: EventCategory
    public init(category: EventCategory) { self.category = category }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.sfSymbol).font(.system(size: 10, weight: .bold))
            Text(L.string(category.labelKey)).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(category.accentColor)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter CategoryStyleTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/DesignSystem/CategoryBadge.swift Core/Tests/UmaCoreTests/CategoryStyleTests.swift
git commit -m "feat: add category style mapping + CategoryBadge view"
```

### Task 6.3: CourseDiagramView (fallback track art)

**Files:**
- Create: `Core/Sources/UmaCore/DesignSystem/CourseDiagramView.swift`

> Views aren't unit-tested; verify via build + Xcode preview. Pure helpers below are tested.

- [ ] **Step 1: Write the failing test** (for the surface→color helper used by the diagram)

```swift
import XCTest
import SwiftUI
@testable import UmaCore

final class SurfaceStyleTests: XCTestCase {
    func test_surfaceTrackColorHex() {
        XCTAssertEqual(Surface.turf.trackHex, "#3FA56B")
        XCTAssertEqual(Surface.dirt.trackHex, "#9C6B3F")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter SurfaceStyleTests`
Expected: FAIL — no member `trackHex`.

- [ ] **Step 3: Write the implementation**

```swift
import SwiftUI

public extension Surface {
    /// Diagram track fill color. Turf = green, dirt = brown.
    var trackHex: String {
        switch self {
        case .turf: return "#3FA56B"
        case .dirt: return "#9C6B3F"
        }
    }
    var trackColor: Color { Color(hex: trackHex) ?? .gray }
}

/// Lightweight self-drawn oval course used when no remote track image is available.
/// Renders a colored oval (surface) with distance + direction overlaid.
public struct CourseDiagramView: View {
    public let track: TrackCondition
    public init(track: TrackCondition) { self.track = track }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(track.surface.trackColor.opacity(0.18))
            Ellipse()
                .stroke(track.surface.trackColor, lineWidth: 6)
                .padding(14)
            VStack(spacing: 2) {
                Text("\(track.distanceMeters)m")
                    .font(.system(size: 18, weight: .bold))
                if let dir = track.direction {
                    Text(dir).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter SurfaceStyleTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Core/Sources/UmaCore/DesignSystem/CourseDiagramView.swift Core/Tests/UmaCoreTests/SurfaceStyleTests.swift
git commit -m "feat: add CourseDiagramView fallback + surface colors"
```

### Task 6.4: TrackImageCache + TrackImageView

**Files:**
- Create: `Core/Sources/UmaCore/Cache/TrackImageCache.swift`
- Create: `Core/Sources/UmaCore/DesignSystem/TrackImageView.swift`
- Test: `Core/Tests/UmaCoreTests/TrackImageCacheTests.swift`

- [ ] **Step 1: Write the failing test** (cache path derivation + read/write round trip)

```swift
import XCTest
@testable import UmaCore

final class TrackImageCacheTests: XCTestCase {
    func test_fileName_isStableHashOfURL() {
        let url = URL(string: "https://x/tokyo.png")!
        XCTAssertEqual(TrackImageCache.fileName(for: url), TrackImageCache.fileName(for: url))
        XCTAssertFalse(TrackImageCache.fileName(for: url).isEmpty)
    }

    func test_storeAndLoadData() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let cache = TrackImageCache(directory: dir)
        let url = URL(string: "https://x/tokyo.png")!
        let bytes = Data([1, 2, 3, 4])
        try cache.store(bytes, for: url)
        XCTAssertEqual(cache.data(for: url), bytes)
        XCTAssertNil(cache.data(for: URL(string: "https://x/other.png")!))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter TrackImageCacheTests`
Expected: FAIL — cannot find `TrackImageCache`.

- [ ] **Step 3: Write `TrackImageCache.swift`**

```swift
import Foundation
import CryptoKit

/// File cache for remote track images, living in the App Group container so both the app
/// (which downloads) and the widget (which reads) can access it. WidgetKit views load the
/// bytes synchronously from disk — no async image loading in widget bodies.
public struct TrackImageCache: Sendable {
    private let directory: URL
    private let fm = FileManager.default

    public init(directory: URL) { self.directory = directory }

    /// Shared instance rooted in the App Group container's `track-images/` folder.
    public static func shared() -> TrackImageCache {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupStore.suiteName)
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("track-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return TrackImageCache(directory: dir)
    }

    public static func fileName(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex + "." + (url.pathExtension.isEmpty ? "img" : url.pathExtension)
    }

    private func fileURL(for url: URL) -> URL { directory.appendingPathComponent(Self.fileName(for: url)) }

    public func data(for url: URL) -> Data? { try? Data(contentsOf: fileURL(for: url)) }

    public func store(_ data: Data, for url: URL) throws { try data.write(to: fileURL(for: url)) }

    /// Download + cache if not already present. Safe to call from the app or a TimelineProvider.
    public func ensureCached(_ url: URL, transport: @Sendable (URL) async throws -> Data) async {
        guard data(for: url) == nil else { return }
        if let bytes = try? await transport(url) { try? store(bytes, for: url) }
    }
}
```

- [ ] **Step 4: Write `TrackImageView.swift`**

```swift
import SwiftUI

/// Renders the cached remote track image if present, otherwise the self-drawn course diagram.
/// Reads cache synchronously (WidgetKit-safe).
public struct TrackImageView: View {
    public let track: TrackCondition
    private let cache: TrackImageCache

    public init(track: TrackCondition, cache: TrackImageCache = .shared()) {
        self.track = track
        self.cache = cache
    }

    public var body: some View {
        if let url = track.imageURL, let data = cache.data(for: url), let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            CourseDiagramView(track: track)
        }
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd Core && swift test --filter TrackImageCacheTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Core/Sources/UmaCore/Cache/TrackImageCache.swift Core/Sources/UmaCore/DesignSystem/TrackImageView.swift Core/Tests/UmaCoreTests/TrackImageCacheTests.swift
git commit -m "feat: add TrackImageCache (App Group file cache) + TrackImageView"
```

---

# Phase 7 — Widget views (SwiftUI)

> These render `WidgetEntry`. They are verified by `cd Core && swift build` (compiles for the package's macOS/iOS surface) and visually in Xcode previews after Task 8.5. Each view exposes an `init(entry:)` and switches on `entry.state`.

### Task 7.1: Shared card pieces (DDayBadge, EventCardRow)

**Files:**
- Create: `Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift`

- [ ] **Step 1: Write the views**

```swift
import SwiftUI
import WidgetKit

/// Big "D-5" / "D-DAY" label, themed.
public struct DDayBadge: View {
    public let targetDate: Date
    public let now: Date
    public init(targetDate: Date, now: Date) { self.targetDate = targetDate; self.now = now }
    public var body: some View {
        let days = CountdownFormatter.daysUntil(targetDate, from: now)
        Text(CountdownFormatter.ddayLabel(days: days))
            .font(Typography.systemFont(size: 20, weight: .heavy))
    }
}

/// One compact row: category badge, title, phase label, d-day. Used in multi-card widgets.
public struct EventCardRow: View {
    public let card: EventCard
    public let now: Date
    public init(card: EventCard, now: Date) { self.card = card; self.now = now }

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                CategoryBadge(category: card.category)
                Text(card.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                if let track = card.track {
                    Text(track.summary).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                DDayBadge(targetDate: card.targetDate, now: now)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }
}

/// Centered placeholder for idle / noData states.
public struct WidgetMessageView: View {
    public let titleKey: L.Key
    public let bodyKey: L.Key
    public init(titleKey: L.Key, bodyKey: L.Key) { self.titleKey = titleKey; self.bodyKey = bodyKey }
    public var body: some View {
        VStack(spacing: 4) {
            Text(L.string(titleKey)).font(.system(size: 14, weight: .semibold))
            Text(L.string(bodyKey)).font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 2: Verify the package builds**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift
git commit -m "feat: add shared widget pieces (DDayBadge, EventCardRow, message view)"
```

### Task 7.2: Small views (overview / single category)

**Files:**
- Create: `Core/Sources/UmaCore/UI/Widget/SmallWidgetView.swift`

- [ ] **Step 1: Write the view**

```swift
import SwiftUI
import WidgetKit

/// systemSmall renderer. Shows the first card (overview): badge, title, d-day, phase.
/// Used by S1 (majorAuto), S2 (champions), S3 (loH), S4 (pickup) — variant only changes
/// which card the resolver placed in `entry.state`.
public struct SmallWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if let card = cards.first { single(card) } else { empty }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    private var empty: some View { WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody) }

    private func single(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CategoryBadge(category: card.category)
            Text(card.title).font(.system(size: 16, weight: .bold)).lineLimit(2)
            Spacer(minLength: 0)
            DDayBadge(targetDate: card.targetDate, now: entry.date)
            Text(card.phaseLabel).font(.system(size: 11)).foregroundStyle(.secondary)
            if let track = card.track {
                Text(track.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 2: Verify the package builds**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Core/Sources/UmaCore/UI/Widget/SmallWidgetView.swift
git commit -m "feat: add SmallWidgetView (overview / single-category)"
```

### Task 7.3: Medium views (brief auto / dual / pickup)

**Files:**
- Create: `Core/Sources/UmaCore/UI/Widget/MediumWidgetView.swift`

- [ ] **Step 1: Write the view**

```swift
import SwiftUI
import WidgetKit

/// systemMedium renderer. Shows up to two cards as stacked rows (brief detail).
/// Used by M1 (majorAuto, 1 card), M2 (championsLoH, 2 cards), M3 (pickupOnly, 1 card).
public struct MediumWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(cards.prefix(2).enumerated()), id: \.offset) { _, card in
                        EventCardRow(card: card, now: entry.date)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }
}
```

- [ ] **Step 2: Verify the package builds**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Core/Sources/UmaCore/UI/Widget/MediumWidgetView.swift
git commit -m "feat: add MediumWidgetView (brief auto / dual / pickup)"
```

### Task 7.4: Large views (detailed major / all-schedule)

**Files:**
- Create: `Core/Sources/UmaCore/UI/Widget/LargeWidgetView.swift`

- [ ] **Step 1: Write the view**

```swift
import SwiftUI
import WidgetKit

/// systemLarge renderer. Two modes driven by detailLevel:
///   .detailed (L1) → single hero card with track image + full phase timeline
///   else      (L2) → up to three stacked EventCardRows
public struct LargeWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if entry.detailLevel == .detailed, let card = cards.first {
                hero(card)
            } else if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(cards.prefix(3).enumerated()), id: \.offset) { _, card in
                        EventCardRow(card: card, now: entry.date)
                        if card.category != cards.prefix(3).last?.category { Divider() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    private func hero(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryBadge(category: card.category)
                Spacer()
                DDayBadge(targetDate: card.targetDate, now: entry.date)
            }
            Text(card.title).font(.system(size: 22, weight: .bold)).lineLimit(1)
            if let track = card.track {
                TrackImageView(track: track).frame(height: 130)
                Text(track.summary).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Text(card.phaseLabel).font(.system(size: 13, weight: .medium))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```

- [ ] **Step 2: Verify the package builds**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Core/Sources/UmaCore/UI/Widget/LargeWidgetView.swift
git commit -m "feat: add LargeWidgetView (detailed hero + all-schedule list)"
```

### Task 7.5: Lock screen views (rectangular + circular)

**Files:**
- Create: `Core/Sources/UmaCore/UI/Widget/LockWidgetViews.swift`

- [ ] **Step 1: Write the views**

```swift
import SwiftUI
import WidgetKit

/// accessoryRectangular: nearest event — title + phase + d-day on two lines.
public struct LockRectangularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            VStack(alignment: .leading, spacing: 1) {
                Text(L.string(card.category.labelKey)).font(.system(size: 11, weight: .semibold))
                Text(card.title).font(.system(size: 13, weight: .bold)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(card.targetDate, from: entry.date)))
                    Text(card.phaseLabel)
                }.font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L.string(.stateIdleTitle)).font(.system(size: 12))
        }
    }
}

/// accessoryCircular: d-day number with the category icon.
public struct LockCircularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            let days = CountdownFormatter.daysUntil(card.targetDate, from: entry.date)
            VStack(spacing: 0) {
                Image(systemName: card.category.sfSymbol).font(.system(size: 11, weight: .bold))
                Text(days <= 0 ? "D" : "\(days)").font(.system(size: 18, weight: .heavy))
                Text(days <= 0 ? "DAY" : "일").font(.system(size: 8))
            }
        } else {
            Image(systemName: "calendar")
        }
    }
}
```

- [ ] **Step 2: Verify the package builds**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Core/Sources/UmaCore/UI/Widget/LockWidgetViews.swift
git commit -m "feat: add lock screen rectangular + circular views"
```

---

# Phase 8 — Widget extension (definitions, provider, bundle)

### Task 8.1: WidgetPreferenceApplier + ScheduleTimelineProvider

**Files:**
- Create: `Widgets/WidgetPreferenceApplier.swift`
- Create: `Widgets/ScheduleTimelineProvider.swift`

> No `swift test` here (extension target builds only inside Xcode). Verified at Task 8.5 build.

- [ ] **Step 1: Write `Widgets/WidgetPreferenceApplier.swift`**

```swift
import Foundation
import UmaCore

/// The widget runs in its own process and doesn't inherit the app's static state — every
/// timeline entry re-applies user prefs so views render with the chosen font + language.
enum WidgetPreferenceApplier {
    static func apply(_ prefs: UserPrefs?) {
        Typography.currentTheme = prefs?.fontTheme ?? .system
        switch prefs?.localeOverride ?? .system {
        case .system: L.currentLocale = nil
        case .ko:     L.currentLocale = Locale(identifier: "ko")
        case .en:     L.currentLocale = Locale(identifier: "en")
        }
    }
}
```

- [ ] **Step 2: Write `Widgets/ScheduleTimelineProvider.swift`**

```swift
import WidgetKit
import UmaCore
import Foundation

/// One provider, parameterized by the widget's variant + detail level. Each Widget passes
/// its own (variant, detailLevel) so a single provider type drives all 11 widgets.
struct ScheduleTimelineProvider: TimelineProvider {
    typealias Entry = WidgetEntry

    let variant: WidgetVariant
    let detailLevel: DetailLevel

    private static let prefsKey = "pref.user.v1"

    func placeholder(in context: Context) -> WidgetEntry {
        let prefs = AppGroupStore.shared().read(UserPrefs.self, forKey: Self.prefsKey)
        WidgetPreferenceApplier.apply(prefs)
        return WidgetEntry(date: Date(), state: .idle, detailLevel: detailLevel, fontTheme: prefs?.fontTheme ?? .system)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        Task { completion(await currentEntry(date: Date())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task {
            let entry = await currentEntry(date: Date())
            completion(Timeline(entries: [entry], policy: refreshPolicy(for: entry)))
        }
    }

    private func currentEntry(date: Date) async -> WidgetEntry {
        let prefs = AppGroupStore.shared().read(UserPrefs.self, forKey: Self.prefsKey)
        WidgetPreferenceApplier.apply(prefs)
        let fontTheme = prefs?.fontTheme ?? .system
        let repo = ScheduleRepository.makeLive()
        do {
            let doc = try await repo.current()
            // Pre-cache the hero track image for detailed widgets so the view can load it sync.
            if detailLevel == .detailed,
               case let .content(cards) = ScheduleStateResolver.resolve(document: doc, variant: variant, now: date),
               let url = cards.first?.track?.imageURL {
                await TrackImageCache.shared().ensureCached(url) { try await Data(contentsOf: $0) }
            }
            let state = ScheduleStateResolver.resolve(document: doc, variant: variant, now: date)
            return WidgetEntry(date: date, state: state, detailLevel: detailLevel, fontTheme: fontTheme)
        } catch {
            return WidgetEntry(date: date, state: .noData, detailLevel: detailLevel, fontTheme: fontTheme)
        }
    }

    /// Refresh shortly after the nearest target date; otherwise 1h if within a day, else 6h.
    private func refreshPolicy(for entry: WidgetEntry) -> TimelineReloadPolicy {
        guard case let .content(cards) = entry.state,
              let nearest = cards.map(\.targetDate).min() else {
            return .after(Date().addingTimeInterval(6 * 3600))
        }
        let secs = nearest.timeIntervalSinceNow
        if secs > 0 && secs <= 60 { return .after(nearest.addingTimeInterval(60)) }   // just past the boundary
        if secs > 0 && secs <= 86_400 { return .after(Date().addingTimeInterval(3600)) }
        return .after(Date().addingTimeInterval(6 * 3600))
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Widgets/WidgetPreferenceApplier.swift Widgets/ScheduleTimelineProvider.swift
git commit -m "feat: add widget preference applier + parameterized timeline provider"
```

### Task 8.2: Home widget definitions (9)

**Files:**
- Create: `Widgets/HomeWidgets.swift`

- [ ] **Step 1: Write the 9 home widget definitions**

```swift
import WidgetKit
import SwiftUI
import UmaCore

private func container<V: View>(_ view: V) -> some View {
    view
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
}

// MARK: Large

struct L1MajorDetailWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "L1MajorDetailWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .detailed)) { entry in
            container(LargeWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.l1.title", bundle: .umaCore))
        .description(Text("gallery.l1.desc", bundle: .umaCore))
        .supportedFamilies([.systemLarge])
    }
}

struct L2AllScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "L2AllScheduleWidget",
                            provider: ScheduleTimelineProvider(variant: .allSchedule, detailLevel: .brief)) { entry in
            container(LargeWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.l2.title", bundle: .umaCore))
        .description(Text("gallery.l2.desc", bundle: .umaCore))
        .supportedFamilies([.systemLarge])
    }
}

// MARK: Medium

struct M1MajorBriefWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "M1MajorBriefWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .brief)) { entry in
            container(MediumWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.m1.title", bundle: .umaCore))
        .description(Text("gallery.m1.desc", bundle: .umaCore))
        .supportedFamilies([.systemMedium])
    }
}

struct M2ChampionsLoHWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "M2ChampionsLoHWidget",
                            provider: ScheduleTimelineProvider(variant: .championsLoH, detailLevel: .brief)) { entry in
            container(MediumWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.m2.title", bundle: .umaCore))
        .description(Text("gallery.m2.desc", bundle: .umaCore))
        .supportedFamilies([.systemMedium])
    }
}

struct M3PickupWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "M3PickupWidget",
                            provider: ScheduleTimelineProvider(variant: .pickupOnly, detailLevel: .brief)) { entry in
            container(MediumWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.m3.title", bundle: .umaCore))
        .description(Text("gallery.m3.desc", bundle: .umaCore))
        .supportedFamilies([.systemMedium])
    }
}

// MARK: Small

struct S1MajorOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S1MajorOverviewWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s1.title", bundle: .umaCore))
        .description(Text("gallery.s1.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}

struct S2ChampionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S2ChampionsWidget",
                            provider: ScheduleTimelineProvider(variant: .championsOnly, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s2.title", bundle: .umaCore))
        .description(Text("gallery.s2.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}

struct S3LoHWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S3LoHWidget",
                            provider: ScheduleTimelineProvider(variant: .loHOnly, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s3.title", bundle: .umaCore))
        .description(Text("gallery.s3.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}

struct S4PickupWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "S4PickupWidget",
                            provider: ScheduleTimelineProvider(variant: .pickupOnly, detailLevel: .overview)) { entry in
            container(SmallWidgetView(entry: entry).fontDesign(Typography.fontDesign(for: entry.fontTheme)))
        }
        .configurationDisplayName(Text("gallery.s4.title", bundle: .umaCore))
        .description(Text("gallery.s4.desc", bundle: .umaCore))
        .supportedFamilies([.systemSmall])
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Widgets/HomeWidgets.swift
git commit -m "feat: add 9 home widget definitions"
```

### Task 8.3: Lock screen widget definitions (2)

**Files:**
- Create: `Widgets/LockWidgets.swift`

- [ ] **Step 1: Write the lock widgets**

```swift
import WidgetKit
import SwiftUI
import UmaCore

struct LockRectangularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockRectangularWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            LockRectangularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_rect.title", bundle: .umaCore))
        .description(Text("gallery.lock_rect.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockCircularWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockCircularWidget",
                            provider: ScheduleTimelineProvider(variant: .majorAuto, detailLevel: .overview)) { entry in
            LockCircularView(entry: entry)
                .fontDesign(Typography.fontDesign(for: entry.fontTheme))
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Text("gallery.lock_circ.title", bundle: .umaCore))
        .description(Text("gallery.lock_circ.desc", bundle: .umaCore))
        .supportedFamilies([.accessoryCircular])
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Widgets/LockWidgets.swift
git commit -m "feat: add lock screen rectangular + circular widgets"
```

### Task 8.4: Widget bundle

**Files:**
- Create: `Widgets/UmaWidgetBundle.swift`

- [ ] **Step 1: Write the bundle**

```swift
import WidgetKit
import SwiftUI

@main
struct UmaWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Lock screen
        LockRectangularWidget()
        LockCircularWidget()
        // Home — large
        L1MajorDetailWidget()
        L2AllScheduleWidget()
        // Home — medium
        M1MajorBriefWidget()
        M2ChampionsLoHWidget()
        M3PickupWidget()
        // Home — small
        S1MajorOverviewWidget()
        S2ChampionsWidget()
        S3LoHWidget()
        S4PickupWidget()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Widgets/UmaWidgetBundle.swift
git commit -m "feat: register all widgets in UmaWidgetBundle"
```

### Task 8.5: Generate Xcode project & build both targets

**Files:** none (build step)

- [ ] **Step 1: Generate the Xcode project**

Run: `xcodegen generate`
Expected: `Created project at .../UmaSchedule.xcodeproj` (install via `brew install xcodegen` if missing).

- [ ] **Step 2: Build app + widget for the simulator**

Run:
```bash
xcodebuild -project UmaSchedule.xcodeproj -scheme UmaSchedule \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```
Expected: `** BUILD SUCCEEDED **`. Fix any compile errors (most likely view-body type mismatches) before continuing.

- [ ] **Step 3: Commit the generated project (gitignored .xcodeproj — commit only if not ignored)**

The `.gitignore` ignores `*.xcodeproj`. Do NOT force-add it. Instead verify the build and commit a no-op marker only if other files changed. (No commit needed if only the gitignored project changed.)

- [ ] **Step 4: Manual visual check (Xcode previews / simulator)**

Open `UmaSchedule.xcodeproj` in Xcode, run the app target on a simulator, long-press the home screen, add each widget from the gallery, and confirm:
- All 11 widgets appear in the gallery with localized titles
- Each renders the seed fallback data (CM "리브르", LoH "시즌 3", pickup "오구리 캡")
- D-day, phase label, and track summary look correct

Document anything off; fix in the relevant Phase 7 view file and rebuild.

---

# Phase 9 — App target

### Task 9.1: PrefsStore + App entry

**Files:**
- Create: `Core/Sources/UmaCore/State/PrefsStore.swift`
- Create: `App/UmaScheduleApp.swift`
- Test: `Core/Tests/UmaCoreTests/PrefsStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import UmaCore

final class PrefsStoreTests: XCTestCase {
    func test_savePersistsAndReloads() {
        let suite = "test.\(UUID().uuidString)"
        let store = AppGroupStore(defaults: UserDefaults(suiteName: suite)!)
        let prefs = PrefsStore(store: store)
        var p = prefs.prefs
        p.fontTheme = .serif
        prefs.save(p)
        let reloaded = PrefsStore(store: store)
        XCTAssertEqual(reloaded.prefs.fontTheme, .serif)
    }

    func test_defaultsWhenEmpty() {
        let store = AppGroupStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!)
        XCTAssertEqual(PrefsStore(store: store).prefs, UserPrefs.default)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Core && swift test --filter PrefsStoreTests`
Expected: FAIL — cannot find `PrefsStore`.

- [ ] **Step 3: Write `PrefsStore.swift`**

```swift
import Foundation
import Observation

@Observable
public final class PrefsStore {
    public static let key = "pref.user.v1"
    public static let ttl: TimeInterval = .greatestFiniteMagnitude

    public private(set) var prefs: UserPrefs

    @ObservationIgnored private let store: AppGroupStore
    @ObservationIgnored private let reloadWidgets: () -> Void

    public init(store: AppGroupStore = .shared(), reloadWidgets: @escaping () -> Void = {}) {
        self.store = store
        self.reloadWidgets = reloadWidgets
        self.prefs = store.read(UserPrefs.self, forKey: Self.key) ?? .default
    }

    public func save(_ updated: UserPrefs) {
        prefs = updated
        try? store.write(updated, forKey: Self.key, ttl: Self.ttl)
        reloadWidgets()
    }

    public func update(_ mutate: (inout UserPrefs) -> Void) {
        var current = prefs
        mutate(&current)
        save(current)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Core && swift test --filter PrefsStoreTests`
Expected: PASS.

- [ ] **Step 5: Write `App/UmaScheduleApp.swift`**

```swift
import SwiftUI
import WidgetKit
import UmaCore

@main
struct UmaScheduleApp: App {
    @State private var prefs = PrefsStore(reloadWidgets: { WidgetCenter.shared.reloadAllTimelines() })

    init() { BackgroundRefreshTask.register() }

    var body: some Scene {
        WindowGroup {
            RootView(prefs: prefs)
                .onAppear { WidgetPreferenceApplierApp.apply(prefs.prefs) }
        }
    }
}

/// App-side mirror of the widget's preference applier (sets Typography + L locale for app UI).
enum WidgetPreferenceApplierApp {
    static func apply(_ prefs: UserPrefs) {
        Typography.currentTheme = prefs.fontTheme
        switch prefs.localeOverride {
        case .system: L.currentLocale = nil
        case .ko:     L.currentLocale = Locale(identifier: "ko")
        case .en:     L.currentLocale = Locale(identifier: "en")
        }
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add Core/Sources/UmaCore/State/PrefsStore.swift App/UmaScheduleApp.swift Core/Tests/UmaCoreTests/PrefsStoreTests.swift
git commit -m "feat: add PrefsStore + app entry point"
```

### Task 9.2: RootView (preview list + settings entry)

**Files:**
- Create: `App/RootView.swift`

- [ ] **Step 1: Write `RootView.swift`**

```swift
import SwiftUI
import WidgetKit
import UmaCore

/// App home: shows a live preview of each category's next event (so the app is useful on
/// its own) plus a link to Settings. Data comes from the same ScheduleRepository the widget
/// uses; loaded once on appear.
struct RootView: View {
    @Bindable var prefs: PrefsStore
    @State private var document: ScheduleDocument?
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            List {
                if let doc = document {
                    ForEach(prefs.prefs.categoryOrder, id: \.self) { category in
                        Section(L.string(category.labelKey)) {
                            if let card = card(for: category, doc: doc) {
                                EventCardRow(card: card, now: Date()).padding(.vertical, 4)
                            } else {
                                Text(L.string(.stateIdleTitle)).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else if loadFailed {
                    Text(L.string(.stateNoDataTitle))
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("우마 스케줄")
            .toolbar {
                NavigationLink {
                    SettingsView(prefs: prefs)
                } label: { Image(systemName: "gearshape") }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func card(for category: EventCategory, doc: ScheduleDocument) -> EventCard? {
        switch category {
        case .championsMeeting: return EventCardFactory.championsCard(doc.championsMeetings, now: Date())
        case .leagueOfHeroes:   return EventCardFactory.leagueCard(doc.leagueOfHeroes, now: Date())
        case .gacha:            return EventCardFactory.gachaCard(doc.gachaBanners, now: Date())
        }
    }

    private func load() async {
        do {
            document = try await ScheduleRepository.makeLive().current()
            loadFailed = false
            WidgetCenter.shared.reloadAllTimelines()
        } catch { loadFailed = true }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add App/RootView.swift
git commit -m "feat: add RootView with per-category next-event preview"
```

### Task 9.3: SettingsView

**Files:**
- Create: `App/SettingsView.swift`

- [ ] **Step 1: Write `SettingsView.swift`**

```swift
import SwiftUI
import UmaCore

struct SettingsView: View {
    @Bindable var prefs: PrefsStore

    var body: some View {
        Form {
            Section(L.string(.settingsSectionCategories)) {
                ForEach(prefs.prefs.categoryOrder, id: \.self) { c in
                    HStack { Image(systemName: c.sfSymbol); Text(L.string(c.labelKey)) }
                }
                .onMove { from, to in
                    var order = prefs.prefs.categoryOrder
                    order.move(fromOffsets: from, toOffset: to)
                    prefs.update { $0.categoryOrder = order }
                }
            }

            Section(L.string(.settingsSectionFont)) {
                Picker(L.string(.settingsSectionFont), selection: fontBinding) {
                    Text(L.string(.settingsValueFontSystem)).tag(FontTheme.system)
                    Text(L.string(.settingsValueFontRounded)).tag(FontTheme.rounded)
                    Text(L.string(.settingsValueFontMono)).tag(FontTheme.mono)
                    Text(L.string(.settingsValueFontSerif)).tag(FontTheme.serif)
                }
            }

            Section(L.string(.settingsSectionLanguage)) {
                Picker(L.string(.settingsSectionLanguage), selection: localeBinding) {
                    Text(L.string(.settingsValueLanguageSystem)).tag(AppLocale.system)
                    Text(L.string(.settingsValueLanguageKo)).tag(AppLocale.ko)
                    Text(L.string(.settingsValueLanguageEn)).tag(AppLocale.en)
                }
            }

            Section(L.string(.settingsSectionNotify)) {
                Toggle(L.string(.settingsRowNotifyBefore), isOn: notifyBinding)
            }

            Section {
                Text(L.string(.legalDisclaimer)).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L.string(.settingsTitle))
    }

    private var fontBinding: Binding<FontTheme> {
        Binding(get: { prefs.prefs.fontTheme }, set: { v in prefs.update { $0.fontTheme = v }; WidgetPreferenceApplierApp.apply(prefs.prefs) })
    }
    private var localeBinding: Binding<AppLocale> {
        Binding(get: { prefs.prefs.localeOverride }, set: { v in prefs.update { $0.localeOverride = v }; WidgetPreferenceApplierApp.apply(prefs.prefs) })
    }
    private var notifyBinding: Binding<Bool> {
        Binding(get: { prefs.prefs.notifyBeforePhase }, set: { v in prefs.update { $0.notifyBeforePhase = v } })
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add App/SettingsView.swift
git commit -m "feat: add SettingsView (category order, font, language, notify)"
```

### Task 9.4: BackgroundRefreshTask

**Files:**
- Create: `App/BackgroundRefreshTask.swift`

- [ ] **Step 1: Write `BackgroundRefreshTask.swift`**

```swift
import Foundation
import BackgroundTasks
import WidgetKit
import UmaCore

/// Registers a periodic background fetch that refreshes the schedule cache + reloads widgets.
enum BackgroundRefreshTask {
    static let identifier = "com.damienjee.umaschedule.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            handle(task as! BGAppRefreshTask)
        }
        schedule()
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(6 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        schedule()  // chain the next one
        let work = Task {
            _ = try? await ScheduleRepository.makeLive().current()
            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }
}
```

- [ ] **Step 2: Build the app target to confirm it links**

Run:
```bash
xcodegen generate && xcodebuild -project UmaSchedule.xcodeproj -scheme UmaSchedule \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add App/BackgroundRefreshTask.swift
git commit -m "feat: add background refresh task for schedule + widget reload"
```

---

# Phase 10 — App Store polish

### Task 10.1: Privacy manifest

**Files:**
- Create: `Core/Sources/UmaCore/Resources/PrivacyInfo.xcprivacy`
- Modify: `Core/Package.swift` (add the `.copy` resource)

- [ ] **Step 1: Write `PrivacyInfo.xcprivacy`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key><array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
  </array>
</dict></plist>
```

- [ ] **Step 2: Add resource to `Core/Package.swift`** — change the `resources:` array of the `UmaCore` target to:

```swift
            resources: [
                .process("Resources"),
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
```

> Note: keep `.process("Resources")` for `.lproj`/JSON; `.copy` the manifest so it ships verbatim. If SPM complains about the file being covered twice, move `PrivacyInfo.xcprivacy` out of `Resources/` into `Core/Sources/UmaCore/PrivacyInfo.xcprivacy` and use `.copy("PrivacyInfo.xcprivacy")`.

- [ ] **Step 3: Verify the package still builds + tests pass**

Run: `cd Core && swift build && swift test`
Expected: build succeeds, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add Core/Sources/UmaCore/Resources/PrivacyInfo.xcprivacy Core/Package.swift
git commit -m "chore: add privacy manifest (UserDefaults reason CA92.1)"
```

### Task 10.2: Fallback-refresh script + README

**Files:**
- Create: `scripts/generate-fallback.sh`
- Create: `README.md`

- [ ] **Step 1: Write `scripts/generate-fallback.sh`** (snapshots the live remote JSON into the bundled fallback)

```bash
#!/usr/bin/env bash
# Refresh the bundled fallback from the live remote schedule JSON.
# Usage: ./scripts/generate-fallback.sh
set -euo pipefail
URL="https://raw.githubusercontent.com/damienjee/uma-schedule-data/main/schedule.json"
DEST="Core/Sources/UmaCore/Resources/schedule_fallback.json"
echo "Fetching $URL ..."
curl -fsSL "$URL" -o "$DEST"
echo "Wrote $DEST"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x scripts/generate-fallback.sh`

- [ ] **Step 3: Write `README.md`**

```markdown
# 우마 스케줄 위젯 (Uma Schedule Widget)

Korean-server Umamusume schedule on your iOS home & lock screen — Champions Meeting,
League of Heroes, and gacha pickups with d-day countdowns.

## Build
```
xcodegen generate
open UmaSchedule.xcodeproj
```
Core logic tests: `cd Core && swift test`.

## Data
Schedule is fetched from a hand-maintained remote JSON (see `ScheduleEndpoint.url`),
cached in the App Group, and falls back to the bundled `schedule_fallback.json`.
Refresh the bundled copy with `./scripts/generate-fallback.sh`.

## Disclaimer
Unofficial. Not affiliated with Kakao Games / Cygames.
```

- [ ] **Step 4: Commit**

```bash
git add scripts/generate-fallback.sh README.md
git commit -m "docs: add fallback refresh script + README"
```

### Task 10.3: Final full-suite verification

**Files:** none

- [ ] **Step 1: Run the entire Core test suite**

Run: `cd Core && swift test`
Expected: all tests pass (no failures, no skips).

- [ ] **Step 2: Build both targets clean**

Run:
```bash
xcodegen generate && xcodebuild -project UmaSchedule.xcodeproj -scheme UmaSchedule \
  -destination 'generic/platform=iOS Simulator' -configuration Debug clean build CODE_SIGNING_ALLOWED=NO
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Manual simulator pass**

Run the app on a simulator: confirm the per-category preview loads, settings changes (font/language/order) persist and reflect in widgets, and all 11 widgets render. Note any issues for follow-up.

- [ ] **Step 4: Commit any fixes, then tag readiness**

```bash
git add -A
git commit -m "chore: final verification fixes" || echo "nothing to commit"
```

---

## Self-Review Notes (for the planner — not an execution step)

- **Spec coverage:** server=KR (fallback JSON `server:"kr"`), remote JSON + bundle fallback (Tasks 2.2–2.4), widget matrix 2L/3M/4S + 2 lock (Tasks 8.2–8.3), d-day auto phase transition (Tasks 3.1, 3.3), track image remote-fetch + diagram fallback (Tasks 6.3–6.4, 8.1 pre-cache), localization ko/en (Phase 5), settings + notify pref (Tasks 9.3, UserPrefs), App Store polish/privacy (Phase 10). Notifications scheduling itself is intentionally limited to a stored preference toggle in v1 (spec §6 "가볍게"); wiring local notifications is a follow-up if desired — flag for the user before execution.
- **Type consistency:** `EventCard` carries `track: TrackCondition?` (Task 1.5) used in views (7.x) and factory (3.3); `WidgetEntry(date:state:detailLevel:fontTheme:)` signature consistent across provider (8.1) and tests (4.2); `ScheduleRepository.makeLive()` / `.current()` consistent across provider, app, background task.
- **Known gotcha flagged inline:** Task 7.2 shows the wrong `.map`/`AnyView` form then instructs to use the clean `if let`. Ensure the shipped code uses `if let`.

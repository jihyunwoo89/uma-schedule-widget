# Workstream A — Rich Schema + v3 Display (App) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the UmaCore data model to schema v2 (rich track conditions, code-name/race titles, event period + estimated flag, pickup trainees + support cards) and update the 11 widgets to the confirmed v3 layout.

**Architecture:** This modifies the already-merged v1 app (on `main`). Schema v2 (spec §3) is the contract; this plan implements the Swift side and a v2 bundled fallback JSON. The remote-fetch/cache/resolver/widget-bundle plumbing is unchanged — only models, the card factory, display formatters, localized labels, and the SwiftUI widget views change. Workstream B (ingestion) will later produce JSON in this exact shape.

**Tech Stack:** Swift 5.10, iOS 17+, SwiftUI, WidgetKit, SPM (UmaCore), XcodeGen, Xcode.

**Reference spec:** `docs/superpowers/specs/2026-05-21-uma-widget-v2-rich-schema-and-ingestion-design.md`

## Default decisions (locked for this plan)
- **L1 detailed = variant A** (show all condition chips).
- **Names in Korean** (한글) as they appear in the source guide.
- `DistanceClass`: sprint→"단거리", mile→"마일", medium→"중거리", long→"장거리".
- `Turn`: clockwise→"시계(우)", counterclockwise→"반시계(좌)", straight→"직선".
- `season`/`weather`/`ground`/`timeOfDay` are stored as already-Korean `String?` (no enum) since the source supplies them as Korean text.
- Schema is bumped to `version: 2`; the app does not need to decode v1 cached blobs (cache is disposable) — but `ScheduleRepository.cacheKey` is bumped to `cache.schedule.v2` so any stale v1 cache is ignored.

## Conventions
- Working dir: `/Users/damienjee/Desktop/claude_dev/uma_schedule_widget`
- Core tests: `cd Core && swift test` (single: `--filter <Class>`)
- Full app build: `xcodegen generate && xcodebuild -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO`
- TDD for logic; views verified by `swift build`. Commit per task. `UIImage` stays guarded by `#if canImport(UIKit)` (already so).

## File Structure (what changes)
```
Core/Sources/UmaCore/
  Models/
    EventPeriod.swift        # NEW — EventPeriod{start,end,estimated}
    TrackCondition.swift     # REWRITE — expanded fields + enums + summary/conditionChips
    Events.swift             # REWRITE — ChampionsMeeting(codeName/raceGrade/raceName/period), LeagueOfHeroes(round/raceName/period), SupportCardPick, PickupPeriod
    ScheduleDocument.swift   # MODIFY — version 2, sourcePostNo, pickups (was gachaBanners)
    EventCard.swift          # REWRITE — title/subtitle/period/trainees/supportCards
  Logic/
    EventCardFactory.swift   # REWRITE — build v2 cards; pickupCard (was gachaCard)
    PeriodFormatter.swift    # NEW — "7.14 ~ 7.20 (예상)" formatting
  DesignSystem/
    CourseDiagramView.swift  # MODIFY — show distanceClass; uses Turn label
  Localization/
    L.swift                  # MODIFY — add labels: estimated, trainee, support, distance/turn classes
    Resources/{ko,en}.lproj/Localizable.strings  # MODIFY — add the strings
  Resources/schedule_fallback.json  # REWRITE — v2 shape with real example data
  Widgets/
    ScheduleStateResolver.swift  # (unchanged — verify still compiles)
  UI/Widget/
    WidgetPieces.swift       # MODIFY — EventCardRow renders subtitle/period; add BracketTitle, ConditionChips, PickupLines
    SmallWidgetView.swift    # MODIFY — bracket title + subtitle; S4 pickup full support names
    MediumWidgetView.swift   # MODIFY — bracket titles; M3 pickup full
    LargeWidgetView.swift    # MODIFY — L1 hero: chips; L2 pickup full
    LockWidgetViews.swift    # MODIFY — bracket title in rect
Core/Tests/UmaCoreTests/     # update affected tests + new ones
```

---

# Phase A1 — Schema models

### Task A1.1: EventPeriod
**Files:** Create `Core/Sources/UmaCore/Models/EventPeriod.swift`; Test `Core/Tests/UmaCoreTests/EventPeriodTests.swift`

- [ ] **Step 1: Write the failing test**
```swift
import XCTest
@testable import UmaCore

final class EventPeriodTests: XCTestCase {
    func test_roundTrip() throws {
        let p = EventPeriod(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 86400), estimated: true)
        XCTAssertEqual(try JSONDecoder().decode(EventPeriod.self, from: JSONEncoder().encode(p)), p)
    }
}
```
- [ ] **Step 2: Run** `cd Core && swift test --filter EventPeriodTests` — FAIL (no EventPeriod).
- [ ] **Step 3: Implement**
```swift
import Foundation

public struct EventPeriod: Codable, Hashable, Sendable {
    public var start: Date
    public var end: Date
    public var estimated: Bool   // "(예상)" — KR date not yet official

    public init(start: Date, end: Date, estimated: Bool = false) {
        self.start = start
        self.end = end
        self.estimated = estimated
    }
}
```
- [ ] **Step 4: Run** the test — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Models/EventPeriod.swift Core/Tests/UmaCoreTests/EventPeriodTests.swift && git commit -m "feat: add EventPeriod model"`

### Task A1.2: TrackCondition expanded + enums
**Files:** Rewrite `Core/Sources/UmaCore/Models/TrackCondition.swift`; Rewrite test `Core/Tests/UmaCoreTests/TrackConditionTests.swift`

- [ ] **Step 1: Write the failing test** (replace the whole file)
```swift
import XCTest
@testable import UmaCore

final class TrackConditionTests: XCTestCase {
    private func t() -> TrackCondition {
        TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile,
                       turn: .clockwise, courseSide: "외측", season: "봄", weather: "맑음", ground: "양호", timeOfDay: "낮")
    }
    func test_summary() { XCTAssertEqual(t().summary, "한신 · 잔디 1600m") }
    func test_distanceClassLabel() {
        XCTAssertEqual(DistanceClass.sprint.koLabel, "단거리")
        XCTAssertEqual(DistanceClass.mile.koLabel, "마일")
        XCTAssertEqual(DistanceClass.long.koLabel, "장거리")
    }
    func test_turnLabel() {
        XCTAssertEqual(Turn.clockwise.koLabel, "시계(우)")
        XCTAssertEqual(Turn.counterclockwise.koLabel, "반시계(좌)")
        XCTAssertEqual(Turn.straight.koLabel, "직선")
    }
    func test_conditionChips_inOrder_skipsNils() {
        XCTAssertEqual(t().conditionChips, ["시계(우)", "외측", "봄", "맑음", "양호", "낮"])
        let bare = TrackCondition(racecourse: "도쿄", surface: .turf, distanceMeters: 2400, distanceClass: .long)
        XCTAssertEqual(bare.conditionChips, [])
    }
    func test_roundTrip() throws {
        XCTAssertEqual(try JSONDecoder().decode(TrackCondition.self, from: JSONEncoder().encode(t())), t())
    }
}
```
- [ ] **Step 2: Run** `--filter TrackConditionTests` — FAIL (signature/fields changed).
- [ ] **Step 3: Implement** (replace the whole file)
```swift
import Foundation

public enum Surface: String, Codable, Hashable, Sendable {
    case turf, dirt
    public var koLabel: String { self == .turf ? "잔디" : "더트" }
}

public enum DistanceClass: String, Codable, Hashable, Sendable {
    case sprint, mile, medium, long
    public var koLabel: String {
        switch self {
        case .sprint: return "단거리"
        case .mile:   return "마일"
        case .medium: return "중거리"
        case .long:   return "장거리"
        }
    }
}

public enum Turn: String, Codable, Hashable, Sendable {
    case clockwise, counterclockwise, straight
    public var koLabel: String {
        switch self {
        case .clockwise:        return "시계(우)"
        case .counterclockwise: return "반시계(좌)"
        case .straight:         return "직선"
        }
    }
}

public struct TrackCondition: Codable, Hashable, Sendable {
    public var racecourse: String
    public var surface: Surface
    public var distanceMeters: Int
    public var distanceClass: DistanceClass
    public var turn: Turn?
    public var courseSide: String?    // 외측/내측
    public var season: String?        // 봄/여름/가을/겨울
    public var weather: String?       // 맑음/흐림/비/눈
    public var ground: String?        // 양호/약간 무거움/무거움/불량
    public var timeOfDay: String?     // 낮/밤
    public var imageURL: URL?

    public init(racecourse: String, surface: Surface, distanceMeters: Int, distanceClass: DistanceClass,
                turn: Turn? = nil, courseSide: String? = nil, season: String? = nil, weather: String? = nil,
                ground: String? = nil, timeOfDay: String? = nil, imageURL: URL? = nil) {
        self.racecourse = racecourse
        self.surface = surface
        self.distanceMeters = distanceMeters
        self.distanceClass = distanceClass
        self.turn = turn
        self.courseSide = courseSide
        self.season = season
        self.weather = weather
        self.ground = ground
        self.timeOfDay = timeOfDay
        self.imageURL = imageURL
    }

    /// One-line summary: "한신 · 잔디 1600m".
    public var summary: String { "\(racecourse) · \(surface.koLabel) \(distanceMeters)m" }

    /// Detailed condition chips for the Large widget, in display order, skipping nils.
    public var conditionChips: [String] {
        var c: [String] = []
        if let turn { c.append(turn.koLabel) }
        if let courseSide { c.append(courseSide) }
        if let season { c.append(season) }
        if let weather { c.append(weather) }
        if let ground { c.append(ground) }
        if let timeOfDay { c.append(timeOfDay) }
        return c
    }
}
```
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Models/TrackCondition.swift Core/Tests/UmaCoreTests/TrackConditionTests.swift && git commit -m "feat: expand TrackCondition (class/turn/course/season/weather/ground/time) + chips"`

### Task A1.3: Events (CM/LoH/PickupPeriod/SupportCardPick)
**Files:** Rewrite `Core/Sources/UmaCore/Models/Events.swift`; Rewrite test `Core/Tests/UmaCoreTests/EventsTests.swift`

- [ ] **Step 1: Write the failing test** (replace file)
```swift
import XCTest
@testable import UmaCore

final class EventsTests: XCTestCase {
    private let track = TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile)
    private func period() -> EventPeriod { EventPeriod(start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 200), estimated: true) }

    func test_championsMeeting_roundTrip() throws {
        let cm = ChampionsMeeting(id: "cm", codeName: "LONG", raceGrade: "G1", raceName: "벚꽃상",
                                  track: track, period: period(),
                                  phases: [EventPhase(kind: .open, label: "오픈", date: Date(timeIntervalSince1970: 100))])
        XCTAssertEqual(try JSONDecoder().decode(ChampionsMeeting.self, from: JSONEncoder().encode(cm)), cm)
    }
    func test_leagueOfHeroes_roundTrip() throws {
        let loh = LeagueOfHeroes(id: "loh", round: "10회차", raceName: "스프린터즈 스테이크스",
                                 track: track, period: period(),
                                 phases: [EventPhase(kind: .open, label: "오픈", date: Date(timeIntervalSince1970: 100))])
        XCTAssertEqual(try JSONDecoder().decode(LeagueOfHeroes.self, from: JSONEncoder().encode(loh)), loh)
    }
    func test_pickupPeriod_roundTrip() throws {
        let p = PickupPeriod(id: "p", period: period(),
                             trainees: ["오르페브르", "푸리오소"],
                             supportCards: [SupportCardPick(rarity: "SSR", name: "아몬드 아이", type: "스피드")])
        XCTAssertEqual(try JSONDecoder().decode(PickupPeriod.self, from: JSONEncoder().encode(p)), p)
    }
}
```
- [ ] **Step 2: Run** `--filter EventsTests` — FAIL.
- [ ] **Step 3: Implement** (replace file)
```swift
import Foundation

public struct ChampionsMeeting: Codable, Hashable, Sendable {
    public var id: String
    public var codeName: String      // 「LONG」 big title
    public var raceGrade: String?    // "G1"
    public var raceName: String      // "벚꽃상"
    public var track: TrackCondition
    public var period: EventPeriod
    public var phases: [EventPhase]

    public init(id: String, codeName: String, raceGrade: String?, raceName: String,
                track: TrackCondition, period: EventPeriod, phases: [EventPhase]) {
        self.id = id
        self.codeName = codeName
        self.raceGrade = raceGrade
        self.raceName = raceName
        self.track = track
        self.period = period
        self.phases = phases
    }
}

public struct LeagueOfHeroes: Codable, Hashable, Sendable {
    public var id: String
    public var round: String         // 「10회차」 big title
    public var raceName: String      // "스프린터즈 스테이크스"
    public var track: TrackCondition
    public var period: EventPeriod
    public var phases: [EventPhase]

    public init(id: String, round: String, raceName: String,
                track: TrackCondition, period: EventPeriod, phases: [EventPhase]) {
        self.id = id
        self.round = round
        self.raceName = raceName
        self.track = track
        self.period = period
        self.phases = phases
    }
}

public struct SupportCardPick: Codable, Hashable, Sendable {
    public var rarity: String   // "SSR"
    public var name: String     // "아몬드 아이"
    public var type: String     // "스피드"/"스태미나"/...
    public init(rarity: String, name: String, type: String) {
        self.rarity = rarity; self.name = name; self.type = type
    }
}

public struct PickupPeriod: Codable, Hashable, Sendable {
    public var id: String
    public var period: EventPeriod
    public var trainees: [String]
    public var supportCards: [SupportCardPick]
    public init(id: String, period: EventPeriod, trainees: [String], supportCards: [SupportCardPick]) {
        self.id = id; self.period = period; self.trainees = trainees; self.supportCards = supportCards
    }
}
```
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Models/Events.swift Core/Tests/UmaCoreTests/EventsTests.swift && git commit -m "feat: v2 events (codeName/round/race, period, pickup trainees+support)"`

### Task A1.4: ScheduleDocument v2
**Files:** Modify `Core/Sources/UmaCore/Models/ScheduleDocument.swift`; Modify test `Core/Tests/UmaCoreTests/ScheduleDocumentTests.swift`

- [ ] **Step 1: Write the failing test** (replace file)
```swift
import XCTest
@testable import UmaCore

final class ScheduleDocumentTests: XCTestCase {
    func test_decodesV2() throws {
        let json = """
        {"version":2,"updatedAt":"2026-05-20T00:00:00Z","sourcePostNo":1850737,"server":"kr",
         "championsMeetings":[],"leagueOfHeroes":[],"pickups":[]}
        """.data(using: .utf8)!
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        let doc = try d.decode(ScheduleDocument.self, from: json)
        XCTAssertEqual(doc.version, 2)
        XCTAssertEqual(doc.sourcePostNo, 1850737)
        XCTAssertTrue(doc.pickups.isEmpty)
    }
    func test_empty() { XCTAssertEqual(ScheduleDocument.empty.version, 2) }
}
```
- [ ] **Step 2: Run** `--filter ScheduleDocumentTests` — FAIL.
- [ ] **Step 3: Implement** (replace file)
```swift
import Foundation

public struct ScheduleDocument: Codable, Hashable, Sendable {
    public var version: Int
    public var updatedAt: Date
    public var sourcePostNo: Int?
    public var server: String
    public var championsMeetings: [ChampionsMeeting]
    public var leagueOfHeroes: [LeagueOfHeroes]
    public var pickups: [PickupPeriod]

    public init(version: Int = 2, updatedAt: Date, sourcePostNo: Int? = nil, server: String,
                championsMeetings: [ChampionsMeeting], leagueOfHeroes: [LeagueOfHeroes], pickups: [PickupPeriod]) {
        self.version = version
        self.updatedAt = updatedAt
        self.sourcePostNo = sourcePostNo
        self.server = server
        self.championsMeetings = championsMeetings
        self.leagueOfHeroes = leagueOfHeroes
        self.pickups = pickups
    }

    /// Zero-state for placeholders / first launch. server "kr" — app's only target region.
    public static let empty = ScheduleDocument(
        version: 2, updatedAt: Date(timeIntervalSince1970: 0), server: "kr",
        championsMeetings: [], leagueOfHeroes: [], pickups: []
    )
}
```
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Models/ScheduleDocument.swift Core/Tests/UmaCoreTests/ScheduleDocumentTests.swift && git commit -m "feat: ScheduleDocument v2 (sourcePostNo, pickups)"`

### Task A1.5: EventCard v2
**Files:** Rewrite `Core/Sources/UmaCore/Models/EventCard.swift`; Rewrite test `Core/Tests/UmaCoreTests/EventCardTests.swift`

- [ ] **Step 1: Write the failing test** (replace file)
```swift
import XCTest
@testable import UmaCore

final class EventCardTests: XCTestCase {
    func test_roundTrip() throws {
        let card = EventCard(
            category: .championsMeeting, title: "LONG", subtitle: "G1 벚꽃상",
            track: TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile),
            period: EventPeriod(start: Date(timeIntervalSince1970: 100), end: Date(timeIntervalSince1970: 200), estimated: true),
            phaseLabel: "오픈까지", targetDate: Date(timeIntervalSince1970: 100), status: .upcoming,
            trainees: [], supportCards: [])
        XCTAssertEqual(try JSONDecoder().decode(EventCard.self, from: JSONEncoder().encode(card)), card)
    }
}
```
- [ ] **Step 2: Run** `--filter EventCardTests` — FAIL.
- [ ] **Step 3: Implement** (replace file; keep EventCategory/EventStatus/DetailLevel as-is — re-declare them here unchanged)
```swift
import Foundation

public enum EventCategory: String, Codable, Hashable, Sendable {
    case championsMeeting, leagueOfHeroes, gacha
}
public enum EventStatus: String, Codable, Hashable, Sendable {
    case upcoming, active, ended
}
public enum DetailLevel: String, Codable, Hashable, Sendable {
    case overview, brief, detailed
}

public struct EventCard: Codable, Hashable, Sendable {
    public var category: EventCategory
    public var title: String                 // 「codeName」/「round」 ; pickup → trainees joined
    public var subtitle: String?             // "G1 벚꽃상" / race name ; nil for pickup
    public var track: TrackCondition?
    public var period: EventPeriod?
    public var phaseLabel: String            // "오픈까지" / "진행중" / "시작까지" / "종료까지"
    public var targetDate: Date
    public var status: EventStatus
    public var trainees: [String]            // pickup only
    public var supportCards: [SupportCardPick]   // pickup only

    public init(category: EventCategory, title: String, subtitle: String? = nil,
                track: TrackCondition? = nil, period: EventPeriod? = nil,
                phaseLabel: String, targetDate: Date, status: EventStatus,
                trainees: [String] = [], supportCards: [SupportCardPick] = []) {
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.track = track
        self.period = period
        self.phaseLabel = phaseLabel
        self.targetDate = targetDate
        self.status = status
        self.trainees = trainees
        self.supportCards = supportCards
    }
}
```
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Models/EventCard.swift Core/Tests/UmaCoreTests/EventCardTests.swift && git commit -m "feat: EventCard v2 (title/subtitle/period/trainees/supportCards)"`

---

# Phase A2 — Formatters & card factory

### Task A2.1: PeriodFormatter
**Files:** Create `Core/Sources/UmaCore/Logic/PeriodFormatter.swift`; Test `Core/Tests/UmaCoreTests/PeriodFormatterTests.swift`

- [ ] **Step 1: Write the failing test**
```swift
import XCTest
@testable import UmaCore

final class PeriodFormatterTests: XCTestCase {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func d(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }

    func test_range_estimated() {
        let p = EventPeriod(start: d("2026-07-14T00:00:00Z"), end: d("2026-07-20T00:00:00Z"), estimated: true)
        XCTAssertEqual(PeriodFormatter.range(p, calendar: cal), "7.14 ~ 7.20 (예상)")
    }
    func test_range_confirmed() {
        let p = EventPeriod(start: d("2026-06-15T00:00:00Z"), end: d("2026-06-21T00:00:00Z"), estimated: false)
        XCTAssertEqual(PeriodFormatter.range(p, calendar: cal), "6.15 ~ 6.21")
    }
}
```
- [ ] **Step 2: Run** `--filter PeriodFormatterTests` — FAIL.
- [ ] **Step 3: Implement**
```swift
import Foundation

public enum PeriodFormatter {
    /// "7.14 ~ 7.20" (+ " (예상)" when estimated).
    public static func range(_ p: EventPeriod, calendar: Calendar = .current) -> String {
        let md: (Date) -> String = { date in
            let c = calendar.dateComponents([.month, .day], from: date)
            return "\(c.month ?? 0).\(c.day ?? 0)"
        }
        let base = "\(md(p.start)) ~ \(md(p.end))"
        return p.estimated ? base + " (예상)" : base
    }
}
```
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Logic/PeriodFormatter.swift Core/Tests/UmaCoreTests/PeriodFormatterTests.swift && git commit -m "feat: add PeriodFormatter (range + 예상)"`

### Task A2.2: EventCardFactory v2
**Files:** Rewrite `Core/Sources/UmaCore/Logic/EventCardFactory.swift`; Rewrite test `Core/Tests/UmaCoreTests/EventCardFactoryTests.swift`

> `ScheduledEvent`/`PhaseResolution` (Logic/ScheduledEvent.swift) and `CountdownFormatter` are UNCHANGED — CM/LoH still conform via `phases`.

- [ ] **Step 1: Write the failing test** (replace file)
```swift
import XCTest
@testable import UmaCore

final class EventCardFactoryTests: XCTestCase {
    private func d(_ t: TimeInterval) -> Date { Date(timeIntervalSince1970: t) }
    private func track() -> TrackCondition { TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile, turn: .clockwise) }
    private func per(_ a: TimeInterval, _ b: TimeInterval, _ est: Bool = false) -> EventPeriod { EventPeriod(start: d(a), end: d(b), estimated: est) }

    private func doc() -> ScheduleDocument {
        let cm = ChampionsMeeting(id: "cm", codeName: "LONG", raceGrade: "G1", raceName: "벚꽃상", track: track(),
            period: per(100, 500, true),
            phases: [EventPhase(kind: .open, label: "오픈", date: d(100)), EventPhase(kind: .ended, label: "종료", date: d(500))])
        let loh = LeagueOfHeroes(id: "loh", round: "10회차", raceName: "스프린터즈 스테이크스", track: track(),
            period: per(200, 600),
            phases: [EventPhase(kind: .open, label: "오픈", date: d(200)), EventPhase(kind: .ended, label: "종료", date: d(600))])
        let pk = PickupPeriod(id: "pk", period: per(150, 450),
            trainees: ["오르페브르", "푸리오소"],
            supportCards: [SupportCardPick(rarity: "SSR", name: "아몬드 아이", type: "스피드"),
                           SupportCardPick(rarity: "SSR", name: "메지로 브라이트", type: "스태미나")])
        return ScheduleDocument(updatedAt: d(0), server: "kr", championsMeetings: [cm], leagueOfHeroes: [loh], pickups: [pk])
    }

    func test_championsCard() {
        let c = EventCardFactory.championsCard(doc().championsMeetings, now: d(50))!
        XCTAssertEqual(c.title, "LONG")
        XCTAssertEqual(c.subtitle, "G1 벚꽃상")
        XCTAssertEqual(c.phaseLabel, "오픈까지")
        XCTAssertEqual(c.targetDate, d(100))
        XCTAssertEqual(c.period?.estimated, true)
        XCTAssertEqual(c.track?.turn, .clockwise)
    }
    func test_leagueCard_subtitleIsRaceName_noGrade() {
        let c = EventCardFactory.leagueCard(doc().leagueOfHeroes, now: d(50))!
        XCTAssertEqual(c.title, "10회차")
        XCTAssertEqual(c.subtitle, "스프린터즈 스테이크스")
    }
    func test_pickupCard_activeShowsTraineesAndSupports() {
        let c = EventCardFactory.pickupCard(doc().pickups, now: d(200))!
        XCTAssertEqual(c.category, .gacha)
        XCTAssertEqual(c.title, "오르페브르 · 푸리오소")
        XCTAssertEqual(c.trainees, ["오르페브르", "푸리오소"])
        XCTAssertEqual(c.supportCards.count, 2)
        XCTAssertEqual(c.phaseLabel, "종료까지")
        XCTAssertEqual(c.targetDate, d(450))
        XCTAssertNil(c.track)
    }
    func test_pickupCard_upcoming() {
        let c = EventCardFactory.pickupCard(doc().pickups, now: d(100))!
        XCTAssertEqual(c.status, .upcoming)
        XCTAssertEqual(c.phaseLabel, "시작까지")
        XCTAssertEqual(c.targetDate, d(150))
    }
    func test_majorCard_picksNearer() {
        XCTAssertEqual(EventCardFactory.majorCard(doc(), now: d(50))?.category, .championsMeeting)
    }
}
```
- [ ] **Step 2: Run** `--filter EventCardFactoryTests` — FAIL.
- [ ] **Step 3: Implement** (replace file)
```swift
import Foundation

public enum EventCardFactory {

    public static func championsCard(_ meetings: [ChampionsMeeting], now: Date) -> EventCard? {
        guard let (cm, r) = meetings.map({ ($0, $0.resolution(now: now)) })
            .filter({ $0.1.status != .ended })
            .min(by: { $0.1.targetDate < $1.1.targetDate }) else { return nil }
        let subtitle = [cm.raceGrade, cm.raceName].compactMap { $0 }.joined(separator: " ")
        return EventCard(category: .championsMeeting, title: cm.codeName, subtitle: subtitle,
                         track: cm.track, period: cm.period, phaseLabel: phaseLabel(for: r),
                         targetDate: r.targetDate, status: r.status)
    }

    public static func leagueCard(_ leagues: [LeagueOfHeroes], now: Date) -> EventCard? {
        guard let (loh, r) = leagues.map({ ($0, $0.resolution(now: now)) })
            .filter({ $0.1.status != .ended })
            .min(by: { $0.1.targetDate < $1.1.targetDate }) else { return nil }
        return EventCard(category: .leagueOfHeroes, title: loh.round, subtitle: loh.raceName,
                         track: loh.track, period: loh.period, phaseLabel: phaseLabel(for: r),
                         targetDate: r.targetDate, status: r.status)
    }

    /// Active pickup (now within period) preferred; else soonest upcoming.
    public static func pickupCard(_ pickups: [PickupPeriod], now: Date) -> EventCard? {
        func card(_ p: PickupPeriod, label: String, target: Date, status: EventStatus) -> EventCard {
            EventCard(category: .gacha, title: p.trainees.joined(separator: " · "), subtitle: nil,
                      track: nil, period: p.period, phaseLabel: label, targetDate: target, status: status,
                      trainees: p.trainees, supportCards: p.supportCards)
        }
        if let p = pickups.filter({ now >= $0.period.start && now < $0.period.end })
            .min(by: { $0.period.end < $1.period.end }) {
            return card(p, label: "종료까지", target: p.period.end, status: .active)
        }
        if let p = pickups.filter({ $0.period.start > now })
            .min(by: { $0.period.start < $1.period.start }) {
            return card(p, label: "시작까지", target: p.period.start, status: .upcoming)
        }
        return nil
    }

    public static func majorCard(_ doc: ScheduleDocument, now: Date) -> EventCard? {
        [championsCard(doc.championsMeetings, now: now), leagueCard(doc.leagueOfHeroes, now: now)]
            .compactMap { $0 }
            .min { $0.targetDate < $1.targetDate }
    }

    private static func phaseLabel(for r: PhaseResolution) -> String {
        if let next = r.nextPhase, next.kind != .ended { return "\(next.label)까지" }
        return r.status == .active ? "진행중" : "종료까지"
    }
}
```
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Logic/EventCardFactory.swift Core/Tests/UmaCoreTests/EventCardFactoryTests.swift && git commit -m "feat: EventCardFactory v2 (code/round/race, period, pickupCard)"`

### Task A2.3: Resolver compile-fix
**Files:** Modify `Core/Sources/UmaCore/Widgets/ScheduleStateResolver.swift`

- [ ] **Step 1:** The resolver calls `EventCardFactory.gachaCard(document.gachaBanners, ...)`. Update the `.gacha` case to the new names.
Open the file and replace the `.gacha` line in `card(for:document:now:)`:
```swift
        case .gacha:            return EventCardFactory.pickupCard(document.pickups, now: now)
```
- [ ] **Step 2: Run** `cd Core && swift test --filter ScheduleStateResolverTests` — the existing resolver tests build a v1 doc; they will FAIL to compile. Update `ScheduleStateResolverTests.swift`'s `doc()` helper to v2 (mirror the `doc()` from EventCardFactoryTests in Task A2.2, using `pickups:` and the new CM/LoH initializers). Keep the existing assertions (categories/idle) — they remain valid.
- [ ] **Step 3: Run** `--filter ScheduleStateResolverTests` — PASS.
- [ ] **Step 4: Commit** `git add Core/Sources/UmaCore/Widgets/ScheduleStateResolver.swift Core/Tests/UmaCoreTests/ScheduleStateResolverTests.swift && git commit -m "refactor: resolver uses pickupCard; v2 test fixtures"`

### Task A2.4: Full Core test sweep
**Files:** any remaining tests referencing old shapes.
- [ ] **Step 1: Run** `cd Core && swift test`. Fix any remaining compile errors in test files that built v1 `GachaBanner`/`ChampionsMeeting(name:)`/`TrackCondition(direction:)` — update them to v2 initializers (do NOT change production code). Likely: none beyond A2.3, but verify.
- [ ] **Step 2:** Confirm green; **Commit** if anything changed: `git commit -am "test: migrate remaining fixtures to schema v2"`

---

# Phase A3 — Localization additions

### Task A3.1: L keys + strings
**Files:** Modify `Core/Sources/UmaCore/Localization/L.swift`, `Resources/ko.lproj/Localizable.strings`, `Resources/en.lproj/Localizable.strings`

- [ ] **Step 1:** Add these cases to `L.Key` (before the gallery block):
```swift
        case fieldEstimated   = "field.estimated"     // "예상"
        case fieldTrainee     = "field.trainee"       // "육성마"
        case fieldSupport     = "field.support"       // "서포트"
```
- [ ] **Step 2:** Append to `ko.lproj/Localizable.strings`:
```
"field.estimated" = "예상";
"field.trainee" = "육성마";
"field.support" = "서포트";
```
- [ ] **Step 3:** Append to `en.lproj/Localizable.strings`:
```
"field.estimated" = "Est.";
"field.trainee" = "Trainee";
"field.support" = "Support";
```
- [ ] **Step 4: Run** `cd Core && swift test --filter LocalizationTests` — PASS (parity holds: 3 new keys, 3 ko + 3 en).
- [ ] **Step 5: Commit** `git add Core/Sources/UmaCore/Localization/L.swift Core/Sources/UmaCore/Resources/ko.lproj/Localizable.strings Core/Sources/UmaCore/Resources/en.lproj/Localizable.strings && git commit -m "feat: add estimated/trainee/support localization keys"`

---

# Phase A4 — Widget views (v3)

> Build-verified (`cd Core && swift build`). `View.body` is implicitly `@ViewBuilder`.

### Task A4.1: Shared pieces — BracketTitle, ConditionChips, PickupLines; EventCardRow update
**Files:** Modify `Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift`

- [ ] **Step 1:** Replace the file with (keeps DDayBadge + WidgetMessageView, updates EventCardRow, adds 3 helpers):
```swift
import SwiftUI
import WidgetKit

public struct DDayBadge: View {
    public let targetDate: Date
    public let now: Date
    public init(targetDate: Date, now: Date) { self.targetDate = targetDate; self.now = now }
    public var body: some View {
        Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(targetDate, from: now)))
            .font(Typography.systemFont(size: 20, weight: .heavy))
    }
}

/// 「title」 in corner brackets — the big event identifier.
public struct BracketTitle: View {
    public let text: String
    public let size: CGFloat
    public init(_ text: String, size: CGFloat) { self.text = text; self.size = size }
    public var body: some View {
        Text("「\(text)」").font(Typography.systemFont(size: size, weight: .heavy)).lineLimit(1)
    }
}

/// Wrapping condition chips (Large detailed). Uses a simple flowing HStack of fixed rows.
public struct ConditionChips: View {
    public let chips: [String]
    public init(_ chips: [String]) { self.chips = chips }
    public var body: some View {
        // Two rows of up to 3 chips keeps layout predictable in the widget box.
        let rows = stride(from: 0, to: chips.count, by: 3).map { Array(chips[$0..<min($0+3, chips.count)]) }
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { chip in
                        Text(chip).font(.system(size: 10))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06)).clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// Pickup trainee + support lines (full names). Used in M3, S4, L2.
public struct PickupLines: View {
    public let trainees: [String]
    public let supports: [SupportCardPick]
    public let compact: Bool
    public init(trainees: [String], supports: [SupportCardPick], compact: Bool = false) {
        self.trainees = trainees; self.supports = supports; self.compact = compact
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            if !trainees.isEmpty {
                Text("\(L.string(.fieldTrainee))  \(trainees.joined(separator: " · "))")
                    .font(.system(size: compact ? 9.5 : 11, weight: .semibold)).lineLimit(1)
            }
            ForEach(Array(supports.enumerated()), id: \.offset) { _, s in
                (Text("\(s.rarity) ").font(.system(size: compact ? 9.5 : 11, weight: .bold)).foregroundColor(EventCategory.gacha.accentColor)
                 + Text(s.name).font(.system(size: compact ? 9.5 : 11))
                 + Text(" <\(s.type)>").font(.system(size: compact ? 9.5 : 11)).foregroundColor(EventCategory.leagueOfHeroes.accentColor))
                    .lineLimit(1)
            }
        }
    }
}

/// One compact row for multi-card widgets: badge + bracket title + subtitle, d-day on the right.
public struct EventCardRow: View {
    public let card: EventCard
    public let now: Date
    public init(card: EventCard, now: Date) { self.card = card; self.now = now }
    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                CategoryBadge(category: card.category)
                if card.category == .gacha {
                    PickupLines(trainees: card.trainees, supports: card.supportCards, compact: true)
                } else {
                    BracketTitle(card.title, size: 15)
                    if let s = card.subtitle { Text(s).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1) }
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
- [ ] **Step 2: Build** `cd Core && swift build` — Build complete!
- [ ] **Step 3: Commit** `git add Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift && git commit -m "feat: v3 widget pieces (BracketTitle, ConditionChips, PickupLines)"`

### Task A4.2: Small view
**Files:** Modify `Core/Sources/UmaCore/UI/Widget/SmallWidgetView.swift`
- [ ] **Step 1:** Replace `single(_:)` and keep the state switch. New file:
```swift
import SwiftUI
import WidgetKit

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

    @ViewBuilder
    private func single(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CategoryBadge(category: card.category)
            if card.category == .gacha {
                PickupLines(trainees: card.trainees, supports: card.supportCards, compact: true)
                Spacer(minLength: 0)
                DDayBadge(targetDate: card.targetDate, now: entry.date)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                BracketTitle(card.title, size: 22)
                if let s = card.subtitle { Text(s).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1) }
                if let t = card.track { Text(t.summary).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1) }
                Spacer(minLength: 0)
                DDayBadge(targetDate: card.targetDate, now: entry.date)
                Text(card.phaseLabel).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
```
- [ ] **Step 2: Build** — complete. **Step 3: Commit** `git add Core/Sources/UmaCore/UI/Widget/SmallWidgetView.swift && git commit -m "feat: v3 SmallWidgetView (bracket title; pickup full names)"`

### Task A4.3: Medium view
**Files:** Modify `Core/Sources/UmaCore/UI/Widget/MediumWidgetView.swift`
- [ ] **Step 1:** Replace file:
```swift
import SwiftUI
import WidgetKit

public struct MediumWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else if cards.count == 1, let card = cards.first, card.category == .gacha {
                pickupBig(card)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(cards.prefix(2).enumerated()), id: \.offset) { _, card in
                        EventCardRow(card: card, now: entry.date)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    private func pickupBig(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                CategoryBadge(category: card.category)
                Spacer()
                if let p = card.period { Text(PeriodFormatter.range(p)).font(.system(size: 11)).foregroundStyle(.secondary) }
                DDayBadge(targetDate: card.targetDate, now: entry.date)
            }
            PickupLines(trainees: card.trainees, supports: card.supportCards)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```
- [ ] **Step 2: Build** — complete. **Step 3: Commit** `git add Core/Sources/UmaCore/UI/Widget/MediumWidgetView.swift && git commit -m "feat: v3 MediumWidgetView (dual rows; pickup big)"`

### Task A4.4: Large view (L1 hero with chips, L2 list with pickup)
**Files:** Modify `Core/Sources/UmaCore/UI/Widget/LargeWidgetView.swift`
- [ ] **Step 1:** Replace file:
```swift
import SwiftUI
import WidgetKit

public struct LargeWidgetView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }

    @ViewBuilder
    public var body: some View {
        switch entry.state {
        case .content(let cards):
            if entry.detailLevel == .detailed, let card = cards.first {
                hero(card)
            } else if cards.isEmpty {
                WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
            } else {
                let shown = Array(cards.prefix(3))
                VStack(spacing: 12) {
                    ForEach(Array(shown.enumerated()), id: \.offset) { index, card in
                        EventCardRow(card: card, now: entry.date)
                        if index < shown.count - 1 { Divider() }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        case .idle:   WidgetMessageView(titleKey: .stateIdleTitle, bodyKey: .stateIdleBody)
        case .noData: WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
        }
    }

    @ViewBuilder
    private func hero(_ card: EventCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { CategoryBadge(category: card.category); Spacer(); DDayBadge(targetDate: card.targetDate, now: entry.date) }
            BracketTitle(card.title, size: 26)
            if let s = card.subtitle { Text(s).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary) }
            if let p = card.period { Text(PeriodFormatter.range(p)).font(.system(size: 12)).foregroundStyle(.secondary) }
            if let t = card.track {
                TrackImageView(track: t).frame(height: 92)
                Text(t.summary).font(.system(size: 12)).foregroundStyle(.secondary)
                ConditionChips(t.conditionChips)
            }
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```
- [ ] **Step 2: Build** — complete. **Step 3: Commit** `git add Core/Sources/UmaCore/UI/Widget/LargeWidgetView.swift && git commit -m "feat: v3 LargeWidgetView (hero + condition chips; list)"`

### Task A4.5: Lock views
**Files:** Modify `Core/Sources/UmaCore/UI/Widget/LockWidgetViews.swift`
- [ ] **Step 1:** Update `LockRectangularView` body to use bracket title + subtitle (LockCircularView unchanged):
```swift
import SwiftUI
import WidgetKit

public struct LockRectangularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }
    @ViewBuilder
    public var body: some View {
        if case let .content(cards) = entry.state, let card = cards.first {
            VStack(alignment: .leading, spacing: 1) {
                Text(card.category == .gacha ? L.string(.categoryPickup) : "\(L.string(card.category.labelKey)) 「\(card.title)」")
                    .font(.system(size: 11, weight: .semibold)).lineLimit(1)
                Text(card.category == .gacha ? card.title : (card.subtitle ?? ""))
                    .font(.system(size: 13, weight: .bold)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(card.targetDate, from: entry.date)))
                    Text(card.phaseLabel)
                }.font(.system(size: 11)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L.string(.stateIdleTitle)).font(.system(size: 12))
        }
    }
}

public struct LockCircularView: View {
    public let entry: WidgetEntry
    public init(entry: WidgetEntry) { self.entry = entry }
    @ViewBuilder
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
- [ ] **Step 2: Build** — complete. **Step 3: Commit** `git add Core/Sources/UmaCore/UI/Widget/LockWidgetViews.swift && git commit -m "feat: v3 lock rectangular (bracket title + race subtitle)"`

---

# Phase A5 — Fallback data, app, integration

### Task A5.1: v2 bundled fallback JSON
**Files:** Rewrite `Core/Sources/UmaCore/Resources/schedule_fallback.json`; bump cache key in `Core/Sources/UmaCore/DataSource/ScheduleRepository.swift`
- [ ] **Step 1:** Replace `schedule_fallback.json` with v2 example data:
```json
{
  "version": 2,
  "updatedAt": "2026-05-20T00:00:00Z",
  "sourcePostNo": 1850737,
  "server": "kr",
  "championsMeetings": [
    {
      "id": "cm-2026-07",
      "codeName": "LONG",
      "raceGrade": "G1",
      "raceName": "벚꽃상",
      "track": { "racecourse": "한신", "surface": "turf", "distanceMeters": 1600, "distanceClass": "mile",
                 "turn": "clockwise", "courseSide": "외측", "season": "봄", "weather": "맑음", "ground": "양호", "timeOfDay": "낮" },
      "period": { "start": "2026-07-14T00:00:00Z", "end": "2026-07-20T00:00:00Z", "estimated": true },
      "phases": [
        { "kind": "open",  "label": "오픈", "date": "2026-07-14T00:00:00Z" },
        { "kind": "ended", "label": "종료", "date": "2026-07-20T00:00:00Z" }
      ]
    }
  ],
  "leagueOfHeroes": [
    {
      "id": "loh-2026-10",
      "round": "10회차",
      "raceName": "스프린터즈 스테이크스",
      "track": { "racecourse": "나카야마", "surface": "turf", "distanceMeters": 1200, "distanceClass": "sprint",
                 "turn": "clockwise", "courseSide": "외측", "season": "겨울", "timeOfDay": "낮" },
      "period": { "start": "2026-06-07T00:00:00Z", "end": "2026-06-16T00:00:00Z", "estimated": true },
      "phases": [
        { "kind": "open",  "label": "오픈", "date": "2026-06-07T00:00:00Z" },
        { "kind": "ended", "label": "종료", "date": "2026-06-16T00:00:00Z" }
      ]
    }
  ],
  "pickups": [
    {
      "id": "pk-2026-06-15",
      "period": { "start": "2026-06-15T00:00:00Z", "end": "2026-06-21T00:00:00Z", "estimated": false },
      "trainees": ["오르페브르", "푸리오소"],
      "supportCards": [
        { "rarity": "SSR", "name": "아몬드 아이", "type": "스피드" },
        { "rarity": "SSR", "name": "메지로 브라이트", "type": "스태미나" }
      ]
    }
  ]
}
```
- [ ] **Step 2:** In `ScheduleRepository.swift` change the cache key:
```swift
    public static let cacheKey = "cache.schedule.v2"
```
- [ ] **Step 3: Run** `cd Core && swift test --filter ScheduleFallbackTests` — update that test's assertions if it referenced `championsMeetings`/`gachaBanners`; assert `doc.version == 2`, `!doc.championsMeetings.isEmpty`, `!doc.pickups.isEmpty`. PASS.
- [ ] **Step 4: Commit** `git add Core/Sources/UmaCore/Resources/schedule_fallback.json Core/Sources/UmaCore/DataSource/ScheduleRepository.swift Core/Tests/UmaCoreTests/ScheduleFallbackTests.swift && git commit -m "feat: v2 bundled fallback + bump cache key to v2"`

### Task A5.2: RootView pickup rendering
**Files:** Modify `App/RootView.swift`
- [ ] **Step 1:** `RootView.card(for:doc:)` already routes `.gacha` to `EventCardFactory.pickupCard(doc.pickups, ...)` once the method is renamed — update the `.gacha` case:
```swift
        case .gacha:            return EventCardFactory.pickupCard(doc.pickups, now: Date())
```
The list row uses `EventCardRow`, which now renders pickup/bracket correctly — no other change needed.
- [ ] **Step 2: Build** the app target (Task A5.3 covers full build). Commit `git add App/RootView.swift && git commit -m "refactor: RootView uses pickupCard"`

### Task A5.3: Full Core suite + iOS build
**Files:** none (verification)
- [ ] **Step 1: Run** `cd Core && swift test` — all pass.
- [ ] **Step 2: Run** `xcodegen generate && xcodebuild -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO` — `** BUILD SUCCEEDED **`. Fix any compile errors surfaced in App/Widgets that referenced old model shapes (e.g., a stray `gachaBanners`/`.name`/`.season`/`.direction` reference) — update to v2.
- [ ] **Step 3: Commit** any fixes: `git commit -am "fix: v2 schema integration build"`

---

## Self-Review Notes (planner)
- **Spec coverage (§3 schema):** EventPeriod (A1.1), TrackCondition expanded (A1.2), CM/LoH/PickupPeriod/SupportCardPick (A1.3), ScheduleDocument v2 (A1.4), EventCard v2 (A1.5). **§4 display matrix:** bracket titles + subtitle (A4.1–A4.5), condition chips L1 (A4.4), pickup full names S4/M3/L2 (A4.1/A4.2/A4.3), period+estimated (A2.1 + views). Localization (A3.1). Fallback v2 (A5.1).
- **Placeholder scan:** clean — en `field.estimated` ships as "Est." (an abbreviation of "Estimated", not a TODO marker).
- **Type consistency:** `EventCardFactory.pickupCard` (not `gachaCard`) used in resolver (A2.3) and RootView (A5.2); `EventCard` v2 init args (title/subtitle/period/trainees/supportCards) consistent across factory + views; `TrackCondition` new init (no `direction:`) used in all fixtures.
- **Out of scope (Workstream B):** the ingestion pipeline producing this JSON is a separate plan; this plan ships against the v2 bundled fallback + (still-placeholder) remote URL.

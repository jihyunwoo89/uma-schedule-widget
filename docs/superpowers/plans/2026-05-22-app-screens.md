# 인앱 화면 (일정 브라우저) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱 본체를 탭바(일정/설정) 기반 일정 브라우저로 만들어 챔미·LoH·픽업 전체 예정 일정과 이벤트 상세를 위젯과 동일한 톤으로 보여준다.

**Architecture:** 코어(UmaCore)에 카테고리별 예정 목록·항목별 카드 팩토리 메서드를 추가하고 색 토큰을 공개한다. 앱 타깃(App/)에 TabView 셸 + 세그먼트 일정 리스트 + 이벤트 상세 뷰를 추가하며, 위젯에서 만든 공개 디자인 컴포넌트(CategoryBadge/GradeBadge/RarityBadge/SupportTypeIcon/DDayStack/BracketTitle/RaceNameLine/TrackLines/TrackImageView/PickupBlock)를 재사용한다. 데이터는 위젯과 동일한 `ScheduleRepository → ScheduleDocument`.

**Tech Stack:** Swift 5.10, SwiftUI, WidgetKit(공유 컴포넌트), Swift Package(UmaCore) + Xcode 앱 타깃, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-05-22-app-screens-design.md`

**Verify commands:**
- Core: `cd Core && swift test`
- 앱+위젯 컴파일: `xcodegen generate && xcodebuild build -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/uma_dd CODE_SIGNING_ALLOWED=NO`

---

## File Structure

**Core (UmaCore) — 수정:**
- `Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift` — `WidgetColors`를 `public`으로.
- `Core/Sources/UmaCore/Logic/EventCardFactory.swift` — 항목별 카드(`…Card(for:now:)`) + 카테고리별 예정 목록(`upcoming…`) 추가, 기존 "가장 임박" 메서드는 재사용하도록 리팩터.
- `Core/Sources/UmaCore/Localization/L.swift` + `Resources/{ko,en}.lproj/Localizable.strings` — 앱 화면 키 추가.
- `Core/Tests/UmaCoreTests/EventCardFactoryTests.swift` — 신규 메서드 테스트 추가.

**App 타깃 — 신규/수정:**
- `App/RootView.swift` — (수정) List 대신 TabView(일정/설정) 셸. struct 이름 `RootView` 유지(앱 진입점 변경 불필요).
- `App/AppNavigation.swift` — (신규) `DetailTarget` enum + `ScheduleItem`.
- `App/ScheduleCards.swift` — (신규) `ScheduleHeroCard`, `ScheduleRowCard`.
- `App/ScheduleListView.swift` — (신규) 세그먼트 + 히어로 + 목록 + 로드/상태.
- `App/EventDetailView.swift` — (신규) 챔미/LoH 상세 + 픽업 상세.
- `App/SettingsView.swift` — (유지) 변경 없음.

각 파일은 단일 책임: 리스트=목록/네비게이션, 상세=한 이벤트, 카드=한 행 렌더, 네비=라우팅 타입.

---

## Task 1: 색 토큰 공개화 (WidgetColors → public)

**Files:**
- Modify: `Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift:6`

- [ ] **Step 1: WidgetColors를 public으로 변경**

`WidgetPieces.swift`의 `enum WidgetColors { ... }` 선언과 각 static 멤버를 public으로:

```swift
public enum WidgetColors {
    public static let title    = Color(hex: "#1B1E24") ?? .primary
    public static let raceName = Color(hex: "#2B2F36") ?? .primary
    public static let subtitle = Color(hex: "#5B616B") ?? .secondary
    public static let cond     = Color(hex: "#7B818B") ?? .secondary
    public static let muted    = Color(hex: "#9AA0A8") ?? .secondary
    public static let star     = Color(hex: "#E8A11A") ?? .yellow
}
```

- [ ] **Step 2: 빌드 확인**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 3: 커밋**

```bash
git add Core/Sources/UmaCore/UI/Widget/WidgetPieces.swift
git commit -m "refactor(core): make WidgetColors public for app reuse"
```

---

## Task 2: 항목별 카드 팩토리 (`…Card(for:now:)`)

**Files:**
- Modify: `Core/Sources/UmaCore/Logic/EventCardFactory.swift`
- Test: `Core/Tests/UmaCoreTests/EventCardFactoryTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

`EventCardFactoryTests.swift`에 추가(파일 상단 `import` / 기존 헬퍼 재사용; 날짜 헬퍼가 없으면 아래처럼 인라인):

```swift
func test_championsCard_forItem_mapsFields() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let track = TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile, turn: .clockwise, season: "봄")
    let period = EventPeriod(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(2*86400), estimated: true)
    let cm = ChampionsMeeting(id: "cm1", codeName: "MILE", raceGrade: "G1", raceName: "벚꽃상",
                              track: track, period: period,
                              phases: [EventPhase(kind: .open, label: "오픈", date: now.addingTimeInterval(86400))])
    let card = EventCardFactory.championsCard(for: cm, now: now)
    XCTAssertEqual(card.title, "MILE")
    XCTAssertEqual(card.subtitle, "벚꽃상")
    XCTAssertEqual(card.raceGrade, "G1")
    XCTAssertEqual(card.category, .championsMeeting)
    XCTAssertEqual(card.track?.racecourse, "한신")
}

func test_leagueCard_forItem_parsesGradeFromRaceName() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let track = TrackCondition(racecourse: "나카야마", surface: .turf, distanceMeters: 1200, distanceClass: .sprint)
    let period = EventPeriod(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(2*86400))
    let loh = LeagueOfHeroes(id: "loh1", round: "10회차", raceName: "G1 스프린터즈 스테이크스",
                             track: track, period: period,
                             phases: [EventPhase(kind: .open, label: "오픈", date: now.addingTimeInterval(86400))])
    let card = EventCardFactory.leagueCard(for: loh, now: now)
    XCTAssertEqual(card.title, "10회차")
    XCTAssertEqual(card.raceGrade, "G1")
    XCTAssertEqual(card.subtitle, "스프린터즈 스테이크스")
}

func test_pickupCard_forItem_upcomingVsActive() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let upcoming = PickupPeriod(id: "p1", period: EventPeriod(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(3*86400)),
                                trainees: ["오르페브르 3★"], supportCards: [])
    let upCard = EventCardFactory.pickupCard(for: upcoming, now: now)
    XCTAssertEqual(upCard.status, .upcoming)
    XCTAssertEqual(upCard.phaseLabel, "시작까지")
    XCTAssertEqual(upCard.targetDate, upcoming.period.start)

    let active = PickupPeriod(id: "p2", period: EventPeriod(start: now.addingTimeInterval(-86400), end: now.addingTimeInterval(86400)),
                              trainees: ["푸리오소 3★"], supportCards: [])
    let actCard = EventCardFactory.pickupCard(for: active, now: now)
    XCTAssertEqual(actCard.status, .active)
    XCTAssertEqual(actCard.phaseLabel, "종료까지")
    XCTAssertEqual(actCard.targetDate, active.period.end)
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `cd Core && swift test --filter EventCardFactoryTests`
Expected: 컴파일 실패 — `championsCard(for:now:)` 등 미정의.

- [ ] **Step 3: 항목별 메서드 구현 (EventCardFactory.swift)**

`EventCardFactory` enum 안에 추가:

```swift
public static func championsCard(for cm: ChampionsMeeting, now: Date) -> EventCard {
    let r = cm.resolution(now: now)
    return EventCard(category: .championsMeeting, title: cm.codeName, subtitle: cm.raceName,
                     track: cm.track, period: cm.period, phaseLabel: phaseLabel(for: r),
                     targetDate: r.targetDate, status: r.status, raceGrade: cm.raceGrade)
}

public static func leagueCard(for loh: LeagueOfHeroes, now: Date) -> EventCard {
    let r = loh.resolution(now: now)
    let (grade, name) = GradeParse.leading(loh.raceName)
    return EventCard(category: .leagueOfHeroes, title: loh.round, subtitle: name,
                     track: loh.track, period: loh.period, phaseLabel: phaseLabel(for: r),
                     targetDate: r.targetDate, status: r.status, raceGrade: grade)
}

public static func pickupCard(for p: PickupPeriod, now: Date) -> EventCard {
    let upcoming = p.period.start > now
    let status: EventStatus = upcoming ? .upcoming : (now < p.period.end ? .active : .ended)
    return EventCard(category: .gacha, title: p.trainees.joined(separator: ", "),
                     period: p.period, phaseLabel: upcoming ? "시작까지" : "종료까지",
                     targetDate: upcoming ? p.period.start : p.period.end, status: status,
                     trainees: p.trainees, supportCards: p.supportCards)
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `cd Core && swift test --filter EventCardFactoryTests`
Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add Core/Sources/UmaCore/Logic/EventCardFactory.swift Core/Tests/UmaCoreTests/EventCardFactoryTests.swift
git commit -m "feat(core): per-item event card factory methods"
```

---

## Task 3: 카테고리별 예정 목록 (`upcoming…`)

**Files:**
- Modify: `Core/Sources/UmaCore/Logic/EventCardFactory.swift`
- Test: `Core/Tests/UmaCoreTests/EventCardFactoryTests.swift`

- [ ] **Step 1: 실패 테스트 작성**

```swift
func test_upcomingChampions_sortedAndExcludesEnded() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    func cm(_ id: String, openInDays: Double, endedDaysAgo: Double? = nil) -> ChampionsMeeting {
        let t = TrackCondition(racecourse: "한신", surface: .turf, distanceMeters: 1600, distanceClass: .mile)
        let phases: [EventPhase]
        if let ago = endedDaysAgo {
            phases = [EventPhase(kind: .ended, label: "종료", date: now.addingTimeInterval(-ago*86400))]
        } else {
            phases = [EventPhase(kind: .open, label: "오픈", date: now.addingTimeInterval(openInDays*86400)),
                      EventPhase(kind: .ended, label: "종료", date: now.addingTimeInterval((openInDays+3)*86400))]
        }
        return ChampionsMeeting(id: id, codeName: id, raceGrade: "G1", raceName: "x",
                                track: t, period: EventPeriod(start: now, end: now.addingTimeInterval(86400)), phases: phases)
    }
    let list = EventCardFactory.upcomingChampions([cm("late", openInDays: 50), cm("soon", openInDays: 5), cm("done", openInDays: 0, endedDaysAgo: 2)], now: now)
    XCTAssertEqual(list.map { $0.id }, ["soon", "late"])  // ended excluded, sorted by target
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `cd Core && swift test --filter test_upcomingChampions_sortedAndExcludesEnded`
Expected: 컴파일 실패 — `upcomingChampions` 미정의.

- [ ] **Step 3: 구현 + 기존 메서드 리팩터 (EventCardFactory.swift)**

추가:

```swift
public static func upcomingChampions(_ meetings: [ChampionsMeeting], now: Date) -> [ChampionsMeeting] {
    meetings.map { ($0, $0.resolution(now: now)) }
            .filter { $0.1.status != .ended }
            .sorted { $0.1.targetDate < $1.1.targetDate }
            .map { $0.0 }
}

public static func upcomingLeagues(_ leagues: [LeagueOfHeroes], now: Date) -> [LeagueOfHeroes] {
    leagues.map { ($0, $0.resolution(now: now)) }
           .filter { $0.1.status != .ended }
           .sorted { $0.1.targetDate < $1.1.targetDate }
           .map { $0.0 }
}

public static func upcomingPickups(_ pickups: [PickupPeriod], now: Date) -> [PickupPeriod] {
    pickups.filter { now < $0.period.end }
           .sorted { lhs, rhs in
               let lt = lhs.period.start > now ? lhs.period.start : lhs.period.end
               let rt = rhs.period.start > now ? rhs.period.start : rhs.period.end
               return lt < rt
           }
}
```

기존 "가장 임박" 메서드는 위를 재사용하도록 교체:

```swift
public static func championsCard(_ meetings: [ChampionsMeeting], now: Date) -> EventCard? {
    guard let cm = upcomingChampions(meetings, now: now).first else { return nil }
    return championsCard(for: cm, now: now)
}

public static func leagueCard(_ leagues: [LeagueOfHeroes], now: Date) -> EventCard? {
    guard let loh = upcomingLeagues(leagues, now: now).first else { return nil }
    return leagueCard(for: loh, now: now)
}
```

(`pickupCard(_:now:)`는 active 우선 로직을 유지하기 위해 기존 구현 그대로 둔다.)

- [ ] **Step 4: 전체 테스트 통과 확인**

Run: `cd Core && swift test`
Expected: 기존 + 신규 전부 PASS (실행 테스트 수 증가, 0 failures)

- [ ] **Step 5: 커밋**

```bash
git add Core/Sources/UmaCore/Logic/EventCardFactory.swift Core/Tests/UmaCoreTests/EventCardFactoryTests.swift
git commit -m "feat(core): upcoming-events list factory methods"
```

---

## Task 4: 앱 화면 로컬라이즈 키

**Files:**
- Modify: `Core/Sources/UmaCore/Localization/L.swift`
- Modify: `Core/Sources/UmaCore/Resources/ko.lproj/Localizable.strings`
- Modify: `Core/Sources/UmaCore/Resources/en.lproj/Localizable.strings`

- [ ] **Step 1: L.Key 케이스 추가**

`L.Key` enum에 추가:

```swift
        case tabSchedule           = "tab.schedule"
        case tabSettings           = "tab.settings"
        case scheduleSectionUpcoming = "schedule.section.upcoming"
        case detailSectionTrack    = "detail.section.track"
        case detailSectionPhases   = "detail.section.phases"
        case detailFieldPeriod     = "detail.field.period"
```

- [ ] **Step 2: ko 문자열 추가**

`ko.lproj/Localizable.strings` 끝에:

```
"tab.schedule" = "일정";
"tab.settings" = "설정";
"schedule.section.upcoming" = "예정";
"detail.section.track" = "마장";
"detail.section.phases" = "단계";
"detail.field.period" = "기간";
```

- [ ] **Step 3: en 문자열 추가**

`en.lproj/Localizable.strings` 끝에:

```
"tab.schedule" = "Schedule";
"tab.settings" = "Settings";
"schedule.section.upcoming" = "Upcoming";
"detail.section.track" = "Course";
"detail.section.phases" = "Phases";
"detail.field.period" = "Period";
```

- [ ] **Step 4: 빌드 확인**

Run: `cd Core && swift build`
Expected: `Build complete!`

- [ ] **Step 5: 커밋**

```bash
git add Core/Sources/UmaCore/Localization/L.swift Core/Sources/UmaCore/Resources
git commit -m "feat(core): localization keys for app screens"
```

---

## Task 5: 네비게이션 타입 + TabView 셸

**Files:**
- Create: `App/AppNavigation.swift`
- Modify: `App/RootView.swift`

- [ ] **Step 1: AppNavigation.swift 작성**

```swift
import Foundation
import UmaCore

/// Navigation value for the detail screen — carries the domain model so detail can show phases.
enum DetailTarget: Hashable {
    case champions(ChampionsMeeting)
    case league(LeagueOfHeroes)
    case pickup(PickupPeriod)
}

/// A list row: the display card + where tapping goes.
struct ScheduleItem: Identifiable {
    let id: String
    let card: EventCard
    let target: DetailTarget
}
```

- [ ] **Step 2: RootView.swift를 TabView 셸로 교체**

`App/RootView.swift` 전체를:

```swift
import SwiftUI
import UmaCore

/// App root: tab bar with Schedule + Settings.
struct RootView: View {
    @Bindable var prefs: PrefsStore

    var body: some View {
        TabView {
            ScheduleListView()
                .tabItem { Label(L.string(.tabSchedule), systemImage: "calendar") }
            NavigationStack {
                SettingsView(prefs: prefs)
            }
            .tabItem { Label(L.string(.tabSettings), systemImage: "gearshape") }
        }
    }
}
```

- [ ] **Step 3: 컴파일 확인 (ScheduleListView가 아직 없으므로 Task 7 후 빌드)**

이 단계에서는 빌드하지 않는다(다음 태스크에서 `ScheduleListView` 정의). 진행만 하고 Task 7 끝에 일괄 빌드.

- [ ] **Step 4: 커밋**

```bash
git add App/AppNavigation.swift App/RootView.swift
git commit -m "feat(app): tab bar shell + navigation types"
```

---

## Task 6: 카드 뷰 (ScheduleHeroCard / ScheduleRowCard)

**Files:**
- Create: `App/ScheduleCards.swift`

- [ ] **Step 1: ScheduleCards.swift 작성**

```swift
import SwiftUI
import UmaCore

/// Big "next event" card for the top of each category list.
struct ScheduleHeroCard: View {
    let card: EventCard
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category)
                Spacer(minLength: 4)
                DDayStack(targetDate: card.targetDate, now: Date(),
                          dateText: card.period.map { PeriodFormatter.startShort($0) } ?? card.phaseLabel,
                          ddaySize: 24, dateSize: 11)
            }
            if card.category == .gacha {
                PickupBlock(trainees: card.trainees, supports: card.supportCards, headerSize: 12.5, lineSize: 12, spacing: 3)
            } else {
                BracketTitle(card.title, size: 20)
                RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 13)
                if let t = card.track { TrackLines(track: t, distanceSize: 12, condSize: 11) }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(card.category.accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(card.category.accentColor.opacity(0.20), lineWidth: 1)
        )
    }
}

/// Smaller uniform card for subsequent upcoming events.
struct ScheduleRowCard: View {
    let card: EventCard
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if card.category == .gacha {
                    Text(card.trainees.map { PickupFormatter.trainee($0).name }.joined(separator: " · "))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WidgetColors.raceName)
                        .lineLimit(2)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        BracketTitle(card.title, size: 15)
                        RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 12)
                    }
                    if let t = card.track {
                        Text(t.distanceLine).font(.system(size: 11)).foregroundStyle(WidgetColors.cond).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 4)
            DDayStack(targetDate: card.targetDate, now: Date(),
                      dateText: card.period.map { PeriodFormatter.startShort($0) } ?? "",
                      ddaySize: 17, dateSize: 10)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
```

- [ ] **Step 2: (빌드는 Task 7 후 일괄) 커밋**

```bash
git add App/ScheduleCards.swift
git commit -m "feat(app): hero + row schedule cards"
```

---

## Task 7: 일정 리스트 뷰 (세그먼트 + 히어로 + 목록)

**Files:**
- Create: `App/ScheduleListView.swift`

- [ ] **Step 1: ScheduleListView.swift 작성**

```swift
import SwiftUI
import UmaCore

struct ScheduleListView: View {
    @State private var document: ScheduleDocument?
    @State private var loadFailed = false
    @State private var category: EventCategory = .championsMeeting
    private let now = Date()

    var body: some View {
        NavigationStack {
            Group {
                if let doc = document {
                    listContent(doc)
                } else if loadFailed {
                    WidgetMessageView(titleKey: .stateNoDataTitle, bodyKey: .stateNoDataBody)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(L.string(.tabSchedule))
            .navigationDestination(for: DetailTarget.self) { EventDetailView(target: $0) }
            .task { if document == nil { await load() } }
            .refreshable { await load() }
        }
    }

    @ViewBuilder
    private func listContent(_ doc: ScheduleDocument) -> some View {
        ScrollView {
            Picker("", selection: $category) {
                Text(L.string(.categoryChampions)).tag(EventCategory.championsMeeting)
                Text(L.string(.categoryLoH)).tag(EventCategory.leagueOfHeroes)
                Text(L.string(.categoryPickup)).tag(EventCategory.gacha)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.top, 6)

            let items = items(for: category, doc: doc)
            if items.isEmpty {
                Text(L.string(.stateIdleTitle))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.top, 40)
            } else {
                LazyVStack(spacing: 10) {
                    NavigationLink(value: items[0].target) {
                        ScheduleHeroCard(card: items[0].card)
                    }.buttonStyle(.plain)

                    if items.count > 1 {
                        HStack {
                            Text(L.string(.scheduleSectionUpcoming))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(WidgetColors.muted)
                                .textCase(.uppercase)
                            Spacer()
                        }.padding(.top, 4).padding(.horizontal, 2)
                        ForEach(items.dropFirst()) { item in
                            NavigationLink(value: item.target) {
                                ScheduleRowCard(card: item.card)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 16)
            }
        }
    }

    private func items(for category: EventCategory, doc: ScheduleDocument) -> [ScheduleItem] {
        switch category {
        case .championsMeeting:
            return EventCardFactory.upcomingChampions(doc.championsMeetings, now: now).map {
                ScheduleItem(id: $0.id, card: EventCardFactory.championsCard(for: $0, now: now), target: .champions($0))
            }
        case .leagueOfHeroes:
            return EventCardFactory.upcomingLeagues(doc.leagueOfHeroes, now: now).map {
                ScheduleItem(id: $0.id, card: EventCardFactory.leagueCard(for: $0, now: now), target: .league($0))
            }
        case .gacha:
            return EventCardFactory.upcomingPickups(doc.pickups, now: now).map {
                ScheduleItem(id: $0.id, card: EventCardFactory.pickupCard(for: $0, now: now), target: .pickup($0))
            }
        }
    }

    private func load() async {
        do {
            document = try await ScheduleRepository.makeLive().current()
            loadFailed = false
        } catch { loadFailed = true }
    }
}
```

- [ ] **Step 2: 프로젝트 재생성 + 컴파일 (EventDetailView는 다음 태스크 — 임시 스텁 추가)**

`EventDetailView`가 아직 없으므로, 빌드 통과를 위해 **임시 스텁**을 `App/EventDetailView.swift`에 먼저 둔다:

```swift
import SwiftUI
import UmaCore

struct EventDetailView: View {
    let target: DetailTarget
    var body: some View { Text("detail") }
}
```

Run: `xcodegen generate && xcodebuild build -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/uma_dd CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add App/ScheduleListView.swift App/EventDetailView.swift
git commit -m "feat(app): schedule list view (segmented + hero + list)"
```

---

## Task 8: 이벤트 상세 — 챔미 / LoH

**Files:**
- Modify: `App/EventDetailView.swift` (스텁 교체)

- [ ] **Step 1: 공통 상세 컴포넌트 + 챔미/LoH 분기 작성**

`App/EventDetailView.swift`를 다음으로 교체(픽업 분기는 Task 9에서 추가; 지금은 픽업도 컴파일되도록 최소 처리 포함):

```swift
import SwiftUI
import UmaCore

struct EventDetailView: View {
    let target: DetailTarget
    private let now = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch target {
                case .champions(let cm):
                    raceDetail(card: EventCardFactory.championsCard(for: cm, now: now),
                               track: cm.track, phases: cm.phases)
                case .league(let loh):
                    raceDetail(card: EventCardFactory.leagueCard(for: loh, now: now),
                               track: loh.track, phases: loh.phases)
                case .pickup(let p):
                    PickupDetailBody(pickup: p, now: now)
                }
                disclaimer
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func raceDetail(card: EventCard, track: TrackCondition, phases: [EventPhase]) -> some View {
        // Hero
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                CategoryBadge(category: card.category)
                Spacer()
                DDayStack(targetDate: card.targetDate, now: now,
                          dateText: card.phaseLabel, ddaySize: 30, dateSize: 11)
            }
            BracketTitle(card.title, size: 26)
            RaceNameLine(grade: card.raceGrade, name: card.subtitle, size: 14)
            if let p = card.period {
                Text("\(L.string(.detailFieldPeriod)) · \(PeriodFormatter.range(p))")
                    .font(.system(size: 12)).foregroundStyle(WidgetColors.muted).padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(card.category.accentColor.opacity(0.08)))

        // Track
        SectionLabel(.detailSectionTrack)
        TrackImageView(track: track).frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        Text(track.distanceLine).font(.system(size: 14, weight: .bold)).foregroundStyle(WidgetColors.raceName)
        let chips = track.conditionChips
        if !chips.isEmpty {
            ConditionChipsWrap(chips: chips)
        }

        // Phases
        if !phases.isEmpty {
            SectionLabel(.detailSectionPhases)
            PhaseTimeline(phases: phases, accent: card.category.accentColor, now: now)
        }
    }

    private var disclaimer: some View {
        Text(L.string(.legalDisclaimer))
            .font(.system(size: 10)).foregroundStyle(WidgetColors.muted)
            .padding(.top, 4)
    }
}

/// Uppercase muted section label.
struct SectionLabel: View {
    let key: L.Key
    init(_ key: L.Key) { self.key = key }
    var body: some View {
        Text(L.string(key)).font(.system(size: 11, weight: .bold))
            .foregroundStyle(WidgetColors.muted).textCase(.uppercase)
            .padding(.top, 6)
    }
}

/// Wrapping condition chips (방향·계절·날씨 등).
struct ConditionChipsWrap: View {
    let chips: [String]
    var body: some View {
        let rows = stride(from: 0, to: chips.count, by: 3).map { Array(chips[$0..<min($0+3, chips.count)]) }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { c in
                        Text(c).font(.system(size: 11)).foregroundStyle(WidgetColors.subtitle)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05)).clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// Vertical phase list: done (filled) / current (filled + d-day) / future (hollow).
struct PhaseTimeline: View {
    let phases: [EventPhase]
    let accent: Color
    let now: Date
    var body: some View {
        let sorted = phases.sorted { $0.date < $1.date }
        VStack(spacing: 0) {
            ForEach(Array(sorted.enumerated()), id: \.offset) { idx, ph in
                let isCurrent = ph.date > now && (idx == 0 || sorted[idx-1].date <= now)
                HStack(spacing: 10) {
                    Circle()
                        .fill(ph.date <= now || isCurrent ? accent : Color.clear)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(accent, lineWidth: 2))
                    Text(ph.label).font(.system(size: 13, weight: .semibold)).foregroundStyle(WidgetColors.title)
                    if isCurrent {
                        Text(CountdownFormatter.ddayLabel(days: CountdownFormatter.daysUntil(ph.date, from: now)))
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(accent)
                    }
                    Spacer()
                    Text(PeriodFormatter.startShort(EventPeriod(start: ph.date, end: ph.date)))
                        .font(.system(size: 12)).foregroundStyle(WidgetColors.subtitle)
                }
                .padding(.vertical, 8)
                if idx < sorted.count - 1 { Divider() }
            }
        }
        .padding(.horizontal, 13)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }
}

/// Placeholder so the file compiles before Task 9 fills it in.
struct PickupDetailBody: View {
    let pickup: PickupPeriod
    let now: Date
    var body: some View { EmptyView() }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `xcodegen generate && xcodebuild build -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/uma_dd CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add App/EventDetailView.swift
git commit -m "feat(app): champions/LoH event detail (hero + track + phase timeline)"
```

---

## Task 9: 이벤트 상세 — 픽업

**Files:**
- Modify: `App/EventDetailView.swift` (`PickupDetailBody` 교체)

- [ ] **Step 1: PickupDetailBody 구현**

`PickupDetailBody`(placeholder)를 다음으로 교체:

```swift
struct PickupDetailBody: View {
    let pickup: PickupPeriod
    let now: Date
    var body: some View {
        let card = EventCardFactory.pickupCard(for: pickup, now: now)
        VStack(alignment: .leading, spacing: 14) {
            // Hero
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    CategoryBadge(category: .gacha)
                    Spacer()
                    DDayStack(targetDate: card.targetDate, now: now, dateText: card.phaseLabel, ddaySize: 30, dateSize: 11)
                }
                Text("\(L.string(.detailFieldPeriod)) · \(PeriodFormatter.range(pickup.period))")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(WidgetColors.raceName)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(EventCategory.gacha.accentColor.opacity(0.08)))

            // Trainees
            if !pickup.trainees.isEmpty {
                Text(L.string(.fieldTrainee)).font(.system(size: 13, weight: .heavy)).foregroundStyle(WidgetColors.title)
                VStack(spacing: 0) {
                    ForEach(Array(pickup.trainees.enumerated()), id: \.offset) { idx, t in
                        let parsed = PickupFormatter.trainee(t)
                        HStack(spacing: 8) {
                            if let stars = parsed.stars, let tier = RarityTier("\(stars)★") {
                                RarityBadge(text: "\(stars)★", tier: tier)
                            }
                            Text(parsed.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(WidgetColors.raceName)
                            Spacer()
                        }.padding(.vertical, 9)
                        if idx < pickup.trainees.count - 1 { Divider() }
                    }
                }.padding(.horizontal, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            }

            // Support cards
            if !pickup.supportCards.isEmpty {
                Text(L.string(.fieldSupport)).font(.system(size: 13, weight: .heavy)).foregroundStyle(WidgetColors.title)
                VStack(spacing: 0) {
                    ForEach(Array(pickup.supportCards.enumerated()), id: \.offset) { idx, s in
                        HStack(spacing: 8) {
                            if let tier = RarityTier(s.rarity) { RarityBadge(text: s.rarity, tier: tier) }
                            Text(s.name).font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SupportType.color(forType: s.type) ?? WidgetColors.raceName)
                            Spacer()
                            SupportTypeIcon(type: s.type, size: 20)
                        }.padding(.vertical, 9)
                        if idx < pickup.supportCards.count - 1 { Divider() }
                    }
                }.padding(.horizontal, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
            }
        }
    }
}
```

- [ ] **Step 2: 컴파일 확인**

Run: `xcodegen generate && xcodebuild build -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/uma_dd CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
git add App/EventDetailView.swift
git commit -m "feat(app): pickup event detail (trainees + support cards)"
```

---

## Task 10: 최종 통합 검증

**Files:** (없음 — 검증/정리)

- [ ] **Step 1: 코어 테스트 전체 통과**

Run: `cd Core && swift test 2>&1 | grep -E "Executed [0-9]+ tests"`
Expected: `Executed N tests, with 0 failures` (N ≥ 97 + 신규)

- [ ] **Step 2: 앱 + 위젯 풀 빌드**

Run: `cd /Users/damienjee/Desktop/claude_dev/uma_schedule_widget && xcodegen generate && xcodebuild build -project UmaSchedule.xcodeproj -scheme UmaSchedule -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/uma_dd CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 댕글링 참조 확인**

Run: `grep -rn "EventCardRow" App/ | grep -v "//"` (RootView가 더 이상 사용하지 않음 — 결과 없거나 의도된 사용만)
Expected: App/에서 제거됨(또는 의도적 사용만 남음). 남은 참조가 있으면 정리.

- [ ] **Step 4: 시뮬레이터 시각 QA (수동, 사용자)**

사용자가 Xcode 시뮬레이터로: 탭바(일정/설정), 세그먼트 전환(챔미/LoH/픽업), 히어로+목록, 상세(마장 이미지·단계 / 육성마·서포트) 렌더 확인.

- [ ] **Step 5: 최종 커밋(필요 시)**

```bash
git add -A -- ':!**/* 2.*'   # 충돌 파일 제외
git commit -m "chore(app): finalize in-app schedule browser screens" || echo "nothing to commit"
```

---

## Self-Review 메모
- 스펙 §3 화면(일정 탭/상세/설정) → Task 5~9로 커버. §4 데이터/팩토리 → Task 2~3. §5 색 토큰 → Task 1. 로컬라이즈 → Task 4. §7 테스트 → Task 2~3, 10.
- 타입 일관성: `DetailTarget`(.champions/.league/.pickup), `ScheduleItem(id,card,target)`, `EventCardFactory.{championsCard(for:now:),leagueCard(for:now:),pickupCard(for:now:),upcomingChampions,upcomingLeagues,upcomingPickups}`, `WidgetColors`(public), `SectionLabel/ConditionChipsWrap/PhaseTimeline/PickupDetailBody` — 태스크 간 동일.
- 픽업 상세 hero는 마장 없음(스펙 §3.2). 셀렉트 픽업(서포트 0) → 서포트 섹션 자동 생략(Task 9 if 조건).

# 우마무스메 스케줄 위젯 — 설계 문서

작성일: 2026-05-21
대상: 한국 서버 (카카오게임즈) 우마무스메 프리티 더비

## 1. 목적

iOS 홈/잠금화면 위젯으로 한국 서버 우마무스메의 다음 일정을 한눈에 보여준다. 직전에 만든 LCK 위젯(`../lckwidget`)과 동일한 형태/아키텍처를 따른다.

보여줄 내용 3가지:

1. 다음 챔피언스 미팅 (일정, d-day, 마장 정보)
2. 다음 리그 오브 히어로즈(LoH) (일정, d-day, 마장 정보)
3. 다음 육성마 / 서포트카드 픽업 (일정, 픽업 대상)

## 2. 핵심 결정 사항

| 항목 | 결정 |
|------|------|
| 서버/지역 | 한국 서버 |
| 데이터 소스 | 원격 JSON fetch + 번들 JSON fallback (LCK의 fetch+fallback 패턴 동일) |
| 위젯 구성 | 카테고리 전용 위젯 + 통합 Large 위젯 둘 다 |
| 배포 | 앱스토어 (한/영 다국어, 개인정보처리방침, 스크린샷 등 풀 폴리시) |
| d-day 기준 | 현재 시각 이후 가장 가까운 다음 단계(phase)로 자동 전환 |

## 3. 아키텍처 / 프로젝트 구조

LCK 위젯과 동일 패턴: XcodeGen + SPM Core 패키지 + WidgetKit 익스텐션 + 얇은 앱 타깃.

```
uma_schedule_widget/
├── project.yml                 # XcodeGen, 번들 prefix com.damienjee, iOS 17+, Swift 5.10
├── App/                        # 얇은 iOS 앱: 설정(카테고리/폰트/언어/알림), 수동 새로고침, 백그라운드 갱신
├── Core/  (SPM: UmaCore)
│   ├── Package.swift
│   └── Sources/UmaCore/
│       ├── Models/             # ScheduleDocument, ChampionsMeeting, LeagueOfHeroes, GachaBanner,
│       │                       #   TrackCondition, EventPhase, EventCard, UserPrefs
│       ├── DataSource/         # ScheduleRepository(캐시 TTL + stale fallback), RemoteScheduleClient
│       ├── Cache/              # AppGroupStore (UserDefaults + App Group)
│       ├── Widgets/            # WidgetEntry, WidgetState, ScheduleStateResolver, SwiftUI 뷰
│       ├── Localization/       # L.swift + ko/en .lproj
│       └── Resources/          # schedule_fallback.json (번들 fallback)
├── Widgets/                    # WidgetKit 익스텐션: 위젯 정의 + TimelineProvider + WidgetBundle
├── Resources/                  # 앱 .lproj
├── Tests/                      # Core 단위 테스트
├── scripts/                    # 번들 fallback 갱신 스크립트
└── docs/                       # 스펙, 앱스토어 자료, privacy/support HTML
```

- 배포 타깃: iOS 17.0+, iPhone, Swift 5.10
- App Group: `group.com.damienjee.umaschedule` (앱 ↔ 위젯 데이터 공유)
- 번들 ID prefix: `com.damienjee.umaschedule`
- FontTheme(system / rounded / mono / serif) 및 잠금화면 위젯 패턴은 LCK Core에서 차용

### 데이터 흐름

1. 위젯 `ScheduleTimelineProvider.getTimeline()` 호출
2. `ScheduleRepository.current()` — 캐시 TTL 확인 → 원격 JSON fetch → 실패 시 stale 캐시 → 번들 JSON
3. `ScheduleStateResolver` — UserPrefs(표시 카테고리/순서) + ScheduleDocument로 카테고리별 `EventCard` 계산
4. `WidgetEntry`(date, state, cards, fontTheme) 반환
5. TimelineProvider가 다음 phase 전환 시각 기반으로 새로고침 정책 계산

### 갱신 정책

- 다음 단계 전환 시각 직후에 새로고침
- 평상시 6시간, 임박(다음 phase까지 24h 이내) 1시간
- 원격 JSON은 BGAppRefreshTask로 하루 1~2회 fetch
- AppGroupStore TTL 봉투 + stale-value fallback (네트워크 실패 시 마지막 성공 데이터 사용)

## 4. 데이터 모델 & 원격 JSON 스키마

핵심 원칙: **각 이벤트는 날짜순 `phases` 배열을 가진다.** d-day는 "현재 시각 이후 가장 가까운 phase"로 자동 전환된다.

```swift
struct ScheduleDocument: Codable, Sendable {   // 원격 JSON 루트
    var version: Int
    var updatedAt: Date
    var server: String                  // "kr"
    var championsMeetings: [ChampionsMeeting]
    var leagueOfHeroes: [LeagueOfHeroes]
    var gachaBanners: [GachaBanner]
}

struct TrackCondition: Codable, Sendable {     // 마장 정보
    var racecourse: String   // 경마장: "도쿄"/"나카야마"/"한신"...
    var distanceMeters: Int  // 거리: 2400
    var surface: Surface     // 바바: turf(잔디)/dirt(더트)
    var direction: String?   // 방향: 좌/우/직선
}
enum Surface: String, Codable { case turf, dirt }

struct EventPhase: Codable, Sendable {
    var kind: PhaseKind      // open / round1 / round2 / ended
    var label: String        // 표시명: "라운드1", "결승"...
    var date: Date           // 시작 시각 (KST)
}
enum PhaseKind: String, Codable { case open, round1, round2, ended }

struct ChampionsMeeting: Codable, Sendable {
    var id: String
    var name: String         // "리브르(LIBRA)" 등 미팅명
    var track: TrackCondition
    var phases: [EventPhase] // 오픈→라운드1→라운드2→종료
}

struct LeagueOfHeroes: Codable, Sendable {
    var id: String
    var season: String       // 시즌/회차명
    var track: TrackCondition
    var phases: [EventPhase]
}

struct GachaBanner: Codable, Sendable {
    var id: String
    var type: BannerType     // trainee(육성마) / supportCard(서포트카드)
    var featured: [String]   // 픽업 대상명: ["오구리 캡", ...]
    var startDate: Date
    var endDate: Date
}
enum BannerType: String, Codable { case trainee, supportCard }
```

위젯이 그리는 파생 모델:

```swift
struct EventCard: Codable, Hashable, Sendable {
    var category: EventCategory      // championsMeeting / leagueOfHeroes / gacha
    var title: String                // 미팅명 / 시즌명 / 픽업 대상
    var trackSummary: String?        // "도쿄 · 잔디 2400m" (gacha는 nil)
    var phaseLabel: String           // "라운드1까지" / "진행중" / "오픈까지"
    var targetDate: Date             // d-day 기준일
    var status: EventStatus          // upcoming / active / ended
}
enum EventCategory: String, Codable { case championsMeeting, leagueOfHeroes, gacha }
enum EventStatus: String, Codable { case upcoming, active, ended }
```

모든 모델은 Codable + Sendable, 버전 인지 디코드(향후 호환).

## 5. 위젯 구성 & 상태

**카테고리 전용 위젯** (각각 systemSmall / systemMedium):
- 챔피언스 미팅: 미팅명, d-day, phase 라벨, 마장 요약(도쿄·잔디 2400m)
- 리그 오브 히어로즈: 시즌명, d-day, 마장 요약
- 픽업: 진행/예정 육성마·서포트카드 픽업, 픽업 대상, 종료/시작 d-day

**통합 Large 위젯** (systemLarge): 3개 카드 세로 스택(챔미 / LoH / 픽업)

**잠금화면 위젯**:
- `accessoryRectangular`: 가장 임박한 이벤트 자동 선택
- `accessoryCircular`: d-day 링

**위젯 상태 머신** (LCK의 upcoming/live/offSeason/empty 대응):
- `upcoming` — 다음 phase까지 카운트다운
- `active` — 현재 진행 중(예: 라운드1 진행중), "진행중 · 종료 D-n"
- `idle` — 예정된 이벤트 없음 (데이터 공백 / 시즌 사이)
- `noData` — 원격/번들 모두 실패

```swift
enum WidgetState: Codable, Hashable, Sendable {
    case content([EventCard])   // 표시할 카드들
    case idle
    case noData
}

struct WidgetEntry: TimelineEntry, Codable, Hashable, Sendable {
    let date: Date
    let state: WidgetState
    let fontTheme: FontTheme
}
```

## 6. 설정 & 다국어

**앱 설정 화면**:
- 표시 카테고리 / 순서 선택
- 폰트 테마 (system / rounded / mono / serif)
- 언어 (시스템 / 한국어 / 영어)
- 알림 on/off

**알림(선택, v1 포함하되 가볍게)**: phase 시작 N시간 전 로컬 알림. BGAppRefreshTask로 일정 갱신 후 스케줄.

**다국어**: ko/en. L.Key enum + .lproj 패턴(LCK 동일). 이벤트 고유명(미팅명·캐릭터명)은 원문 유지, UI 라벨만 번역. 한국어 텍스트는 시스템 폰트 사용.

## 7. 테스트

LCK와 동일하게 Core SPM 단위 테스트:
- 모델 Codable 라운드트립
- ScheduleRepository 캐시 TTL / stale fallback / 번들 fallback
- ScheduleStateResolver의 phase 자동 전환 (upcoming → active → 다음 이벤트)
- EventCard 파생 로직 (trackSummary 포맷, phaseLabel 계산)
- 다국어 키 누락 검사

## 8. v1 범위 밖 (YAGNI)

- 과거 이벤트 결과 아카이브
- 푸시 서버 / 원격 알림
- 인앱결제 / Pro 기능
- 위젯 탭 시 딥링크 상세화면 (앱 열기까지만)

## 9. 열린 항목 (구현 중 확정)

- 원격 JSON 호스팅 위치 (GitHub raw vs Netlify) 및 URL
- 챔미 phase 실제 구성이 한국 서버 운영과 정확히 일치하는지 검증 (오픈/라운드1/라운드2 외 단계 유무)
- 마장 정보에 방향/코스를 위젯에 노출할지 (데이터 모델엔 포함, 표시 여부만 구현 중 확정)

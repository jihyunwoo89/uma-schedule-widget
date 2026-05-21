# 우마무스메 위젯 v2 — 확장 스키마 + DCinside 자동 수집 파이프라인 설계

작성일: 2026-05-21
선행: [v1 위젯 설계](2026-05-21-uma-schedule-widget-design.md) (구현·머지 완료)

## 1. 목적 & 배경

v1 위젯은 빌드·머지 완료(68 테스트 통과). 비주얼 컴패니언으로 실제 데이터 기준 레이아웃(v3 초안)을 확정하면서 두 가지가 드러났다:

1. **표시 데이터가 v1 모델보다 훨씬 풍부하다** → 스키마 확장 필요.
2. **데이터 소스가 정해졌다**: DCinside 우마무스메 갤러리의 "미래시가이드" 게시글. 본문이 **이미지(WebP) 슬라이드**로, 픽업 배너·리그 오브 히어로즈·마장 조건 등이 정형 표/카드로 정리돼 있다. (실제 글 `gall.dcinside.com/mgallery/board/view/?id=umamusu&no=1850737` 확인: HTML 접근 OK, Referer 헤더로 이미지 23장 추출·다운로드 성공, 슬라이드에 픽업표 `시기|픽업|명칭|구분|범위` + LoH 조건 + 배너 상세 존재 확인.)

이번 이터레이션은 **확장 스키마를 계약으로** 두 워크스트림을 진행한다:
- **A**: 앱이 확장 데이터를 표시 (모델·위젯뷰 갱신).
- **B**: DCinside 가이드 이미지 → 비전 추출 → 검수 게이트 → `schedule.json` 발행 파이프라인.

## 2. 핵심 결정 사항

| 항목 | 결정 |
|------|------|
| 레이아웃 | v3 초안 확정 (제목 위계 「코드명」/「회차」 + 하단 레이스명) |
| 발행 방식 | **검수 게이트** — 자동 추출 → PR diff → 사람 승인 → 발행 |
| 데이터 소스 | DCinside "미래시가이드" 게시글 본문 이미지 |
| 추출 방식 | **멀티모달 LLM(Claude 비전 API)** 으로 이미지→JSON (OCR+정규식 X) |
| 자동화 | GitHub Actions cron (주 1회 + 수동 dispatch) |
| 스키마 버전 | `version: 2` |
| 저작권 | 가이드 이미지는 재배포 X, **사실 데이터(날짜/조건/캐릭터명)만 추출** |

## 3. 확장 데이터 스키마 (v2) — 두 워크스트림의 계약

```swift
struct ScheduleDocument: Codable, Sendable {
    var version: Int            // = 2
    var updatedAt: Date
    var sourcePostNo: Int?      // 추출 출처 글 번호 (추적용)
    var server: String          // "kr"
    var championsMeetings: [ChampionsMeeting]
    var leagueOfHeroes: [LeagueOfHeroes]
    var pickups: [PickupPeriod]   // v1의 gachaBanners 대체
}

struct EventPeriod: Codable, Hashable, Sendable {
    var start: Date
    var end: Date
    var estimated: Bool          // "(예상)" — 한국 날짜 미확정
}

struct TrackCondition: Codable, Hashable, Sendable {
    var racecourse: String       // 한신
    var surface: Surface         // turf/dirt
    var distanceMeters: Int      // 1600
    var distanceClass: DistanceClass  // 단거리/마일/중거리/장거리 (거리에서 파생 가능하나 명시 저장)
    var turn: Turn?              // 시계(우)/반시계(좌)/직선
    var courseSide: String?      // 외측/내측
    var season: String?          // 봄/여름/가을/겨울
    var weather: String?         // 맑음/흐림/비/눈
    var ground: String?          // 양호/약간 무거움/무거움/불량
    var timeOfDay: String?       // 낮/밤
    var imageURL: URL?           // 마장 이미지(원격, 선택)
}
enum Surface: String, Codable, Hashable, Sendable { case turf, dirt }
enum DistanceClass: String, Codable, Hashable, Sendable { case sprint, mile, medium, long }
enum Turn: String, Codable, Hashable, Sendable { case clockwise, counterclockwise, straight }

struct ChampionsMeeting: Codable, Hashable, Sendable {
    var id: String
    var codeName: String         // 「LONG」 — 큰 제목
    var raceGrade: String?       // "G1"
    var raceName: String         // "벚꽃상" — 하단 표시
    var track: TrackCondition
    var period: EventPeriod
    var phases: [EventPhase]      // d-day 자동전환 유지 (오픈/라운드1/라운드2/종료)
}

struct LeagueOfHeroes: Codable, Hashable, Sendable {
    var id: String
    var round: String            // 「10회차」 — 큰 제목
    var raceName: String         // "스프린터즈 스테이크스" — 하단
    var track: TrackCondition
    var period: EventPeriod
    var phases: [EventPhase]
}

struct SupportCardPick: Codable, Hashable, Sendable {
    var rarity: String           // "SSR"
    var name: String             // "아몬드 아이"
    var type: String             // "스피드"/"스태미나"/"파워"/"근성"/"지능"/"우정" 등
}

struct PickupPeriod: Codable, Hashable, Sendable {
    var id: String
    var period: EventPeriod
    var trainees: [String]       // ["오르페브르", "푸리오소"]
    var supportCards: [SupportCardPick]
}
```

`EventPhase`/`PhaseKind`는 v1 그대로 유지 (d-day 자동전환의 근거). `period`는 표시용(기간+예상 배지), `phases`는 d-day 계산용 — 보통 `phases.first.date == period.start`, `phases.last.date == period.end`.

> **마이그레이션**: v1의 `gachaBanners`/`TrackCondition(direction:String?)`/`ChampionsMeeting(name:)`은 v2에서 위 구조로 대체된다. 앱은 `version` 분기로 v1 캐시를 무시하고 새로 fetch(또는 단순 폐기) — 사용자 데이터가 아니므로 백워드 디코드 부담 없음.

## 4. 워크스트림 A — 앱 표시 변경

### 4.1 모델/로직
- 위 스키마로 `Models/` 교체·확장, `EventCardFactory`/`ScheduledEvent`/`EventCard`가 새 필드를 싣도록 갱신.
- `EventCard`에 `codeName`/`raceLine`(grade+raceName)/`period`/`estimated`/확장 `track`/픽업용 `trainees`/`supportCards` 추가.

### 4.2 위젯 표시 매트릭스 (v3 확정)

| 위젯 | 제목 | 부제 | 기간/d-day | 마장 | 픽업 상세 |
|------|------|------|-----------|------|-----------|
| L1 주요(상세) | 「코드명」/「회차」 크게 | 등급+레이스명 | 기간(예상)+D-day | **코스 이미지 + 조건 칩 전부** (시계·외측·계절·날씨·마장상태·시간대) | — |
| L2 전체 | 카테고리별 「제목」 | 레이스명 1줄 | D-day | 1줄 요약 | 육성마+서포트 풀 |
| M1 주요(간략) | 「제목」 | 레이스명 | 기간+D-day | 1줄 요약 | — |
| M2 챔미+LoH | 「제목」x2 | 레이스명 | D-day x2 | — | — |
| M3 픽업 | — | — | 기간+D-day | — | 육성마+서포트 풀네임 |
| S1 주요(개요) | 「제목」 | 레이스명 | D-day | 1줄 | — |
| S2/S3 챔미·LoH | 「제목」 | 레이스명 | D-day | 1줄 | — |
| S4 픽업 | 육성마명 | — | D-day | — | **서포트 2종 풀네임 전부** |
| Lock rect | 카테고리+「제목」 | 레이스명 | D-day | — | — |
| Lock circ | 아이콘 | — | D-day 숫자 | — | — |

**L1 상세 기본안 = L1-A (조건 칩 전부)**. 정보 우선 사용자 선호 반영. (열린 항목: 너무 빽빽하면 L1-B로 후퇴.)

### 4.3 기타
- 번들 `schedule_fallback.json`을 v2 스키마로 교체.
- 다국어 키 추가 (거리구분/회전/계절/날씨/마장상태/시간대 라벨, "예상", "육성마"/"서포트").
- Core 단위 테스트 갱신 + 신규(파생/표시 포맷).

## 5. 워크스트림 B — DCinside 수집 파이프라인

### 5.1 아키텍처
별도 데이터 레포(예: `uma-schedule-data`)에 GitHub Actions로 구동. 앱은 그 레포의 raw `schedule.json`을 fetch (v1 `ScheduleEndpoint.url`을 이 레포로 지정).

```
cron(주1회)/manual
  → ① 최신 "미래시가이드" 글 탐색 (umamusu mgallery 검색, 최신 post no)
  → ② 직전 처리 post no 캐시와 비교 (변화 없으면 종료)
  → ③ 글 HTML fetch → dcimg viewimage URL 전부 추출
  → ④ 이미지 다운로드 (UA + Referer 헤더, WebP→PNG)
  → ⑤ 슬라이드별 Claude 비전 API 호출:
        - 1차: 슬라이드 분류 (표지/안내/픽업표/배너상세/LoH/챔미/무관)
        - 2차: 해당 슬라이드에서 스키마 필드 추출 (JSON)
  → ⑥ 슬라이드 결과 병합 → ScheduleDocument(v2) 조립
  → ⑦ JSON Schema 검증 + 신뢰도/누락 플래그
  → ⑧ 현재 발행본과 diff → 변화 있으면 PR 생성 (검수 게이트)
  → (사람 승인·머지) → schedule.json 발행 → 앱 fetch
```

### 5.2 구현 선택
- 언어: Node 또는 Python (스크립트 + Anthropic SDK). 단일 러너에서 실행.
- 비전 추출은 최신 Claude 모델(vision)로 스키마 제약 프롬프트 사용. 슬라이드는 다운스케일(비용/토큰 절감).
- 발견(discovery): 갤러리 목록/검색에서 제목 prefix "미래시가이드" 최신 글. (불안정하면 사용자가 글 URL을 수동 입력하는 fallback.)
- 빈도: 주 1회 + `workflow_dispatch`. last-seen post no를 레포 파일/Actions 캐시에 저장.
- 시크릿/외부 준비(사용자): 데이터 레포 생성, `ANTHROPIC_API_KEY` 시크릿, (PR 생성용 토큰).

### 5.3 검수 게이트
- 자동 발행 금지. 추출 결과는 항상 **PR diff**로 올라오고 사람이 확인 후 머지.
- 각 이벤트에 `estimated` 플래그 + 문서 `updatedAt`/`sourcePostNo` 기록.
- 추출 신뢰도 낮은 필드(미인식/모호)는 PR 본문에 ⚠️로 표기.

## 6. 정확도 & 검증

- JSON Schema(스키마 §3)로 구조 검증: 필수 필드, 날짜 파싱, enum 값.
- 비전 추출 회귀 테스트: 고정 fixture 이미지(이번에 받은 슬라이드들) → 기대 JSON 스냅샷 비교.
- 앱: 모델 디코드/표시 포맷 단위 테스트.

## 7. 리스크

- **저작권/ToS**: 가이드 이미지(작성자 창작물) 재배포 금지. 추출하는 건 사실 데이터(날짜/마장 조건/캐릭터명)로 한정. DCinside 과도 요청 금지(주1회 + 변화 시만), UA/Referer 명시, robots 준수.
- **양식 변경 취약성**: 가이드 작성자가 레이아웃 바꾸면 추출 흔들림 → 비전 LLM이 정규식보다 견고하나 프롬프트 조정 필요할 수 있음. 검수 게이트가 안전망.
- **비전 오독**: 캐릭터명/날짜 오인식 → 검수 게이트 + estimated 플래그로 완화.
- **유지보수 부담**: 지속 운영 파이프라인. 실패 시 앱은 마지막 발행본/번들 fallback으로 graceful degrade(이미 구현).
- **API 비용**: 슬라이드 다수 × 호출 — 변화 시에만 실행 + 다운스케일로 제한.

## 8. 테스트 전략

- Core(앱): 모델 v2 Codable, EventCardFactory 파생, 위젯 표시 포맷, 다국어 키 파리티 — `swift test`.
- 파이프라인: 슬라이드 분류/추출 fixture 스냅샷, 스키마 검증, diff 로직 — 러너 테스트.
- 통합: 발행된 `schedule.json`을 앱이 디코드·표시하는 라운드트립.

## 9. v2 범위 밖 (YAGNI)

- 완전 자동 발행(검수 없이) — 명시적으로 제외.
- 다중 가이드 작성자/소스 통합 — 단일 "미래시가이드" 우선.
- 과거 일정 아카이브, 푸시 알림 서버.
- 마장 이미지 자동 수집(별도 트랙; 지금은 코스 도식 fallback 유지).

## 10. 열린 항목 (스펙 리뷰/계획에서 확정)

- L1 상세 A(조건 칩 전부) vs B(간결) 최종 선택.
- 슬라이드 → 필드 정확한 매핑 (가이드의 어떤 슬라이드가 챔미/LoH/픽업인지; 비전 분류로 흡수).
- 캐릭터/서포트명 표기: 한글 vs JP 로마자/원문.
- 데이터 레포 위치·이름, `ScheduleEndpoint.url` 최종값.
- 파이프라인 언어(Node vs Python) 및 PR 생성 방식(gh CLI vs action).
- 가이드 글 발견 자동화 vs 수동 URL 입력 fallback 범위.

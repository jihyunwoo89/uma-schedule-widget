# 우마무스메 스케줄 — 인앱 화면 설계

작성일: 2026-05-22 · 톤: **Frost Minimal**(위젯과 동일) · 대상: 앱 본체(iOS, SwiftUI)

위젯은 완료되었고, 이 문서는 **앱 본체 화면**을 다룬다. 결정은 브라우저 목업으로 검증했다:
`app-schedule-tab.html`(A안), `app-detail-cm.html`, `app-detail-pickup.html`.

---

## 1. 목표 / 범위

- 앱을 **일정 브라우저**로 만든다: 챔미·LoH·픽업 **전체 예정 일정**을 보고, 각 이벤트의 **상세**(마장/단계 또는 육성마/서포트)까지 확인.
- 위젯과 **시각적 일관성**(Frost Minimal: 카테고리색 헤더, 등급 뱃지, 레어도 뱃지, 특성 아이콘·이름색).
- 데이터는 위젯과 **동일 소스**(`ScheduleRepository` → `ScheduleDocument`). **스키마 변경 없음**(필요한 필드 — 등급/마장/기간/단계/육성마/서포트 — 모두 존재).

**범위 밖(YAGNI)**: 위젯 코드 변경, 새 데이터 필드, 알림 로직 변경, 검색/필터, '위젯 추가하는 법' 가이드(추후 별도). 설정 탭은 기존 화면 재사용(톤만 정리).

---

## 2. 네비게이션

`TabView` — 탭 2개:
- **일정**(`ScheduleListView`) — 기본 탭
- **설정**(`SettingsView`) — 기존 화면 재사용

(현재 `RootView`의 단일 List + 기어 toolbar 구조를 TabView로 교체. `UmaScheduleApp`의 루트를 새 `RootTabView`로.)

---

## 3. 화면

### 3.1 일정 탭 — `ScheduleListView` (A안)
- 상단 **세그먼트 컨트롤**: 챔피언스 미팅 / LoH / 픽업. 선택된 카테고리만 표시.
- 각 카테고리 화면:
  - **히어로 카드**(가장 임박한 1건): 카테고리 헤더 + 「코드명」(또는 픽업 요약) + 등급 뱃지·레이스명 + 마장 1줄 / 우측 큰 D-day + 기간. 카테고리색 옅은 그라데이션 배경.
  - **"예정" 섹션 라벨** 아래 나머지 예정 일정을 **균일 카드 목록**(작은 카드: 「코드명」+등급·레이스명, 마장 요약, 우측 D-day/날짜).
  - 카드 탭 → 상세(`EventDetailView`).
- 정렬: 비종료(upcoming/active) 이벤트를 **임박 순**(resolved targetDate 오름차순). 종료 이벤트는 제외(기본). 
- 픽업 세그먼트의 히어로/카드는 마장 대신 **육성마·서포트 요약**으로 치환.

### 3.2 상세 — `EventDetailView`
입력은 **도메인 모델**(`ChampionsMeeting` / `LeagueOfHeroes` / `PickupPeriod`)로 받아 단계(phases)까지 표현.

**챔미 / LoH 상세**(`app-detail-cm.html`):
- **히어로**: 카테고리 / 「코드명」 / 등급 뱃지·레이스명 / 기간(`M.D ~ M.D` + (예상)) / 큰 D-day + 다음 단계 라벨.
- **마장**: 큰 마장 이미지(`TrackImageView`; 이미지 없으면 코스 도식) + 거리줄(`distanceLine`, 여기선 거리구분 괄호 표기 허용) + 조건 칩(시계/외측/계절/날씨/마장상태/시간대).
- **단계 타임라인**: 오픈 / 라운드1 / 라운드2 / 종료 등 `phases`를 행으로(현재 단계 강조 + D-day, 각 날짜). 날짜 없는 단계는 라벨만/생략.

**픽업 상세**(`app-detail-pickup.html`):
- **히어로**: 카테고리(픽업) / 기간 / 큰 D-day + 시작·종료까지.
- **육성 우마무스메** 섹션: `N★`(레어도 뱃지) + 이름 목록.
- **서포트 카드** 섹션: 레어도 뱃지 + 이름(특성색) + 특성 아이콘 목록. 서포트 없으면(셀렉트 픽업) 섹션 생략.

### 3.3 설정 탭 — `SettingsView`(기존)
- 기존 그대로(카테고리 순서·폰트·언어·알림·새로고침·데이터 출처·면책). 큰 변경 없음, 톤만 시스템 Form 유지.

### 3.4 상태
- 각 탭/리스트: 로딩(`ProgressView`), 빈 상태(해당 카테고리 예정 없음 안내), 실패(`state.nodata`). `.task`/`.refreshable`로 로드(기존 RootView 패턴 재사용).

---

## 4. 데이터 흐름 / 코어 추가

- `ScheduleRepository.current()` → `ScheduleDocument`(이미 public). 앱 진입 시 1회 로드 + 당겨서 새로고침.
- **`EventCardFactory` 추가(코어)**:
  - 특정 항목 → 카드: `championsCard(for:now:)`, `leagueCard(for:now:)`, `pickupCard(for:now:)`(기존 "가장 임박" 메서드는 이를 재사용하도록 리팩터).
  - 카테고리별 예정 목록: `upcomingChampions(_:now:)`, `upcomingLeagues(_:now:)`, `upcomingPickups(_:now:)` → 비종료 + 임박 순 정렬된 **도메인 모델 배열**(상세에서 phases 접근 위해 도메인 모델 유지).
- 리스트 행은 도메인 모델 → `…Card(for:now:)`로 EventCard를 만들어 렌더(매핑 로직 코어에 일원화). 상세는 도메인 모델을 직접 받음.
- `resolution(now:)`는 내부 유지(코어 메서드가 정렬/카드화 담당).

---

## 5. 디자인 시스템 재사용

- 공개 컴포넌트 그대로 사용: `CategoryBadge`, `GradeBadge`, `RarityBadge`/`RarityTier`, `SupportTypeIcon`/`SupportType`, `BracketTitle`, `TrackImageView`, `CourseDiagramView`, `RaceNameLine`/`TrackLines`(필요 시).
- **색 토큰 공개화**: 현재 `WidgetColors`(internal) → **public**으로 승격(예: `UmaColors`)하여 앱 카드/텍스트가 위젯과 동일 색 사용. 카테고리색은 `EventCategory.accentColor`(public) 재사용.
- 폰트: `Typography`(FontTheme) 적용 — 설정의 글꼴 테마가 앱 화면에도 반영.

---

## 6. 컴포넌트 / 파일 배치

앱 화면 뷰는 **앱 타깃(App/)** 에 둔다(기존 `RootView`/`SettingsView`와 동일 위치; 공개 UmaCore API 사용). 코어 변경은 팩토리/색토큰뿐.

- `App/RootTabView.swift` — TabView(일정/설정). `UmaScheduleApp` 루트 교체.
- `App/ScheduleListView.swift` — 세그먼트 + 히어로 + 목록.
- `App/EventDetailView.swift` — 챔미/LoH/픽업 분기 상세.
- `App/ScheduleRowCard.swift` / `App/ScheduleHeroCard.swift` — 재사용 카드(또는 ScheduleListView 내부 뷰).
- `App/SettingsView.swift` — 기존 유지.
- 코어: `Core/Sources/UmaCore/Logic/EventCardFactory.swift`(메서드 추가), `Core/Sources/UmaCore/DesignSystem/`(색 토큰 public 승격).

각 뷰는 단일 책임: 리스트는 목록/네비게이션, 상세는 한 이벤트 표현, 카드 뷰는 한 행 렌더.

---

## 7. 테스트

- 코어 신규 팩토리 메서드 유닛 테스트: `upcoming…` 정렬·종료 제외, `…Card(for:now:)` 매핑(등급/레이스/트랙/픽업) — `swift test`.
- 뷰는 시각 검증(Xcode 시뮬레이터). 기존 97 테스트 유지.

---

## 8. 실제 데이터(2026-05-22 기준 예시)

- 챔미 예정: 「MILE」G1 벚꽃상(7.14, D-54) · 「LONG」G1 텐노상(봄)(8.13) · 「CLASSIC」G1 오크스(10.10) · 「CLASSIC」G1 타카라즈카(11.13)
- LoH 예정: 「10회차」 스프린터즈 스테이크스(6.7, D-17) · 「11회차」 재팬 더트 더비(9.15)
- 픽업: 5.22 D-1 — 육성 3★ 발렌타인 애스턴 마짱 / 3★ 발렌타인 야마닌 제퍼 · 서포트 SSR 카렌짱<근성> / SSR 이쿠노 딕터스<지능> 외 18건

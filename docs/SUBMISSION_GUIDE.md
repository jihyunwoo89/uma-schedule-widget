# App Store 심사 제출 상세 가이드 — 우마스케쥴

대상 빌드: **1.0 (build 13)** · 출시: **대한민국 단독** · 무료

준비물 확인: Apple Developer Program(유료) 가입, App Store Connect 접근 권한.

---

## STEP 1 — 빌드 13 업로드 (Xcode Organizer)
1. Xcode → **Window ▸ Organizer** (`⌥⌘⇧O`)
2. 왼쪽 **Archives** → UmaSchedule → **`08-56-08` (App Version 1.0 (13))** 선택
   - ⚠️ 이전 빌드(3~12) 무시. 반드시 **(13)** 선택.
3. 오른쪽 **Distribute App** → **App Store Connect** → **Upload**
4. 서명: **Automatically manage signing** 그대로 → **Upload**
5. 업로드 후 App Store Connect에서 **처리(Processing) 5~15분**. 처리 끝나면 빌드 선택 가능.

---

## STEP 2 — 앱 레코드 생성 (앱이 아직 없다면)
[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **앱(My Apps)** → **+ ▸ 새로운 앱**
- 플랫폼: **iOS**
- 이름: **우마스케쥴**
- 기본 언어: **한국어**
- 번들 ID: **com.damienjee.umaschedule** (목록에서 선택)
- SKU: 아무 고유값 (예: `umaschedule-001`)
- 사용자 액세스: 전체

---

## STEP 3 — 앱 정보 (App Information)
좌측 **앱 정보**:
- 부제: `픽업·챔미·LoH 일정 위젯` (또는 노출안)
- 카테고리: 기본 **유틸리티**, 보조 **참고**
- **콘텐츠 권리(Content Rights)**: "타사 콘텐츠 포함" 여부 →
  - 코스맵 이미지: **gametora 사용 허락 받음**(설정에 출처+링크 표기). 보유 권리 확인란 체크 가능.
  - 레이스/캐릭터명은 사실 정보, 앱 내 면책 표기. (5.2 리스크 인지 — 아래 STEP 9 참고)
- **개인정보 처리방침 URL**:
  `https://github.com/jihyunwoo89/uma-schedule-data/blob/main/PRIVACY.md`

---

## STEP 4 — 가격 및 사용 가능 여부
- 가격: **무료(₩0)**
- 사용 가능 여부: **대한민국만 선택** (전체 해제 후 대한민국 체크)

---

## STEP 5 — 앱 개인정보 (App Privacy)
- **데이터 미수집(Data Not Collected)** 선택 → 게시(Publish)
- 추적(Tracking): **아니오**
- (근거: 앱은 개인정보 수집·전송 없음. PrivacyInfo.xcprivacy에 명시)

---

## STEP 6 — 버전 정보 입력 (iOS 앱 1.0)
- **프로모션 텍스트**(선택): 한 줄 홍보 문구
- **설명(Description)**: (docs/APP_STORE_SUBMISSION.md 의 설명 복붙)
- **키워드**: `일정,위젯,챔피언스미팅,픽업,리그오브히어로스,경마,스케쥴,잠금화면,마장`
- **지원 URL**: `https://github.com/jihyunwoo89/uma-schedule-data/blob/main/SUPPORT.md`
- **마케팅 URL**(선택): 비워도 됨
- **스크린샷**: 6.9"(iPhone) 칸에 `appstore_screens/` 3장 업로드
  - 01_main / 02_detail / 03_widgets
- **앱 아이콘**: 빌드에서 자동 (1024 포함)
- **저작권**: `© 2026 (본인 이름/닉네임)`
- **빌드**: 처리 완료된 **(13)** 선택

---

## STEP 7 — 연령 등급
- "연령 등급 편집" → 질문지 전부 **없음** → **4+** 확정

---

## STEP 8 — 심사 정보 (App Review Information)
- 연락처: 이름 / `jihyunwoo89@gmail.com` / 전화
- **로그인 필요 없음** (데모 계정 불필요 → 체크 해제)
- 비고(Notes): (docs/APP_STORE_SUBMISSION.md 의 심사 노트 복붙) — 핵심:
  - 비공식 KR 우마무스메 일정 앱, 로그인 불필요
  - 일정은 공개 GitHub JSON에서 읽기, 개인정보 수집 없음
  - 위젯은 홈/잠금화면 추가로 확인
  - 마장 이미지: gametora **사용 허락 받음**, 설정에 출처·링크 표기

---

## STEP 9 — 제출
- 버전 출시: **자동(승인 즉시)** 또는 **수동** 선택
- 우측 상단 **심사를 위해 추가 ▸ 제출(Submit for Review)**
- 마지막 질문:
  - **수출 규정(Export Compliance)**: 비표준 암호화 사용? **아니오** (Info.plist에 이미 false → 자동 처리될 수 있음)
  - **광고 식별자(IDFA)**: 사용 안 함 → **아니오**

---

## 제출 후
- 상태: **심사 대기 → 심사 중 → 승인/거부** (보통 24~48시간)
- **거부 시(특히 가이드라인 5.2 지식재산권)** 대응:
  - 해결 센터(Resolution Center)에서 회신
  - gametora **사용 허락 사실** + 앱 내 출처·링크 표기 + 면책 문구 + 무료/비공식 팬 유틸리티임을 설명
  - 그래도 코스맵이 문제되면 → 자체 다이어그램(옵션 B)으로 교체한 새 빌드 제출

## 최종 체크리스트
- [ ] build 13 업로드 & 처리 완료
- [ ] 부제 / 카테고리(유틸리티) / 콘텐츠 권리
- [ ] 개인정보 처리방침 URL / 지원 URL
- [ ] 무료 / 대한민국 단독
- [ ] 앱 개인정보 "미수집" 게시
- [ ] 설명 / 키워드 / 스크린샷 3장 / 저작권
- [ ] 빌드 (13) 선택
- [ ] 연령 4+
- [ ] 심사 노트 + 연락처
- [ ] 수출규정/IDFA "아니오"
- [ ] 제출

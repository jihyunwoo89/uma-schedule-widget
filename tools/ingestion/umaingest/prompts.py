"""Prompts for Claude vision extraction of the 미래시가이드 slides.

The guide is community-made and splits one event across slides (race conditions on a
preview slide, dates on a banner/schedule slide), so we send ALL slides in one call and
let the model cross-reference them into complete events.
"""

MULTI_SYSTEM = (
    "You read ALL slides of one Korean-server Umamusume '미래시가이드' post together and "
    "produce ONE consolidated schedule as JSON. Information about a single event is often "
    "split across slides (race conditions on a preview slide, dates on a banner/schedule slide) "
    "— cross-reference the slides to assemble complete events. Return ONLY valid JSON, no prose. "
    "Use Korean text exactly as shown. Unknown fields → null. Never invent dates or names."
)

MULTI_EXTRACT = """첨부된 이미지들은 한 개의 '미래시가이드' 게시글의 모든 슬라이드입니다.
슬라이드 전체를 종합해(조건은 프리뷰 슬라이드, 날짜는 배너/일정 슬라이드에 나뉘어 있을 수 있음)
완전한 일정 JSON 하나만 출력하세요:

{
  "championsMeetings": [{
    "codeName":"「」 안 코드명/분류 (예: MILE, LONG, CLASSIC)",
    "raceGrade":"G1 등 또는 null","raceName":"레이스명 (예: 벚꽃상, 텐노상(봄), 오크스)",
    "track":{"racecourse":"경마장","surface":"turf|dirt","distanceMeters":1600,
             "distanceClass":"sprint|mile|medium|long",
             "turn":"clockwise|counterclockwise|straight|null","courseSide":"외측|내측|null",
             "season":"봄|여름|가을|겨울|null","weather":"맑음 등|null","ground":"양호 등|null","timeOfDay":"낮|밤|null"},
    "period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":true}
  }],
  "leagueOfHeroes":[{"round":"「」 안 회차 또는 분류","raceName":"명칭","track":{"...동일...":null},
                     "period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":true}}],
  "pickups":[{"period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":false},
              "trainees":["육성마명"],
              "supportCards":[{"rarity":"SSR","name":"이름","type":"스피드|스태미나|파워|근성|지능"}]}]
}

규칙: 날짜는 YYYY-MM-DD. 조건과 날짜를 같은 이벤트로 합치세요. 한국 서버 미확정이면 estimated=true.
조건만 있고 날짜를 어디서도 못 찾은 이벤트는 제외하세요."""

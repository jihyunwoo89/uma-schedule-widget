"""Prompts for Claude vision extraction of the 미래시가이드 slides.

The guide is community-made and may change layout; the model classifies each
slide then extracts only factual schedule data into our schema shape.
"""

SYSTEM = (
    "You extract Korean-server Umamusume schedule facts from community guide images. "
    "Return ONLY valid minified JSON, no prose. Use Korean text exactly as shown in the image. "
    "Unknown/absent fields → null. Never invent dates or names."
)

# One call per slide. The model returns a partial document with any of the three arrays.
EXTRACT = """이 이미지는 한국 서버 우마무스메 '미래시가이드' 슬라이드입니다.
다음 JSON 스키마로 보이는 정보만 추출하세요(없으면 빈 배열):

{
  "championsMeetings": [{
    "codeName": "「」 안의 코드명 또는 분류 (예: LONG)",
    "raceGrade": "G1 등 등급 또는 null",
    "raceName": "레이스명 (예: 벚꽃상)",
    "track": {"racecourse":"경마장","surface":"turf|dirt","distanceMeters":1600,
              "distanceClass":"sprint|mile|medium|long",
              "turn":"clockwise|counterclockwise|straight|null","courseSide":"외측|내측|null",
              "season":"봄|여름|가을|겨울|null","weather":"맑음 등|null","ground":"양호 등|null","timeOfDay":"낮|밤|null"},
    "period": {"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":true}
  }],
  "leagueOfHeroes": [{"round":"「」 안 회차","raceName":"레이스명","track":{...위와 동일...},
                      "period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":true}}],
  "pickups": [{"period":{"start":"YYYY-MM-DD","end":"YYYY-MM-DD","estimated":false},
               "trainees":["육성마명",...],
               "supportCards":[{"rarity":"SSR","name":"이름","type":"스피드|스태미나|파워|근성|지능"}]}]
}

규칙: 날짜는 YYYY-MM-DD. 한국 서버 미확정 일정이면 estimated=true. 표지/안내/캐릭터 로스터만 있는 슬라이드는 모든 배열을 비웁니다."""

from umaingest import prompts

def test_prompts_have_schema_keys():
    assert "championsMeetings" in prompts.EXTRACT
    assert "supportCards" in prompts.EXTRACT
    assert "estimated" in prompts.EXTRACT
    assert prompts.SYSTEM  # non-empty


import base64
from umaingest.vision import extract_slide, VisionResult

def test_extract_slide_parses_model_json():
    class FakeBlock:
        def __init__(self, t): self.text = t
    class FakeMsg:
        def __init__(self, t): self.content = [FakeBlock(t)]
    class FakeClient:
        def __init__(self, payload): self._p = payload
        class _Messages:
            def __init__(self, outer): self._o = outer
            def create(self, **kw):
                FakeClient.last_kwargs = kw
                return FakeMsg(self._o._p)
        @property
        def messages(self): return FakeClient._Messages(self)

    payload = '{"championsMeetings":[],"leagueOfHeroes":[],"pickups":[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":false},"trainees":["오르페브르"],"supportCards":[]}]}'
    res = extract_slide(b"\x00fakeimage", client=FakeClient(payload))
    assert isinstance(res, VisionResult)
    assert res.pickups[0]["trainees"] == ["오르페브르"]
    assert res.championsMeetings == []
    sent = FakeClient.last_kwargs["messages"][0]["content"]
    assert any(b.get("type") == "image" for b in sent)

def test_extract_slide_tolerates_codefenced_json():
    class FakeBlock:
        def __init__(self, t): self.text = t
    class FakeMsg:
        def __init__(self, t): self.content = [FakeBlock(t)]
    class FakeClient:
        class _M:
            def create(self, **kw): return FakeMsg("```json\n{\"championsMeetings\":[],\"leagueOfHeroes\":[],\"pickups\":[]}\n```")
        @property
        def messages(self): return FakeClient._M()
    res = extract_slide(b"x", client=FakeClient())
    assert res.pickups == []

from umaingest import prompts
from umaingest.vision import extract_document


def test_prompts_have_schema_keys():
    assert "championsMeetings" in prompts.MULTI_EXTRACT
    assert "supportCards" in prompts.MULTI_EXTRACT
    assert "estimated" in prompts.MULTI_EXTRACT
    assert prompts.MULTI_SYSTEM


class _FakeBlock:
    def __init__(self, t): self.text = t

class _FakeMsg:
    def __init__(self, t): self.content = [_FakeBlock(t)]

class _FakeClient:
    last_kwargs = None
    def __init__(self, payload): self._p = payload
    class _Messages:
        def __init__(self, outer): self._o = outer
        def create(self, **kw):
            _FakeClient.last_kwargs = kw
            return _FakeMsg(self._o._p)
    @property
    def messages(self): return _FakeClient._Messages(self)


def test_extract_document_sends_all_images_and_parses():
    payload = '{"championsMeetings":[],"leagueOfHeroes":[],"pickups":[{"period":{"start":"2026-06-15","end":"2026-06-21","estimated":false},"trainees":["오르페브르"],"supportCards":[]}]}'
    res = extract_document([b"img1", b"img2", b"img3"], client=_FakeClient(payload))
    assert res["pickups"][0]["trainees"] == ["오르페브르"]
    assert res["championsMeetings"] == []
    sent = _FakeClient.last_kwargs["messages"][0]["content"]
    # all 3 images sent in the single call, plus one text block
    assert sum(1 for b in sent if b.get("type") == "image") == 3
    assert any(b.get("type") == "text" for b in sent)


def test_extract_document_tolerates_codefence():
    payload = "```json\n{\"championsMeetings\":[],\"leagueOfHeroes\":[],\"pickups\":[]}\n```"
    res = extract_document([b"x"], client=_FakeClient(payload))
    assert res["pickups"] == []

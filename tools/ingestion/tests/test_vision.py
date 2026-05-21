from umaingest import prompts

def test_prompts_have_schema_keys():
    assert "championsMeetings" in prompts.EXTRACT
    assert "supportCards" in prompts.EXTRACT
    assert "estimated" in prompts.EXTRACT
    assert prompts.SYSTEM  # non-empty

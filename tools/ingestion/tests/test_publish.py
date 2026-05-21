from pathlib import Path
from umaingest.publish import write_if_changed

def test_write_if_changed_writes_new(tmp_path):
    dest = tmp_path / "data" / "schedule.json"
    wrote = write_if_changed(dest, '{"version":2,"pickups":[],"updatedAt":"2026-05-20T00:00:00Z"}')
    assert wrote is True
    assert dest.exists()

def test_write_if_changed_skips_when_same_modulo_timestamp(tmp_path):
    dest = tmp_path / "schedule.json"
    write_if_changed(dest, '{"version":2,"pickups":[],"updatedAt":"2026-05-20T00:00:00Z"}')
    wrote = write_if_changed(dest, '{"version":2,"pickups":[],"updatedAt":"2026-05-21T00:00:00Z"}')
    assert wrote is False

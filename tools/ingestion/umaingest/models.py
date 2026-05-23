from __future__ import annotations
from datetime import datetime, timezone
from typing import Literal, Optional
from pydantic import BaseModel, field_serializer

Surface = Literal["turf", "dirt"]
DistanceClass = Literal["sprint", "mile", "medium", "long"]
Turn = Literal["clockwise", "counterclockwise", "straight"]
PhaseKind = Literal["open", "round1", "round2", "ended"]


def _iso_z(value) -> str:
    """Serialize a datetime/str to ISO-8601 with a 'Z' suffix (Swift .iso8601 contract)."""
    if isinstance(value, str):
        return value.replace("+00:00", "Z")
    dt = value.astimezone(timezone.utc).replace(microsecond=0)
    return dt.isoformat().replace("+00:00", "Z")


class _Base(BaseModel):
    model_config = {"extra": "forbid"}


class EventPeriod(_Base):
    start: datetime
    end: datetime
    estimated: bool = False

    @field_serializer("start", "end")
    def _ser(self, v): return _iso_z(v)


class EventPhase(_Base):
    kind: PhaseKind
    label: str
    date: datetime

    @field_serializer("date")
    def _ser(self, v): return _iso_z(v)


class TrackCondition(_Base):
    racecourse: str
    surface: Surface
    distanceMeters: int
    distanceClass: DistanceClass
    turn: Optional[Turn] = None
    courseSide: Optional[str] = None
    season: Optional[str] = None
    weather: Optional[str] = None
    ground: Optional[str] = None
    timeOfDay: Optional[str] = None
    imageURL: Optional[str] = None


class ChampionsMeeting(_Base):
    id: str
    codeName: str
    raceGrade: Optional[str] = None
    raceName: str
    track: TrackCondition
    period: EventPeriod
    phases: list[EventPhase]


class LeagueOfHeroes(_Base):
    id: str
    round: str
    raceName: str
    track: TrackCondition
    period: EventPeriod
    phases: list[EventPhase]


class SupportCardPick(_Base):
    rarity: str
    name: str
    type: str


class PickupPeriod(_Base):
    id: str
    period: EventPeriod
    trainees: list[str]
    supportCards: list[SupportCardPick]
    supportNote: str | None = None


class ScheduleDocument(_Base):
    version: int = 2
    updatedAt: datetime
    sourcePostNo: Optional[int] = None
    server: str = "kr"
    championsMeetings: list[ChampionsMeeting]
    leagueOfHeroes: list[LeagueOfHeroes]
    pickups: list[PickupPeriod]

    @field_serializer("updatedAt")
    def _ser(self, v): return _iso_z(v)

    def to_json(self) -> str:
        return self.model_dump_json(indent=2)

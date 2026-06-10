"""Strideby API — accounts, run upload, crossing detection, matching, chat.

Run locally:
    pip install -r requirements.txt
    uvicorn app.main:app --reload

All timestamps in request/response bodies are Unix epoch seconds.
"""
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import and_, func, or_, select
from sqlalchemy.orm import Session

from . import detection
from .db import (Crossing, Decision, Match, Message, Run, SessionLocal, User,
                 init_db, utcnow)
from .security import create_token, decode_token, hash_password, verify_password

app = FastAPI(title="Strideby API", version="0.1.0")


@app.on_event("startup")
def startup() -> None:
    init_db()


# --- dependencies -----------------------------------------------------------

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(authorization: str = Header(default=""),
                     db: Session = Depends(get_db)) -> User:
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "Missing bearer token")
    user_id = decode_token(authorization.removeprefix("Bearer ").strip())
    if user_id is None:
        raise HTTPException(401, "Invalid or expired token")
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(401, "Unknown user")
    return user


# --- helpers ----------------------------------------------------------------

def epoch(dt: datetime) -> float:
    return dt.replace(tzinfo=timezone.utc).timestamp()


def from_epoch(t: float) -> datetime:
    return datetime.fromtimestamp(t, tz=timezone.utc).replace(tzinfo=None)


def public_profile(user: User) -> dict:
    return {
        "id": user.id,
        "first_name": user.first_name,
        "age": user.age,
        "bio": user.bio,
        "pace_per_km": user.pace_per_km,
        "weekly_km": user.weekly_km,
        "favorite_distance": user.favorite_distance,
        "tags": user.tags or [],
        "emoji": user.emoji,
    }


def route_name(occurred_at: datetime) -> str:
    hour = occurred_at.hour
    if 5 <= hour < 11:
        return "Morning run"
    if 11 <= hour < 17:
        return "Daytime run"
    if 17 <= hour < 22:
        return "Evening run"
    return "Night run"


def other_user_and_run(crossing: Crossing, me: User, db: Session) -> tuple[User, Run]:
    other_id = crossing.user_b_id if crossing.user_a_id == me.id else crossing.user_a_id
    other_run_id = crossing.run_b_id if crossing.user_a_id == me.id else crossing.run_a_id
    return db.get(User, other_id), db.get(Run, other_run_id)


def crossing_payload(crossing: Crossing, me: User, db: Session) -> dict:
    other, other_run = other_user_and_run(crossing, me, db)
    duration = (other_run.ended_at - other_run.started_at).total_seconds()
    return {
        "id": crossing.id,
        "occurred_at": epoch(crossing.occurred_at),
        "overlap_minutes": max(1, round(crossing.overlap_seconds / 60)),
        "closest_meters": max(1, round(crossing.closest_meters)),
        "their_pace": detection.pace_str(other_run.distance_meters, duration)
                      or other.pace_per_km,
        "route_name": route_name(crossing.occurred_at),
        "profile": public_profile(other),
    }


def match_payload(match: Match, me: User, db: Session) -> dict:
    crossing = db.get(Crossing, match.crossing_id)
    other, _ = other_user_and_run(crossing, me, db)
    last = db.scalars(
        select(Message).where(Message.match_id == match.id)
        .order_by(Message.created_at.desc()).limit(1)
    ).first()
    return {
        "id": match.id,
        "matched_at": epoch(match.created_at),
        "occurred_at": epoch(crossing.occurred_at),
        "route_name": route_name(crossing.occurred_at),
        "overlap_minutes": max(1, round(crossing.overlap_seconds / 60)),
        "profile": public_profile(other),
        "last_message": message_payload(last, me) if last else None,
    }


def message_payload(message: Message, me: User) -> dict:
    return {
        "id": message.id,
        "sender": "me" if message.sender_id == me.id else "them",
        "text": message.text,
        "sent_at": epoch(message.created_at),
    }


# --- auth -------------------------------------------------------------------

class RegisterIn(BaseModel):
    email: str
    password: str = Field(min_length=8)
    first_name: str = Field(min_length=1, max_length=80)
    age: int = Field(ge=18, le=100)


class LoginIn(BaseModel):
    email: str
    password: str


@app.post("/auth/register")
def register(body: RegisterIn, db: Session = Depends(get_db)):
    email = body.email.strip().lower()
    if "@" not in email:
        raise HTTPException(422, "Invalid email")
    if db.scalars(select(User).where(User.email == email)).first():
        raise HTTPException(409, "An account with this email already exists")
    user = User(email=email, password_hash=hash_password(body.password),
                first_name=body.first_name.strip(), age=body.age)
    db.add(user)
    db.commit()
    return {"token": create_token(user.id), "profile": public_profile(user)}


@app.post("/auth/login")
def login(body: LoginIn, db: Session = Depends(get_db)):
    user = db.scalars(
        select(User).where(User.email == body.email.strip().lower())
    ).first()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "Wrong email or password")
    return {"token": create_token(user.id), "profile": public_profile(user)}


# --- profile ----------------------------------------------------------------

class ProfileUpdate(BaseModel):
    first_name: str | None = None
    age: int | None = Field(default=None, ge=18, le=100)
    bio: str | None = None
    pace_per_km: str | None = None
    weekly_km: int | None = Field(default=None, ge=0, le=500)
    favorite_distance: str | None = None
    tags: list[str] | None = None
    emoji: str | None = None
    ghost_mode: bool | None = None
    hide_home_zone: bool | None = None


@app.get("/me")
def get_me(me: User = Depends(get_current_user)):
    data = public_profile(me)
    data["email"] = me.email
    data["ghost_mode"] = me.ghost_mode
    data["hide_home_zone"] = me.hide_home_zone
    return data


@app.put("/me")
def update_me(body: ProfileUpdate, me: User = Depends(get_current_user),
              db: Session = Depends(get_db)):
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(me, field, value)
    db.add(me)
    db.commit()
    return get_me(me)


# --- runs + crossing detection ----------------------------------------------

class SampleIn(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    t: float


class RunIn(BaseModel):
    samples: list[SampleIn] = Field(min_length=2, max_length=50_000)


@app.post("/runs")
def upload_run(body: RunIn, me: User = Depends(get_current_user),
               db: Session = Depends(get_db)):
    samples = sorted([(s.lat, s.lon, s.t) for s in body.samples],
                     key=lambda s: s[2])
    lats = [s[0] for s in samples]
    lons = [s[1] for s in samples]
    run = Run(
        user_id=me.id,
        started_at=from_epoch(samples[0][2]),
        ended_at=from_epoch(samples[-1][2]),
        samples=samples,
        distance_meters=detection.track_distance_m(samples),
        min_lat=min(lats), max_lat=max(lats),
        min_lon=min(lons), max_lon=max(lons),
    )
    db.add(run)
    db.commit()

    new_crossings = 0 if me.ghost_mode else detect_crossings(run, me, db)
    return {"run_id": run.id, "new_crossings": new_crossings}


def detect_crossings(run: Run, me: User, db: Session) -> int:
    """Compare a freshly uploaded run against candidate runs and create
    Crossing rows for both users. Synchronous for the MVP; becomes a queued
    job at scale."""
    margin = 0.001  # ~110 m in latitude; generous everywhere for longitude
    candidates = db.scalars(
        select(Run).join(User, User.id == Run.user_id).where(
            Run.user_id != me.id,
            User.ghost_mode == False,  # noqa: E712 (SQLAlchemy expression)
            Run.started_at <= run.ended_at,
            Run.ended_at >= run.started_at,
            Run.min_lat <= run.max_lat + margin,
            Run.max_lat >= run.min_lat - margin,
            Run.min_lon <= run.max_lon + margin,
            Run.max_lon >= run.min_lon - margin,
        )
    ).all()

    my_samples = (detection.trim_home_zone(run.samples)
                  if me.hide_home_zone else run.samples)
    created = 0
    for candidate in candidates:
        # Product decision (MVP): one crossing per pair of users, ever.
        # Once someone has been liked/passed/matched, later runs together
        # don't resurface them.
        exists = db.scalars(select(Crossing).where(or_(
            and_(Crossing.user_a_id == me.id, Crossing.user_b_id == candidate.user_id),
            and_(Crossing.user_a_id == candidate.user_id, Crossing.user_b_id == me.id),
        ))).first()
        if exists:
            continue

        other = db.get(User, candidate.user_id)
        their_samples = (detection.trim_home_zone(candidate.samples)
                         if other.hide_home_zone else candidate.samples)
        stats = detection.overlap_stats(my_samples, their_samples)
        if stats.overlap_seconds < detection.MIN_OVERLAP_S:
            continue

        db.add(Crossing(
            run_a_id=run.id, run_b_id=candidate.id,
            user_a_id=me.id, user_b_id=candidate.user_id,
            overlap_seconds=stats.overlap_seconds,
            closest_meters=stats.closest_meters,
            closest_lat=stats.closest_lat,
            closest_lon=stats.closest_lon,
            occurred_at=from_epoch(stats.occurred_at_epoch),
        ))
        created += 1
    db.commit()
    return created


# --- run history ------------------------------------------------------------

def run_summary_payload(run: Run, db: Session) -> dict:
    crossing_count = db.scalar(
        select(func.count()).select_from(Crossing).where(
            or_(Crossing.run_a_id == run.id, Crossing.run_b_id == run.id))
    )
    return {
        "id": run.id,
        "started_at": epoch(run.started_at),
        "distance_meters": run.distance_meters,
        "duration_seconds": (run.ended_at - run.started_at).total_seconds(),
        "crossing_count": int(crossing_count or 0),
    }


@app.get("/runs")
def list_runs(me: User = Depends(get_current_user),
              db: Session = Depends(get_db)):
    runs = db.scalars(
        select(Run).where(Run.user_id == me.id)
        .order_by(Run.started_at.desc())
    ).all()
    return [run_summary_payload(r, db) for r in runs]


@app.get("/runs/{run_id}")
def run_detail(run_id: int, me: User = Depends(get_current_user),
               db: Session = Depends(get_db)):
    run = db.get(Run, run_id)
    if run is None or run.user_id != me.id:
        raise HTTPException(404, "Run not found")

    # Downsample the route so the map payload stays small.
    stride = max(1, len(run.samples) // 500)
    route = [[s[0], s[1]] for s in run.samples[::stride]]

    crossings = db.scalars(select(Crossing).where(
        or_(Crossing.run_a_id == run.id, Crossing.run_b_id == run.id)
    )).all()
    crossed = []
    for crossing in crossings:
        other_id = (crossing.user_b_id if crossing.user_a_id == me.id
                    else crossing.user_a_id)
        other = db.get(User, other_id)
        crossed.append({
            "profile": public_profile(other),
            "lat": crossing.closest_lat,
            "lon": crossing.closest_lon,
            "overlap_minutes": max(1, round(crossing.overlap_seconds / 60)),
            "occurred_at": epoch(crossing.occurred_at),
        })

    payload = run_summary_payload(run, db)
    payload["route"] = route
    payload["crossings"] = crossed
    return payload


# --- crossings feed ---------------------------------------------------------

@app.get("/crossings")
def list_crossings(me: User = Depends(get_current_user),
                   db: Session = Depends(get_db)):
    my_decisions = select(Decision.crossing_id).where(Decision.user_id == me.id)
    crossings = db.scalars(
        select(Crossing).where(
            or_(Crossing.user_a_id == me.id, Crossing.user_b_id == me.id),
            Crossing.id.not_in(my_decisions),
        ).order_by(Crossing.occurred_at.desc())
    ).all()
    return [crossing_payload(c, me, db) for c in crossings]


class DecisionIn(BaseModel):
    liked: bool


@app.post("/crossings/{crossing_id}/decision")
def decide(crossing_id: int, body: DecisionIn,
           me: User = Depends(get_current_user), db: Session = Depends(get_db)):
    crossing = db.get(Crossing, crossing_id)
    if crossing is None or me.id not in (crossing.user_a_id, crossing.user_b_id):
        raise HTTPException(404, "Crossing not found")
    if db.scalars(select(Decision).where(
            Decision.crossing_id == crossing_id,
            Decision.user_id == me.id)).first():
        raise HTTPException(409, "Already decided")

    db.add(Decision(crossing_id=crossing_id, user_id=me.id, liked=body.liked))
    db.commit()

    if not body.liked:
        return {"matched": False, "match": None}

    other_decision = db.scalars(select(Decision).where(
        Decision.crossing_id == crossing_id,
        Decision.user_id != me.id,
        Decision.liked == True,  # noqa: E712
    )).first()
    if other_decision is None:
        return {"matched": False, "match": None}

    match = Match(crossing_id=crossing_id)
    db.add(match)
    db.commit()
    return {"matched": True, "match": match_payload(match, me, db)}


# --- matches + chat ---------------------------------------------------------

def get_my_match(match_id: int, me: User, db: Session) -> Match:
    match = db.get(Match, match_id)
    if match is None:
        raise HTTPException(404, "Match not found")
    crossing = db.get(Crossing, match.crossing_id)
    if me.id not in (crossing.user_a_id, crossing.user_b_id):
        raise HTTPException(404, "Match not found")
    return match


@app.get("/matches")
def list_matches(me: User = Depends(get_current_user),
                 db: Session = Depends(get_db)):
    matches = db.scalars(
        select(Match).join(Crossing, Crossing.id == Match.crossing_id).where(
            or_(Crossing.user_a_id == me.id, Crossing.user_b_id == me.id)
        ).order_by(Match.created_at.desc())
    ).all()
    return [match_payload(m, me, db) for m in matches]


@app.get("/matches/{match_id}/messages")
def list_messages(match_id: int, me: User = Depends(get_current_user),
                  db: Session = Depends(get_db)):
    get_my_match(match_id, me, db)
    messages = db.scalars(
        select(Message).where(Message.match_id == match_id)
        .order_by(Message.created_at.asc())
    ).all()
    return [message_payload(m, me) for m in messages]


class MessageIn(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


@app.post("/matches/{match_id}/messages")
def send_message(match_id: int, body: MessageIn,
                 me: User = Depends(get_current_user),
                 db: Session = Depends(get_db)):
    get_my_match(match_id, me, db)
    message = Message(match_id=match_id, sender_id=me.id,
                      text=body.text.strip())
    db.add(message)
    db.commit()
    return message_payload(message, me)


@app.get("/health")
def health():
    return {"status": "ok", "time": epoch(utcnow())}

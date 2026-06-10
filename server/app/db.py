"""Database setup and models.

SQLite by default (zero setup for development). Set DATABASE_URL to a
Postgres URL in production — SQLAlchemy makes that a config change.
"""
import os
from datetime import datetime, timezone

from sqlalchemy import (
    JSON, Boolean, DateTime, Float, ForeignKey, Integer, String, Text,
    UniqueConstraint, create_engine,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker

DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./strideby.db")

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    first_name: Mapped[str] = mapped_column(String(80), default="Runner")
    age: Mapped[int] = mapped_column(Integer, default=25)
    bio: Mapped[str] = mapped_column(Text, default="")
    pace_per_km: Mapped[str] = mapped_column(String(20), default="")
    weekly_km: Mapped[int] = mapped_column(Integer, default=0)
    favorite_distance: Mapped[str] = mapped_column(String(40), default="")
    tags: Mapped[list] = mapped_column(JSON, default=list)
    emoji: Mapped[str] = mapped_column(String(8), default="🏃")
    ghost_mode: Mapped[bool] = mapped_column(Boolean, default=False)
    hide_home_zone: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Run(Base):
    __tablename__ = "runs"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime, index=True)
    ended_at: Mapped[datetime] = mapped_column(DateTime, index=True)
    # [[lat, lon, epoch_seconds], ...] sorted by time. JSON keeps the MVP
    # simple; move to PostGIS when run volume demands it.
    samples: Mapped[list] = mapped_column(JSON)
    distance_meters: Mapped[float] = mapped_column(Float, default=0.0)
    # Bounding box for cheap candidate prefiltering.
    min_lat: Mapped[float] = mapped_column(Float)
    max_lat: Mapped[float] = mapped_column(Float)
    min_lon: Mapped[float] = mapped_column(Float)
    max_lon: Mapped[float] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Crossing(Base):
    __tablename__ = "crossings"
    __table_args__ = (UniqueConstraint("run_a_id", "run_b_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    run_a_id: Mapped[int] = mapped_column(ForeignKey("runs.id"))
    run_b_id: Mapped[int] = mapped_column(ForeignKey("runs.id"))
    user_a_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    user_b_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    overlap_seconds: Mapped[float] = mapped_column(Float)
    closest_meters: Mapped[float] = mapped_column(Float)
    # Where the closest pass happened — shown on the run-detail map.
    closest_lat: Mapped[float] = mapped_column(Float, default=0.0)
    closest_lon: Mapped[float] = mapped_column(Float, default=0.0)
    occurred_at: Mapped[datetime] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Decision(Base):
    __tablename__ = "decisions"
    __table_args__ = (UniqueConstraint("crossing_id", "user_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    crossing_id: Mapped[int] = mapped_column(ForeignKey("crossings.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    liked: Mapped[bool] = mapped_column(Boolean)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[int] = mapped_column(primary_key=True)
    crossing_id: Mapped[int] = mapped_column(ForeignKey("crossings.id"), unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(primary_key=True)
    match_id: Mapped[int] = mapped_column(ForeignKey("matches.id"), index=True)
    sender_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    text: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


def init_db() -> None:
    Base.metadata.create_all(engine)

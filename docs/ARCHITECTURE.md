# Strideby — Technical Architecture

## System overview

```
┌─────────────┐     workout +        ┌──────────────────┐
│ Apple Watch │──── GPS route ──────▶│                  │
│ (HealthKit) │     via iPhone app   │                  │
└─────────────┘                      │   Strideby       │      ┌──────────────┐
                                     │   Backend        │◀────▶│  iOS app     │
┌─────────────┐     activity push    │                  │      │  (SwiftUI)   │
│   Garmin    │──── webhooks ───────▶│  - crossing jobs │      │  feed/match/ │
│ Health API  │     (FIT files)      │  - match + chat  │      │  chat UI     │
└─────────────┘                      └──────────────────┘      └──────────────┘
```

There is deliberately **no Bluetooth and no live location sharing**. Crossings are computed server-side after runs sync, the same way Strava's grouped-activities/Flyby feature works.

## Data sources

### Apple Watch — HealthKit (do this first)
- The iOS app requests read access to workouts and **workout routes** (`HKWorkoutRoute` = the GPS track).
- Zero partnership required, works for every Apple Watch user on day one.
- After each run, the app uploads the route to the backend (with user consent).

### Garmin — Garmin Health API (v1 milestone)
- Free developer program, but requires an application/approval (takes a few weeks — apply early).
- Once a user links their Garmin account (OAuth), Garmin **pushes** each activity to your server via webhook, including the GPS track. No polling needed.

### Strava — deliberately NOT used
- Strava's API agreement prohibits using their data for matchmaking/dating and for building competing products; they have a history of cutting off apps. Building your core feature on a competitor's API is also a terrible position to be acquired from.
- Strava matters as the *design benchmark* and *potential acquirer*, not as a data source.

## Crossing detection

Reference implementation: [`ios/Strideby/Reference/CrossingDetector.swift`](../ios/Strideby/Reference/CrossingDetector.swift).

1. **Ingest:** each synced run = a GPS track (≈1 sample/second) + time window.
2. **Candidate pairs:** index track points by `(geohash cell, 5-minute time bucket)`. Two runs sharing any bucket are candidates — this avoids comparing every run to every other run.
3. **Verify:** for each candidate pair, walk both tracks in time order; count seconds where the runners were within **25 m** at the same moment (haversine distance, ±5 s tolerance).
4. **Classify:**
   - ≥ 5 s within radius → a **crossing** (shows in the feed). This counts a genuine face-to-face pass (~8 s within 25 m at running speeds) while discarding single-sample GPS blips.
   - ≥ 5 min → "ran side by side" badge (stronger signal, shown on the card). The card always shows the overlap duration, so a long shared stretch reads differently from a brief pass.
5. **Fan out:** create a `Crossing` row for both users, send a push notification ("You crossed 2 runners on today's run 👀").

Postgres + PostGIS handles all of this comfortably to ~100k users; no exotic infrastructure needed.

## Backend (MVP)

| Concern | Choice | Why |
|---|---|---|
| API + jobs | One small service (e.g. TypeScript/Node or Python/FastAPI) | Boring and hireable |
| Database | Postgres + PostGIS | Geospatial queries built in |
| Auth | Sign in with Apple (required for App Store anyway) | Lowest friction |
| Chat | WebSockets, or Firebase/Stream to start | Don't build chat from scratch for MVP |
| Photos | S3-compatible storage + moderation API | Required for dating apps |

## Privacy & safety (this is make-or-break)

A dating app built on location data must be conservative by default. Non-negotiables, several already reflected in the prototype UI:

- **Opt-in only:** runs are never shared until the user explicitly connects a device and enables crossings.
- **No exact routes:** other users see "Riverside Loop, Tuesday morning" — never a map of your run.
- **Home-zone masking:** crossings within ~500 m of a user's habitual start/end points are discarded (Strava-style privacy zones).
- **Delay:** crossings appear hours after the run, never live.
- **Ghost mode:** keep syncing runs, stop appearing to others.
- **Match-gated chat:** mutual like required before any contact; optional women-message-first mode (Bumble playbook).
- **Block & report** with photo/message moderation — Apple rejects dating apps without robust moderation and easy account deletion (App Review Guidelines 1.2 / 5.1.1(v)). Dating apps are rated 17+.

## Why this can get acquired

- **happn** proved "people you crossed paths with" works as a dating mechanic; Strideby narrows it to a passionate, high-retention niche with *verified shared context* (you really were both out running at 6 am — that's compatibility data).
- The **crossing graph** (who runs where, when, at what pace) is a dataset neither Match Group nor Strava has.
- Build it on HealthKit + Garmin (not Strava's API) so the asset is independent and the integrations are exactly what an acquirer would rather buy than build.

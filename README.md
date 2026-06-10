# Strideby 🏃🧡

**The dating app for runners.** Record your run with an Apple Watch or Garmin like you always do — when your path crosses another Strideby runner's, you both show up in each other's feed. Like them, match, chat, and plan the next run together.

*Working name — easy to change. Tagline: "Cross paths. Match strides."*

---

## The key insight (read this first)

The Strava feature you noticed — where it said you "ran with" someone you merely passed — is called **grouped activities / Flyby**, and it does **not** use Bluetooth. Here's how it actually works, and how Strideby works too:

1. Both runners record GPS tracks on their watches.
2. The tracks upload to a server after the run.
3. The **server compares tracks**: same place (within ~25 m), same time, for long enough → "you crossed."

This has three important consequences for the product:

- **No Bluetooth needed.** Phones/watches can't grab a stranger's name and photo over Bluetooth — Apple wouldn't allow it, and it would be a privacy disaster.
- **Both people must be on the app.** You can only cross paths with other Strideby users. This is a classic chicken-and-egg problem — launch city by city, run-club by run-club (this is how happn and Tinder grew).
- **Detection happens after the run**, not live. That's actually a feature: it's safer (no real-time location), and it creates a delightful "check the app after your run" habit loop.

> ⚠️ **Do not build this on the Strava API.** Strava's API agreement explicitly prohibits using their data for dating/matchmaking apps, and they shut off API access for competitors. Use **HealthKit** (Apple Watch) and the **Garmin Health API** (requires a free developer-program application) to read runs directly. Details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## What's in this repo

A fully working **SwiftUI prototype** with mock data — every screen of the core loop, in the Strava × Bumble design language you described (Strava orange `#FC5200` + Bumble yellow `#FFC629`):

| Screen | What it does |
|---|---|
| Onboarding | Brand intro, "how it works", connect-your-watch, basic profile |
| Crossings | Bumble-style swipe deck of runners you crossed, with run context (route, time side-by-side, closest pass, their pace) |
| It's a Run-In! | Full-screen match celebration when a like is mutual |
| Matches | Your matches with last-message preview |
| Chat | Messaging with run-context header and icebreaker suggestions |
| Profile | Your stats, connected devices, and privacy controls (ghost mode, home-zone hiding) |

Plus `ios/Strideby/Reference/CrossingDetector.swift` — a readable reference implementation of the GPS crossing-detection algorithm the backend will run.

**What's mocked:** profiles, crossings, watch connections, and chat replies. There is no backend yet — that's the next milestone.

## Run it (no experience needed)

You need a Mac with **Xcode** (free, from the Mac App Store).

**Option A — simplest:**
1. Open Xcode → *Create New Project* → iOS → **App**. Name it `Strideby`, Interface: **SwiftUI**, Language: **Swift**.
2. In the new project, delete the generated `ContentView.swift` and `StridebyApp.swift`.
3. Drag everything inside `ios/Strideby/` from this repo into Xcode's file list (check *"Copy items if needed"* and add to the Strideby target).
4. Press **▶** to launch the iPhone simulator.

**Option B — with [XcodeGen](https://github.com/yonaskolb/XcodeGen):**
```bash
brew install xcodegen
cd ios && xcodegen generate && open Strideby.xcodeproj
```

## Roadmap

1. **v0 (this repo):** clickable prototype — use it to get feedback from runners and show investors/partners.
2. **MVP:** real backend (accounts, photo profiles, crossing detection, matching, chat), HealthKit sync for Apple Watch users, TestFlight beta in one city.
3. **v1:** Garmin Health API integration, push notifications ("You crossed 3 runners today"), safety/moderation tooling (required for App Store dating apps), women-message-first option (the Bumble playbook).
4. **Growth:** partner with run clubs and parkrun-style events — one event seeds hundreds of mutual crossings at once.

The acquisition story (Strava or Match Group) gets credible at: one city with weekly active runners, a defensible crossing-graph dataset, and watch integrations they'd rather buy than build. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full technical plan, privacy/safety design, and App Store requirements.

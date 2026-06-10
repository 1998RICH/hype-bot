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

**1. A real backend** (`server/`) — accounts, run upload, GPS crossing detection, matching, and chat, with a full test suite. Deployable to a free Render instance in ~10 minutes; see [server/README.md](server/README.md).

**2. The iOS app** (`ios/`) — every screen of the core loop, in a dark "night runner" design language with **three switchable design directions** (Profile → Design lab): *Neon Night* (gradients & violet haze), *Volt Minimal* (clean black & electric yellow), and *Sunset Club* (bold amber blocks). All three carry the warm orange/yellow brand:

| Screen | What it does |
|---|---|
| Onboarding | Brand intro, "how it works", connect-your-watch, basic profile |
| Crossings | Bumble-style swipe deck of runners you crossed, with run context (route, time side-by-side, closest pass, their pace) |
| It's a Run-In! | Full-screen match celebration when a like is mutual |
| Matches | Your matches with last-message preview |
| Chat | Messaging with run-context header and icebreaker suggestions |
| Profile | Your stats, connected devices, and privacy controls (ghost mode, home-zone hiding) |

**Two modes, one switch.** Out of the box the app runs in **demo mode** (mock data, no server — perfect for showing people). Deploy the backend, paste its URL into `ios/Strideby/AppConfig.swift`, and it becomes **live mode**: real accounts, Apple Watch run sync via HealthKit, real crossings computed by the server, real matches and chat. There's even an "Upload a test run" button in the Profile tab so two testers can cross each other without going for a run.

## Run it (no experience needed)

You need a Mac with **Xcode** (free, from the Mac App Store — version 16 or newer).

1. Double-click **`ios/Strideby.xcodeproj`** — the project opens in Xcode with all files already in place.
2. Press **▶** to launch the iPhone simulator.

That's it. The HealthKit capability and privacy text are pre-configured; for running on a real iPhone you only need to pick your (free) Apple ID team under *Signing & Capabilities*.

## Roadmap

1. **v0 — done:** clickable prototype + working backend with accounts, crossing detection, matching, and chat.
2. **MVP — next:** deploy the backend, switch on live mode, TestFlight beta with real runners in one city. Add photo profiles + moderation.
3. **v1:** Garmin sync (via Terra first, direct Garmin Health API once a legal entity exists), push notifications ("You crossed 3 runners today"), safety/moderation tooling (required for App Store dating apps), women-message-first option (the Bumble playbook).
4. **Growth:** partner with run clubs and parkrun-style events — one event seeds hundreds of mutual crossings at once.

The acquisition story (Strava or Match Group) gets credible at: one city with weekly active runners, a defensible crossing-graph dataset, and watch integrations they'd rather buy than build. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full technical plan, privacy/safety design, and App Store requirements.

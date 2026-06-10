import CoreLocation
import SwiftUI

/// Single source of truth for the app.
///
/// Two modes:
///  - Demo mode (AppConfig.apiBaseURL == nil): everything runs on MockData —
///    no server, no account, instant to show around.
///  - Live mode: real accounts, HealthKit run sync, and crossings computed
///    by the backend in server/.
final class AppState: ObservableObject {
    /// nil in demo mode.
    let api = APIClient()
    var isLive: Bool { api != nil }

    @Published var hasOnboarded = false
    @Published var me = MockData.me
    @Published var appleWatchConnected = false
    @Published var garminConnected = false

    /// Crossings you haven't liked or passed on yet.
    @Published var pendingCrossings: [Crossing] = []
    @Published var matches: [Match] = []
    /// Non-nil while the "It's a Run-In!" overlay is showing.
    @Published var newMatch: Match?
    /// Your recorded runs, newest first.
    @Published var runs: [RunSummary] = []
    private var demoRunStore: [String: RunDetail] = [:]

    // Live-mode state
    @Published var needsAuth = false
    @Published var authError: String?
    @Published var isSyncing = false
    @Published var syncStatus: String?
    /// Hidden while a detail screen (chat, run detail) is open.
    @Published var hideTabBar = false

    /// Active design direction (Profile → Design lab).
    @Published var design: DesignVariant = .voltMinimal {
        didSet {
            Theme.variant = design
            UserDefaults.standard.set(design.rawValue, forKey: Self.designKey)
        }
    }

    private static let lastSyncKey = "strideby.lastHealthKitSync"
    private static let designKey = "strideby.design"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.designKey),
           let saved = DesignVariant(rawValue: raw) {
            design = saved
        }
        Theme.variant = design
        if let api {
            if api.token != nil {
                hasOnboarded = true
                Task { @MainActor in await refresh() }
            }
        } else {
            pendingCrossings = MockData.crossings
            matches = MockData.seedMatches
            for detail in MockData.demoRunDetails {
                demoRunStore[detail.summary.id] = detail
                runs.append(detail.summary)
            }
        }
    }

    func finishOnboarding(name: String, age: Int) {
        if !name.isEmpty { me.firstName = name }
        me.age = age
        hasOnboarded = true
        if isLive && api?.token == nil { needsAuth = true }
    }

    // MARK: - Auth (live mode)

    @MainActor
    func authenticate(register: Bool, email: String, password: String,
                      firstName: String, age: Int) async {
        guard let api else { return }
        authError = nil
        do {
            let response: APIClient.AuthResponse
            if register {
                let name = firstName.trimmingCharacters(in: .whitespaces)
                response = try await api.register(
                    email: email, password: password,
                    firstName: name.isEmpty ? me.firstName : name, age: age)
            } else {
                response = try await api.login(email: email, password: password)
            }
            me = Self.profile(from: response.profile)
            needsAuth = false
            await refresh()
        } catch {
            authError = error.localizedDescription
        }
    }

    func signOut() {
        guard let api else { return }
        api.logout()
        pendingCrossings = []
        matches = []
        needsAuth = true
    }

    // MARK: - Feed actions

    func like(_ crossing: Crossing) {
        pendingCrossings.removeAll { $0.id == crossing.id }
        if let api {
            Task { @MainActor in
                guard let id = Int(crossing.id),
                      let response = try? await api.decide(crossingID: id, liked: true)
                else { return }
                if response.matched, let dto = response.match {
                    let match = Self.match(from: dto)
                    matches.insert(match, at: 0)
                    newMatch = match
                }
            }
        } else if crossing.profile.likesYou {
            let match = Match(id: UUID().uuidString, crossing: crossing,
                              messages: [], matchedAt: .now)
            matches.insert(match, at: 0)
            newMatch = match
        }
    }

    func pass(_ crossing: Crossing) {
        pendingCrossings.removeAll { $0.id == crossing.id }
        if let api, let id = Int(crossing.id) {
            Task { try? await api.decide(crossingID: id, liked: false) }
        }
    }

    /// Demo helper: pretend a fresh run just synced from the watch.
    func syncDemoRun() {
        guard !isLive else { return }
        pendingCrossings = MockData.crossings
    }

    // MARK: - Server sync (live mode)

    @MainActor
    func refresh() async {
        guard let api, api.token != nil else { return }
        do {
            pendingCrossings = try await api.crossings().map(Self.crossing(from:))
            matches = try await api.matches().map(Self.match(from:))
        } catch {
            syncStatus = "Couldn't reach the server: \(error.localizedDescription)"
        }
    }

    @MainActor
    func syncFromHealthKit() async {
        guard let api else { return }
        guard HealthKitManager.shared.isAvailable else {
            syncStatus = "Health data isn't available on this device."
            return
        }
        isSyncing = true
        syncStatus = nil
        defer { isSyncing = false }
        do {
            try await HealthKitManager.shared.requestAuthorization()
            appleWatchConnected = true
            let since = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
            let workouts = try await HealthKitManager.shared.runningWorkouts(since: since)
            var uploaded = 0
            var found = 0
            for workout in workouts {
                let points = try await HealthKitManager.shared.routePoints(for: workout)
                guard points.count >= 2 else { continue }  // e.g. treadmill runs
                let response = try await api.uploadRun(points: points)
                uploaded += 1
                found += response.newCrossings
            }
            UserDefaults.standard.set(Date.now, forKey: Self.lastSyncKey)
            syncStatus = uploaded == 0
                ? "No new runs with GPS in the last 14 days."
                : "Synced \(uploaded) run\(uploaded == 1 ? "" : "s") · \(found) new crossing\(found == 1 ? "" : "s")"
            await refresh()
        } catch {
            syncStatus = "Sync failed: \(error.localizedDescription)"
        }
    }

    /// Testing aid (live mode): uploads a synthetic 30-minute run on a fixed
    /// route ending just now. Two testers who both tap this will cross each
    /// other — no Apple Watch required to try the full loop.
    @MainActor
    func uploadTestRun() async {
        guard let api else { return }
        let start = Date.now.timeIntervalSince1970 - 1800
        let points = (0..<1500).map { second in
            APIClient.GPSPoint(lat: 40.0 + 3.0 * Double(second) / 111_320.0,
                               lon: -73.97,
                               t: start + Double(second))
        }
        do {
            let response = try await api.uploadRun(points: points)
            syncStatus = "Test run uploaded · \(response.newCrossings) new crossing\(response.newCrossings == 1 ? "" : "s")"
            await refresh()
        } catch {
            syncStatus = "Upload failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Run recording & history

    @MainActor
    func loadRuns() async {
        guard let api, api.token != nil else { return }
        if let dtos = try? await api.runs() {
            runs = dtos.map(Self.runSummary(from:))
        }
    }

    @MainActor
    func runDetail(for id: String) async -> RunDetail? {
        if let api {
            guard let intID = Int(id),
                  let dto = try? await api.runDetail(id: intID) else { return nil }
            return Self.runDetail(from: dto)
        }
        return demoRunStore[id]
    }

    /// Called when the in-app recorder finishes a run.
    @MainActor
    func finishRun(points: [APIClient.GPSPoint]) async {
        guard points.count >= 10 else {
            syncStatus = "Run too short to save — keep moving a bit longer next time."
            return
        }
        if let api {
            do {
                let response = try await api.uploadRun(points: points)
                syncStatus = "Run saved · \(response.newCrossings) new crossing\(response.newCrossings == 1 ? "" : "s")"
                await loadRuns()
                await refresh()
            } catch {
                syncStatus = "Couldn't save the run: \(error.localizedDescription)"
            }
        } else {
            let coordinates = points.map {
                CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
            }
            let summary = RunSummary(
                id: UUID().uuidString,
                date: Date(timeIntervalSince1970: points.first?.t ?? Date.now.timeIntervalSince1970),
                distanceMeters: Self.trackDistance(points),
                durationSeconds: (points.last?.t ?? 0) - (points.first?.t ?? 0),
                crossingCount: 0
            )
            demoRunStore[summary.id] = RunDetail(summary: summary,
                                                 coordinates: coordinates,
                                                 crossed: [])
            runs.insert(summary, at: 0)
            syncStatus = "Run saved. (Demo mode — connect a server to find real crossings.)"
        }
    }

    private static func trackDistance(_ points: [APIClient.GPSPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        var total = 0.0
        for (a, b) in zip(points, points.dropFirst()) {
            total += CLLocation(latitude: a.lat, longitude: a.lon)
                .distance(from: CLLocation(latitude: b.lat, longitude: b.lon))
        }
        return total
    }

    func updatePrivacy(ghostMode: Bool? = nil, hideHomeZone: Bool? = nil) {
        guard let api else { return }
        Task {
            try? await api.updatePrivacy(ghostMode: ghostMode,
                                         hideHomeZone: hideHomeZone)
        }
    }

    // MARK: - Chat

    func send(_ text: String, in matchID: String) {
        if let api {
            Task { @MainActor in
                guard let id = Int(matchID),
                      let dto = try? await api.sendMessage(matchID: id, text: text)
                else { return }
                append(Self.message(from: dto), to: matchID)
            }
        } else {
            append(ChatMessage(id: UUID().uuidString, sender: .me,
                               text: text, date: .now), to: matchID)
            scheduleDemoReply(for: matchID)
        }
    }

    @MainActor
    func loadMessages(for matchID: String) async {
        guard let api, let id = Int(matchID) else { return }
        guard let dtos = try? await api.messages(matchID: id) else { return }
        if let index = matches.firstIndex(where: { $0.id == matchID }) {
            matches[index].messages = dtos.map(Self.message(from:))
        }
    }

    private func append(_ message: ChatMessage, to matchID: String) {
        guard let index = matches.firstIndex(where: { $0.id == matchID }) else { return }
        matches[index].messages.append(message)
    }

    /// Demo-only: canned replies so chat feels alive without a backend.
    private func scheduleDemoReply(for matchID: String) {
        let replies = [
            "Ha! I was wondering who flew past me 😄",
            "Sunrise on that loop is unbeatable, right?",
            "I'm in. Loser buys the post-run coffee ☕️",
            "Deal — same spot, Saturday 8am?"
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self,
                  let index = self.matches.firstIndex(where: { $0.id == matchID })
            else { return }
            let reply = replies[self.matches[index].messages.count % replies.count]
            self.matches[index].messages.append(
                ChatMessage(id: UUID().uuidString, sender: .them,
                            text: reply, date: .now)
            )
        }
    }

    // MARK: - DTO mapping

    static func profile(from dto: APIClient.ProfileDTO) -> RunnerProfile {
        RunnerProfile(
            id: String(dto.id),
            firstName: dto.firstName,
            age: dto.age,
            bio: dto.bio,
            pacePerKm: dto.pacePerKm,
            weeklyKm: dto.weeklyKm,
            favoriteDistance: dto.favoriteDistance,
            tags: dto.tags,
            emoji: dto.emoji.isEmpty ? "🏃" : dto.emoji,
            avatarColors: [Theme.yellow, Theme.orange],
            likesYou: false
        )
    }

    static func crossing(from dto: APIClient.CrossingDTO) -> Crossing {
        Crossing(
            id: String(dto.id),
            profile: profile(from: dto.profile),
            routeName: dto.routeName,
            date: Date(timeIntervalSince1970: dto.occurredAt),
            overlapMinutes: dto.overlapMinutes,
            closestDistanceMeters: dto.closestMeters,
            theirPace: dto.theirPace
        )
    }

    static func match(from dto: APIClient.MatchDTO) -> Match {
        Match(
            id: String(dto.id),
            crossing: Crossing(
                id: "match-\(dto.id)",
                profile: profile(from: dto.profile),
                routeName: dto.routeName,
                date: Date(timeIntervalSince1970: dto.occurredAt),
                overlapMinutes: dto.overlapMinutes,
                closestDistanceMeters: 0,
                theirPace: dto.profile.pacePerKm
            ),
            messages: dto.lastMessage.map { [message(from: $0)] } ?? [],
            matchedAt: Date(timeIntervalSince1970: dto.matchedAt)
        )
    }

    static func message(from dto: APIClient.MessageDTO) -> ChatMessage {
        ChatMessage(
            id: String(dto.id),
            sender: dto.sender == "me" ? .me : .them,
            text: dto.text,
            date: Date(timeIntervalSince1970: dto.sentAt)
        )
    }

    static func runSummary(from dto: APIClient.RunSummaryDTO) -> RunSummary {
        RunSummary(
            id: String(dto.id),
            date: Date(timeIntervalSince1970: dto.startedAt),
            distanceMeters: dto.distanceMeters,
            durationSeconds: dto.durationSeconds,
            crossingCount: dto.crossingCount
        )
    }

    static func runDetail(from dto: APIClient.RunDetailDTO) -> RunDetail {
        RunDetail(
            summary: RunSummary(
                id: String(dto.id),
                date: Date(timeIntervalSince1970: dto.startedAt),
                distanceMeters: dto.distanceMeters,
                durationSeconds: dto.durationSeconds,
                crossingCount: dto.crossings.count
            ),
            coordinates: dto.route.compactMap { pair in
                pair.count == 2
                    ? CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
                    : nil
            },
            crossed: dto.crossings.enumerated().map { index, crossed in
                CrossedRunner(
                    id: "\(dto.id)-\(index)",
                    profile: profile(from: crossed.profile),
                    coordinate: (crossed.lat != nil && crossed.lon != nil)
                        ? CLLocationCoordinate2D(latitude: crossed.lat!,
                                                 longitude: crossed.lon!)
                        : nil,
                    overlapMinutes: crossed.overlapMinutes
                )
            }
        )
    }
}

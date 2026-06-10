import Foundation

/// Talks to the Strideby backend (server/ in this repo).
/// All timestamps on the wire are Unix epoch seconds; JSON keys are
/// snake_case and converted automatically.
final class APIClient {
    struct APIError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private let baseURL: URL
    private static let tokenKey = "strideby.authToken"

    /// nil when no backend is configured — the app stays in demo mode.
    init?() {
        guard let url = AppConfig.apiBaseURL else { return nil }
        baseURL = url
    }

    // TODO: move to Keychain before a public release.
    var token: String? {
        get { UserDefaults.standard.string(forKey: Self.tokenKey) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: Self.tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.tokenKey)
            }
        }
    }

    func logout() { token = nil }

    // MARK: - DTOs

    struct ProfileDTO: Decodable {
        let id: Int
        let firstName: String
        let age: Int
        let bio: String
        let pacePerKm: String
        let weeklyKm: Int
        let favoriteDistance: String
        let tags: [String]
        let emoji: String
    }

    struct AuthResponse: Decodable {
        let token: String
        let profile: ProfileDTO
    }

    struct CrossingDTO: Decodable {
        let id: Int
        let occurredAt: Double
        let overlapMinutes: Int
        let closestMeters: Int
        let lat: Double?
        let lon: Double?
        let theirPace: String
        let routeName: String
        let profile: ProfileDTO
    }

    struct MessageDTO: Decodable {
        let id: Int
        let sender: String   // "me" | "them"
        let text: String
        let sentAt: Double
    }

    struct MatchDTO: Decodable {
        let id: Int
        let matchedAt: Double
        let occurredAt: Double
        let routeName: String
        let overlapMinutes: Int
        let profile: ProfileDTO
        let lastMessage: MessageDTO?
    }

    struct DecisionResponse: Decodable {
        let matched: Bool
        let match: MatchDTO?
    }

    struct RunResponse: Decodable {
        let runId: Int
        let newCrossings: Int
    }

    struct RunSummaryDTO: Decodable {
        let id: Int
        let startedAt: Double
        let distanceMeters: Double
        let durationSeconds: Double
        let crossingCount: Int
    }

    struct RunCrossedDTO: Decodable {
        let profile: ProfileDTO
        let lat: Double?
        let lon: Double?
        let overlapMinutes: Int
    }

    struct RunDetailDTO: Decodable {
        let id: Int
        let startedAt: Double
        let distanceMeters: Double
        let durationSeconds: Double
        let route: [[Double]]
        let crossings: [RunCrossedDTO]
    }

    struct GPSPoint: Encodable {
        let lat: Double
        let lon: Double
        let t: Double
    }

    // MARK: - Endpoints

    func register(email: String, password: String, firstName: String,
                  age: Int) async throws -> AuthResponse {
        let body = try JSONSerialization.data(withJSONObject: [
            "email": email, "password": password,
            "first_name": firstName, "age": age,
        ])
        let response: AuthResponse = try await request(
            "POST", "auth/register", bodyData: body, authorized: false)
        token = response.token
        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONSerialization.data(withJSONObject: [
            "email": email, "password": password,
        ])
        let response: AuthResponse = try await request(
            "POST", "auth/login", bodyData: body, authorized: false)
        token = response.token
        return response
    }

    func crossings() async throws -> [CrossingDTO] {
        try await request("GET", "crossings")
    }

    func decide(crossingID: Int, liked: Bool) async throws -> DecisionResponse {
        let body = try JSONSerialization.data(withJSONObject: ["liked": liked])
        return try await request("POST", "crossings/\(crossingID)/decision",
                                 bodyData: body)
    }

    func matches() async throws -> [MatchDTO] {
        try await request("GET", "matches")
    }

    func messages(matchID: Int) async throws -> [MessageDTO] {
        try await request("GET", "matches/\(matchID)/messages")
    }

    func sendMessage(matchID: Int, text: String) async throws -> MessageDTO {
        let body = try JSONSerialization.data(withJSONObject: ["text": text])
        return try await request("POST", "matches/\(matchID)/messages",
                                 bodyData: body)
    }

    func uploadRun(points: [GPSPoint]) async throws -> RunResponse {
        struct RunUpload: Encodable { let samples: [GPSPoint] }
        let body = try JSONEncoder().encode(RunUpload(samples: points))
        return try await request("POST", "runs", bodyData: body)
    }

    func runs() async throws -> [RunSummaryDTO] {
        try await request("GET", "runs")
    }

    func runDetail(id: Int) async throws -> RunDetailDTO {
        try await request("GET", "runs/\(id)")
    }

    func updatePrivacy(ghostMode: Bool?, hideHomeZone: Bool?) async throws {
        var fields: [String: Any] = [:]
        if let ghostMode { fields["ghost_mode"] = ghostMode }
        if let hideHomeZone { fields["hide_home_zone"] = hideHomeZone }
        guard !fields.isEmpty else { return }
        struct MeDTO: Decodable { let ghostMode: Bool; let hideHomeZone: Bool }
        let body = try JSONSerialization.data(withJSONObject: fields)
        let _: MeDTO = try await request("PUT", "me", bodyData: body)
    }

    // MARK: - Plumbing

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private struct ErrorBody: Decodable { let detail: String? }

    private func request<T: Decodable>(_ method: String, _ path: String,
                                       bodyData: Data? = nil,
                                       authorized: Bool = true) async throws -> T {
        var urlRequest = URLRequest(url: baseURL.appending(path: path))
        urlRequest.httpMethod = method
        urlRequest.httpBody = bodyData
        if bodyData != nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authorized, let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "No response from server")
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401, authorized { token = nil }
            let detail = (try? decoder.decode(ErrorBody.self, from: data))?.detail
            throw APIError(message: detail ?? "Server error (\(http.statusCode))")
        }
        return try decoder.decode(T.self, from: data)
    }
}

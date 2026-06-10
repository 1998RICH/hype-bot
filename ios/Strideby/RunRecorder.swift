import CoreLocation
import Foundation

/// Records a run with the iPhone's own GPS — no watch or third-party app
/// needed. Keeps recording with the screen locked (the project enables the
/// `location` background mode and shows iOS's standard indicator).
final class RunRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var distanceMeters: Double = 0

    private(set) var points: [APIClient.GPSPoint] = []
    private let manager = CLLocationManager()
    private var timer: Timer?
    private var startedAt: Date?
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        points = []
        distanceMeters = 0
        elapsed = 0
        lastLocation = nil
        startedAt = .now
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
        isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let startedAt = self.startedAt else { return }
            self.elapsed = Date.now.timeIntervalSince(startedAt)
        }
    }

    /// Stops recording and returns the captured GPS track.
    func stop() -> [APIClient.GPSPoint] {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        timer?.invalidate()
        timer = nil
        isRecording = false
        return points
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard isRecording else { return }
        for location in locations
        where location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 {
            if let last = lastLocation {
                distanceMeters += location.distance(from: last)
            }
            lastLocation = location
            points.append(APIClient.GPSPoint(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude,
                t: location.timestamp.timeIntervalSince1970
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        // Transient GPS errors are common (tunnels, signal loss) — keep going.
    }
}

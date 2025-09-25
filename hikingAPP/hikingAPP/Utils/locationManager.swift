//
//  locationManager.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/9/13.
//

import CoreLocation


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var manager = CLLocationManager()

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var elevation: Double?
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var locationHistory: [CLLocationCoordinate2D] = []

    private let maxHistoryCount = 5
    private let updateInterval: TimeInterval = 10 // seconds
    private var lastHistoryUpdateTime: Date = .distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        // Store previous coordinate as lastLocation
        if let current = coordinate {
            lastLocation = current
        }

        coordinate = latest.coordinate
        elevation = latest.altitude

        let now = Date()
            if now.timeIntervalSince(lastHistoryUpdateTime) >= updateInterval {
                lastHistoryUpdateTime = now

                locationHistory.append(latest.coordinate)

                if locationHistory.count > maxHistoryCount {
                    locationHistory.removeFirst(locationHistory.count - maxHistoryCount)
                }
            }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}

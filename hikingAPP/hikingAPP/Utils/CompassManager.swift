//
//  CompassManager.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/9/5.
//

import Foundation
import CoreLocation

class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    @Published var heading: CLHeading?
    

    override init() {
        super.init()
        locationManager.delegate = self

        locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = kCLHeadingFilterNone
            locationManager.startUpdatingHeading()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
}

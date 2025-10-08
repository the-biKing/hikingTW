//
//  hikingAPPApp.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/9/5.
//

import SwiftUI
import UserNotifications

@main
struct hikingAPPApp: App {
    @StateObject var navigationViewModel = NavigationViewModel()
    @StateObject var locationManager = LocationManager()
    @StateObject var compass = CompassManager()

    
    init() {
        ensureUserJSONExists()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                 if let error = error {
                     print("Notification permission error: \(error)")
                 }
             }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack
            {
                MainView()
                    .environmentObject(navigationViewModel)
                    .environmentObject(locationManager)
                    .environmentObject(compass)
            }
        }
    }
}

// MARK: - Ensure user.json exists in Documents
func ensureUserJSONExists() {
    let fm = FileManager.default
    guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    let userFileURL = docs.appendingPathComponent("user.json")
    
    if !fm.fileExists(atPath: userFileURL.path) {
        if let bundleURL = Bundle.main.url(forResource: "user", withExtension: "json") {
            do {
                try fm.copyItem(at: bundleURL, to: userFileURL)
                print("✅ Copied default user.json to Documents")
            } catch {
                print("❌ Failed to copy user.json to Documents: \(error)")
            }
        } else {
            print("❌ Default user.json not found in bundle")
        }
    }
}


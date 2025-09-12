//
//  hikingAPPApp.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/9/5.
//

import SwiftUI

@main
struct hikingAPPApp: App {
    @StateObject var navigationViewModel = NavigationViewModel()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(navigationViewModel)
        }
    }
}

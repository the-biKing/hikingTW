//
//  NavigationViewModel.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/9/10.
//

import Foundation

enum PlanState {
    case idle
    case active
    case offRoute
}



class NavigationViewModel: ObservableObject {
    @Published var planState: PlanState = .idle
    @Published var currentPlan: [String] = []
    
    init() {
            // preload test plan
            currentPlan = ["ntust_tr", "ntust_ib","ntust_ee"]
            planState = .active
        }
}

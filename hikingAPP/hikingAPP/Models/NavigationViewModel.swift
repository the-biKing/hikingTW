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
    @Published var prevNodeID: String? = nil
    @Published var nextNodeID: String? = nil
    @Published var segmentDistanceLeft: Double = 0.0
    
    init() {
            planState = .idle
        }
    //TODO handle multiple day plan
    func loadPlan(from graphVM: GraphViewModel) {
        if let firstDayPlan = graphVM.history.first {
            self.currentPlan = firstDayPlan
            self.planState = .idle
        } else {
            print("⚠️ No plan available in history")
        }
    }
}

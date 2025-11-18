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
    @Published var dayIndex: Int = 0   // default until multi-day logic is ready
    
    
    //TODO create multi day helper
    func setCurrentDay(_ index: Int) {
        self.dayIndex = index
        UserDefaults.standard.set(index, forKey: "CurrentDayIndex")
        loadPlanFromSavedHistory()
    }
    
    init() {
            planState = .idle
            loadPlanFromSavedHistory()
            if let savedIndex = UserDefaults.standard.object(forKey: "CurrentDayIndex") as? Int {
                self.dayIndex = savedIndex
            }
        }
    
    func loadPlanFromSavedHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]],
           !savedHistory.isEmpty {
            // Use the current day index plan as the current plan
            let index = min(dayIndex, savedHistory.count - 1)
            self.currentPlan = savedHistory[index]
        } else {
            // Fallback if nothing saved
            self.currentPlan = []
            self.planState = .idle
            print("⚠️ No plan available in saved history")
        }
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

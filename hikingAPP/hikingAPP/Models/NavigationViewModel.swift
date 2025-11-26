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
    @Published var planIndex: Int = 0   // tracks progress within current day's plan
    
    init() {
        planState = .idle
        loadPlanFromSavedHistory()
    }
    
    
    // Returns last node of today's plan
    func lastNodeOfToday() -> String? {
        let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
        guard dayIndex < savedHistory.count else { return nil }
        return savedHistory[dayIndex].last
    }

    // Returns last segment of today's plan (direction-aware)
    func lastSegmentOfToday() -> (from: String, to: String)? {
        let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
        guard dayIndex < savedHistory.count else { return nil }
        let plan = savedHistory[dayIndex]
        guard plan.count >= 2 else { return nil }
        return (from: plan[plan.count - 2], to: plan.last!)
    }

    // Multi-day advancement logic
    func tryAdvanceDay(reachedNode: String? = nil, completedSegment: (from: String, to: String)? = nil) {
        let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
        guard dayIndex < savedHistory.count else { return }

        // Rule 1: reached last node
        if let node = reachedNode,
           let lastNode = lastNodeOfToday(),
           node == lastNode {

            if dayIndex + 1 < savedHistory.count {
                setCurrentDay(dayIndex + 1)
                print("📅 Auto-advanced to Day \(dayIndex + 1) by node")
            }
            return
        }

        // Rule 2: completed last segment
        if let seg = completedSegment,
           let lastSeg = lastSegmentOfToday(),
           seg.from == lastSeg.from && seg.to == lastSeg.to {

            if dayIndex + 1 < savedHistory.count {
                setCurrentDay(dayIndex + 1)
                print("📅 Auto-advanced to Day \(dayIndex + 1) by segment")
            }
            return
        }
    }
    
    func setCurrentDay(_ index: Int) {
        self.dayIndex = index
        UserDefaults.standard.set(index, forKey: "CurrentDayIndex")
        self.planIndex = 0
        UserDefaults.standard.set(0, forKey: "CurrentPlanIndex")
        loadPlanFromSavedHistory()
    }
    
    
    
    func loadPlanFromSavedHistory() {
        // Load saved day index
        if let savedIndex = UserDefaults.standard.object(forKey: "CurrentDayIndex") as? Int {
            self.dayIndex = savedIndex
        }
        if let savedPlanIndex = UserDefaults.standard.object(forKey: "CurrentPlanIndex") as? Int {
            self.planIndex = savedPlanIndex
        }
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

    func loadPlan(from graphVM: GraphViewModel) {
        if let firstDayPlan = graphVM.history.first {
            self.currentPlan = firstDayPlan
            self.planState = .idle
        } else {
            print("⚠️ No plan available in history")
        }
    }
}

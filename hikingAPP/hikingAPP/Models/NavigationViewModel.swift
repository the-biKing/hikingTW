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
    case evacuate
    case changeOfPlan
}

class NavigationViewModel: ObservableObject {
    @Published var planState: PlanState = .idle
}

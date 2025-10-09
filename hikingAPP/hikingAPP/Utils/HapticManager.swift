//
//  HapticManager.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/10/9.
//

import SwiftUI

struct HapticOnTouchDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
    }
}

extension View {
    func hapticOnTouchDown() -> some View {
        self.modifier(HapticOnTouchDown())
    }
}

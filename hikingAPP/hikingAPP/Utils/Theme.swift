import SwiftUI

struct AppColors {
    // Brand Colors
    static let primary = Color.red
    static let secondary = Color.blue
    static let background = Color.black.opacity(0.9)
    static let surface = Color.white.opacity(0.1)
    
    // UI Elements
    static let text = Color.white
    static let textSecondary = Color.gray
    static let glassStroke = Color.white.opacity(0.3)
    static let glassFill = Color.gray.opacity(0.2)
    
    // Feature Specific
    struct Radar {
        static let pulse = Color.red.opacity(0.3)
        static let scan = Color.blue.opacity(0.07)
        static let center = Color.red
    }
    
    struct Compass {
        static let ticks = Color.white
        static let cardinal = Color.red
        static let ring = Color.white.opacity(0.5)
    }
    
    struct Gradients {
        static let wheel = Gradient(colors: [.blue.opacity(0.4), .red.opacity(0.4)])
        static let glass = Gradient(colors: [
            Color.white.opacity(0.3),
            Color.gray.opacity(0.2),
            Color.white.opacity(0.3)
        ])
    }
}

extension View {
    func standardGlassBackground() -> some View {
        self.background(
            Capsule().stroke(
                AngularGradient(
                    gradient: AppColors.Gradients.glass,
                    center: .center
                ),
                lineWidth: 20
            )
        )
    }
}

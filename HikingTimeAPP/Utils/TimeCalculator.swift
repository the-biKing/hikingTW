import Foundation

struct TimeCalculator {
    static func estimatedTime(shangheMinutes: Double, factor: Double) -> Double {
        return shangheMinutes * factor
    }

    static func standardShangheTime(actualMinutes: Double, factor: Double) -> Double {
        guard factor != 0 else { return actualMinutes }
        return actualMinutes / factor
    }
}


import SwiftUI
import CoreLocation

struct MapView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var compassManager: CompassManager
    
    var body: some View {
        if navModel.planState == .idle {
            AppColors.background
            if !navModel.currentPlan.isEmpty,
               let user = locationManager.coordinate,
               let firstNode = PersistenceManager.shared.loadNodes().first(where: { $0.id == navModel.currentPlan.first }) {
                
                let target = CLLocationCoordinate2D(latitude: firstNode.latitude, longitude: firstNode.longitude)
                let bearingToTarget = NavigationUtils.bearing(from: user, to: target)
                let heading = compassManager.heading?.trueHeading ?? 0
                let relativeAngle = bearingToTarget - heading
                
                DirectionIndicator(angle: relativeAngle)
            } else {
                RouteDisplayView()
            }
        }
    }
}

struct RouteDisplayView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var compassManager: CompassManager
    @State private var lastValidHeading: Double = 0
    
    var body: some View {
        let points = NavigationUtils.extractRoutePoints(from: SegmentDataManager.shared.getAllLoadedSegments(), plan: navModel.currentPlan)
        
        GeometryReader { geo in
            Canvas { context, size in
                guard let center = locationManager.coordinate else { return }
                
                let cgPoints = convertPointsToCG(points: points, canvasSize: size, center: center, zoomScale: 80000)
                
                guard cgPoints.count >= 2 else { return }
                
                var path = Path()
                path.move(to: cgPoints[0])
                for point in cgPoints.dropFirst() {
                    path.addLine(to: point)
                }
                
                context.stroke(path, with: .color(AppColors.secondary), lineWidth: 3)
            }
            .rotationEffect(Angle(degrees: {
                if let heading = compassManager.heading?.trueHeading, heading >= 0 {
                    DispatchQueue.main.async {
                        lastValidHeading = heading
                    }
                    return -heading
                } else {
                    return -lastValidHeading
                }
            }()))
        }
        .frame(width: 300, height: 300)
        .background(AppColors.background)
    }
}

func convertPointsToCG(points: [Point], canvasSize: CGSize, center: CLLocationCoordinate2D, zoomScale: CGFloat) -> [CGPoint] {
    guard !points.isEmpty else { return [] }
    let scale = zoomScale

    return points.map { point in
        let dx = point.longitude - center.longitude
        let dy = point.latitude - center.latitude
        let x = canvasSize.width / 2 + dx * scale
        let y = canvasSize.height / 2 - dy * scale
        return CGPoint(x: x, y: y)
    }
}

struct DirectionIndicator: View {
    var angle: Double
    let radius: CGFloat = 150
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = radius - 10
            let rad = Angle(degrees: angle).radians
            
            let x = center.x + cos(rad - .pi / 2) * r
            let y = center.y + sin(rad - .pi / 2) * r
            
            Triangle()
                .fill(Color.yellow)
                .frame(width: 16, height: 16)
                .rotationEffect(Angle(degrees: angle))
                .position(x: x, y: y)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    MapView()
        .environmentObject(NavigationViewModel())
        .environmentObject(CompassManager())
}

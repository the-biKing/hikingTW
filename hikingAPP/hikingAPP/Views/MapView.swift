import SwiftUI
import CoreLocation

struct MapView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var compassManager: CompassManager
    private func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    var body: some View {
        
        
            if navModel.planState == .active {
                routeView()
            }
            else{
                Color.black.opacity(1)
                if !navModel.currentPlan.isEmpty,
                                  let user = locationManager.coordinate,
                                  let firstNode = loadNodes().first(where: { $0.id == navModel.currentPlan.first }) {
                                   
                                   let target = CLLocationCoordinate2D(latitude: firstNode.latitude, longitude: firstNode.longitude)
                                   let bearingToTarget = bearing(from: user, to: target)
                                   let heading = compassManager.heading?.trueHeading ?? 0
                                   let relativeAngle = bearingToTarget - heading
                                   
                                   DirectionIndicator(angle: relativeAngle)
                               }
            }
            
        
    }
}
struct routeView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var compassManager: CompassManager
    @State private var lastValidHeading: Double = 0
    

    var body: some View {
        let points = extractRoutePoints(from: loadSegments(), plan: navModel.currentPlan)

       
            GeometryReader { geo in
                Canvas { context, size in
                    
                    
                    guard let center = locationManager.coordinate else{
                        return
                    }
                
                    
                    let cgPoints = convertPointsToCG(points: points, canvasSize: size, center: center, zoomScale: 80000)

                    guard cgPoints.count >= 2 else { return }

                    var path = Path()
                    path.move(to: cgPoints[0])
                    for point in cgPoints.dropFirst() {
                        path.addLine(to: point)
                    }

                    context.stroke(path, with: .color(.blue), lineWidth: 3)
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
            .frame(width:300, height: 300)
            .background(Color.black)

    }
}







func convertPointsToCG(points: [Point], canvasSize: CGSize, center: CLLocationCoordinate2D, zoomScale: CGFloat) -> [CGPoint] {
    guard !points.isEmpty else { return [] }

    // Scale in points per degree (this is your "zoom")
    // You can tweak zoomScale (e.g., 10000 is very zoomed in, 100 is zoomed out)
    let scale = zoomScale

    return points.map { point in
        let dx = point.longitude - center.longitude
        let dy = point.latitude - center.latitude

        // X = longitude, Y = inverted latitude (since Y grows down on screen)
        let x = canvasSize.width / 2 + dx * scale
        let y = canvasSize.height / 2 - dy * scale

        return CGPoint(x: x, y: y)
    }
}

struct DirectionIndicator: View {
    var angle: Double // in degrees, relative to top (north)
    let radius: CGFloat = 150 // same as circle radius in MainView (half of 300)
    
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

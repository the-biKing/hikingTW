import SwiftUI
import CoreLocation

struct MapView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    var body: some View {
        
        
            if navModel.planState == .active {
                routeView()
                    .environmentObject(LocationManager())
            }
            else{
                Color.black.opacity(1)
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
                    /*
                    // Center around first point for now (or later: user coordinate)
                    guard let first = points.first else { return }
                    let center = CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
                     */
                    
                    
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




#Preview {
    MapView()
        .environmentObject(NavigationViewModel())
        .environmentObject(CompassManager())
}

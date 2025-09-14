import SwiftUI
import CoreLocation

struct MapView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    var body: some View {
        
        
            if navModel.planState == .active {
                routeView()
            }
            else{
                Color.black.opacity(1)
            }
            
        
    }
}
struct routeView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var compassManager: CompassManager
    @State private var lastValidHeading: Double = 0

    var body: some View {
        let segments = loadSegments()
        let points = extractRoutePoints(from: segments, plan: navModel.currentPlan)

       
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




func node2seg(_ node1: String, _ node2: String) -> String {
    return "\(node1)_\(node2)"
}

func extractRoutePoints(from segments: [Segment], plan: [String]) -> [Point] {
    guard plan.count >= 2 else { return [] }

    let segmentDict = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })

    var routePoints: [Point] = []

    for i in 0..<(plan.count - 1) {
        let nodeA = plan[i]
        let nodeB = plan[i + 1]
        let segId = node2seg(nodeA, nodeB)

        if let segment = segmentDict[segId] {
            // ✅ Just append all points every time
            routePoints.append(contentsOf: segment.points)
        } else {
            print("⚠️ Segment not found for ID: \(segId)")
        }
    }

    return routePoints
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




func loadSegments() -> [Segment] {
    guard let url = Bundle.main.url(forResource: "segments", withExtension: "json") else {
        print("❌ segments.json not found in bundle.")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        let segmentCollection = try JSONDecoder().decode(SegmentCollection.self, from: data)
        return segmentCollection.segments
    } catch {
        print("❌ Failed to decode segments.json: \(error)")
        return []
    }
}



#Preview {
    MapView()
        .environmentObject(NavigationViewModel())
        .environmentObject(CompassManager())
}

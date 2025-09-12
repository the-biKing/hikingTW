import SwiftUI
import CoreLocation
import Combine
import Foundation



struct MainView: View {
    @StateObject private var compass = CompassManager()
    @StateObject private var locationManager = LocationManager()


    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().opacity(0.9)
            
            
            

            VStack {
                Text("ETA : 15 mins").font(.largeTitle).foregroundColor(Color.white)
                    .padding(.bottom, 20)
                    .offset(y:110)
                    .fontWeight(.bold)
                
                let displayHeading = compass.heading?.magneticHeading ?? 0
                
                ZStack {
                    CompassWheel(heading: displayHeading)
                    RadarView(
                        elevation: locationManager.elevation,
                        coordinate: locationManager.coordinate
                    )

                        .offset(y: 150)
                        .frame(width: 200, height:200)
                    WheelScalePreview()
                        .offset(y: 150)
                }
                .frame(width: 600, height: 300)

                Spacer()

                NodeInfoPanel(
                    nextNodeName: "Campground A",
                    prevNodeName: "Trailhead",
                    distance: "1200M",
                    elevation: "230M"
                )

                

            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: {
                print("Add plan tapped")
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40) // fixed tappable size
                    .background(Capsule().stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.gray.opacity(0.2),
                                Color.white.opacity(0.3)
                            ]),
                            center: .center
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 60, height: 16))
                    .shadow(radius: 5)
                    .offset(x:140, y:-20)
            }
            .padding() // ← padding around the whole button
        }
    }

}

import SwiftUI
import CoreLocation

struct CompassWheel: View {
    var heading: CLLocationDirection

    var body: some View {
        GeometryReader { geometry in
            let size = max(geometry.size.width, geometry.size.height)
            let radius = size / 2
            let tickOffset = -radius
            let labelOffset = -radius + 30

            ZStack {
                // Optional: change stroke to make border visible
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 0)

                // Tick marks every 10°
                ForEach(0..<360, id: \.self) { angle in
                    if angle % 10 == 0 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: angle % 90 == 0 ? size * 0.05 : size * 0.025)
                            .offset(y: tickOffset)
                            .rotationEffect(.degrees(Double(angle)))
                    }
                }

                // Cardinal direction labels (N, E, S, W)
                Group {
                    Text("N")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        .offset(y: labelOffset)

                    Text("W")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                       // .rotationEffect(.degrees(90))
                        .offset(y: labelOffset)
                        .rotationEffect(.degrees(-90))

                    Text("S")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                       // .rotationEffect(.degrees(180))
                        .offset(y: labelOffset)
                        .rotationEffect(.degrees(-180))

                    Text("E")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        //.rotationEffect(.degrees(0))
                        .offset(y: labelOffset)
                        .rotationEffect(.degrees(-270))
                }
            }
            .rotationEffect(.degrees(-heading)) // Rotate the wheel to match heading
            .frame(width: size, height: size)
            .clipShape(Rectangle().offset(y: -radius * 1.5)) // Optional: clip to top half
        }
    }
}

struct RadarPulse: View {
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1.0

    var animationDuration: Double = 10.0

    var body: some View {
        ZStack {
            // Radial circle stroke
            
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.3),
                            Color.white.opacity(0.7),
                            Color.black.opacity(0.3)
                        ]),
                        center: .center
                    ),
                    lineWidth: 1
                )
                .frame(width: 340 ,height: 340)
             

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.07),
                            Color.clear
                        ]),
                        center: .bottom,
                        startRadius: 340,
                        endRadius: 200
                    )
                    
                )
                .frame(width: 630, height: 630)
                .saturation(0.2)


            // Red animated pulse
            Circle()
                .fill(Color.red.opacity(0.3))
                .scaleEffect(scale)
                .opacity(opacity)
                .frame(width: 200, height: 200)
                .onAppear {
                    withAnimation(
                        Animation.easeOut(duration: animationDuration)
                            .repeatForever(autoreverses: false)
                    ) {
                        scale = 1.5
                        opacity = 0
                    }
                }
        }
    }
}


struct RadarView: View {
    var elevation: Double? = nil
    var coordinate: CLLocationCoordinate2D? = nil
    
    var body: some View {
        ZStack {
            MapView()
                .clipShape(Circle())
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.gray.opacity(0.2),
                                        Color.white.opacity(0.3)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 20
                            )
                            .frame(width: 320, height: 320)
                        
                        // Top text (elevation)
                        CurvedText(text: elevation != nil ? "\(Int(elevation!)) M" : "1000M", radius: 160, centerAngle: 0)
                            .font(.caption)
                            //.fontWeight(.black)

                        CurvedText(
                            text: coordinate != nil
                                ? formattedCoordinates(from: coordinate!)
                            : "W0000.0 • N0000.0",
                            radius: 160,
                            centerAngle: 180
                        )

                        .font(.caption)
                        .foregroundColor(.white)
                        .font(.caption)
                    }
                )
                .frame(width: 300, height: 300)
            
            RadarPulse()
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
        }
    }
}

struct CurvedText: View {
    var text: String
    var radius: CGFloat
    var centerAngle: Double = 0 // 0 = top, 180 = bottom
    var font: Font = .caption
    var color: Color = .white

    var body: some View {
        let chars: [Character] = Array(centerAngle == 180 ? String(text.reversed()) : text)
        let count = chars.count
        // angle per character (deg) — tweak as needed
        let anglePerChar = 5.0
        let totalArc = min(Double(count) * anglePerChar, 120.0)
        let step = count > 1 ? totalArc / Double(count - 1) : 0.0
        let startAngle = centerAngle - totalArc / 2.0
        
        

        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = startAngle + step * Double(i)
                   let rad = angle * .pi / 180.0
                   let x = CGFloat(radius * sin(rad))
                   let y = CGFloat(-radius * cos(rad))

                   let displayRotation: Double = {
                       if angle > 90 && angle < 270 {
                           return angle - 180
                       } else {
                           return angle
                       }
                   }()
               

                Text(String(chars[i]))
                    .bold()
                    .font(font)
                    .foregroundColor(color)
                    .rotationEffect(.degrees(displayRotation))
                    .offset(x: x, y: y)
            }
        }
    }
}


struct NodeInfoPanel: View {
    var nextNodeName: String
    var prevNodeName: String
    var distance: String
    var elevation: String

    var body: some View {
        VStack(spacing: 8) {
            // Next Node capsule
            Text(nextNodeName)
                .font(.caption)
                .padding(.horizontal, 30)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
                .foregroundColor(.white)

            HStack(alignment: .center, spacing: 16) {
                // Arrow
                Image(systemName: "chevron.up")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .offset(x:5)

                // Distance & Elevation
                VStack(alignment: .leading, spacing: 4) {
                    Text("DIST: \(distance)")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("ELEV: \(elevation)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }

            // Previous Node capsule
            Text(prevNodeName)
                .font(.caption)
                .padding(.horizontal, 30)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
                .foregroundColor(.white)
        }
        .padding(.bottom, 20)
        .scaleEffect(1.5)
    }
}

struct WheelScalePreview: View {
    let minValue: Double = 0.13
    let maxValue: Double = 2.0

    /// Controls the current value on the wheel
    var speedFactor: Double = 1

    var body: some View {
        
        VStack {
            ZStack {
                
                // Gradient wheel
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.4), .red.opacity(0.4)]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90)) // Start gradient from top
                    .frame(width: 355, height: 355)
                    .rotationEffect(.degrees(rotation))

                // Pointer and value label
                VStack(spacing: 2) {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180)) // point downward
                        .foregroundColor(.red)

                    Text(String(format: "%.2f", speedFactor))
                        .foregroundColor(Color.white)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .offset(y: -185)
            }
        }
    }

    /// Converts the speedFactor to rotation angle (0–360)
    private var rotation: Double {
        let clamped = max(min(speedFactor, maxValue), minValue)
        let normalized = (clamped - minValue) / (maxValue - minValue)
        return normalized * 360
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var manager = CLLocationManager()

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var elevation: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        coordinate = latest.coordinate
        elevation = latest.altitude
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}

func formattedCoordinates(from coord: CLLocationCoordinate2D) -> String {
    let lat = abs(coord.latitude)
    let lon = abs(coord.longitude)

    let latDir = coord.latitude >= 0 ? "N" : "S"
    let lonDir = coord.longitude >= 0 ? "E" : "W"

    let latStr = String(format: "%.4f", lat)
    let lonStr = String(format: "%.4f", lon)

    // Flip order: W123.1234, N321.3214
    return "\(latDir)\(latStr) • \(lonDir)\(lonStr)"
}



#Preview {
    MainView()
        .environmentObject(NavigationViewModel())
}

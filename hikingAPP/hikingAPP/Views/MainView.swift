import SwiftUI
import CoreLocation
import Combine
import Foundation



struct MainView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var compass: CompassManager
    let user = loadUser()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea().opacity(0.9)

            VStack {
                ETAView()
                let displayHeading = compass.heading?.magneticHeading ?? 0

                ZStack {
                    CompassWheel(heading: displayHeading)
                    RadarView()
                        .offset(y: 150)
                        .frame(width: 200, height: 200)
                    WheelScalePreview(speedFactor: user?.speedFactor ?? 1.00)
                        .offset(y: 150)
                }
                .frame(width: 600, height: 300)

                Spacer()

                NodeInfoPanel()
            }
            // ✅ Place NavigationLink here — top-left overlay position
            NavigationLink(destination: PlanView()) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Capsule().stroke(
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
                        .frame(width: 60, height: 16)
                    )
                    .shadow(radius: 5)
            }
            .offset(x:140)
            .simultaneousGesture(TapGesture().onEnded {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

            })
        }
    }
}


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
    @EnvironmentObject private var locationManager: LocationManager
    
    private var elevationText: String {
        let elevation = locationManager.elevation ?? 1000
        return "\(Int(elevation)) M"
    }
    
    private var coordinateText: String {
        guard let coord = locationManager.coordinate else {
            return "W0000.0 • N0000.0"
        }
        return formattedCoordinates(from: coord)
    }

    var body: some View {
        ZStack {
            MapView()
                .frame(width: 380, height: 300) // match outer circle
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
                        
                        CurvedText(text: elevationText, radius: 160, centerAngle: 0)
                            .font(.caption)
                            .foregroundColor(.white)

                        CurvedText(text: coordinateText, radius: 160, centerAngle: 180)
                            .font(.caption)
                            .foregroundColor(.white)
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



struct WheelScalePreview: View {
    let minValue: Double = 0.13
    let maxValue: Double = 2.0

    /// Controls the current value on the wheel
    var speedFactor: Double

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
    NavigationStack {
        MainView()
            .environmentObject(LocationManager())
            .environmentObject(NavigationViewModel())
            .environmentObject(CompassManager())
    }
}

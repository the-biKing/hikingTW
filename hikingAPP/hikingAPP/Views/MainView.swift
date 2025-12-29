import SwiftUI
import CoreLocation
import Combine
import Foundation


extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}



struct MainView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var compass: CompassManager
    @EnvironmentObject var navModel: NavigationViewModel
    @State private var navigateToPlan = false
    @State private var hasTriggeredHaptic = false
    let user = PersistenceManager.shared.loadUser()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()
            
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

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                navigateToPlan = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(AppColors.text)
                    .frame(width: 40, height: 40)
                    .background(
                        Capsule()
                            .stroke(
                                AngularGradient(
                                    gradient: AppColors.Gradients.glass,
                                    center: .center
                                ),
                                lineWidth: 20
                            )
                            .frame(width: 60, height: 16)
                    )
                    .shadow(radius: 5)
            }
            .offset(x: 140)
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                // TODO: navigate to settings
            }) {
                Image(systemName: "gearshape")
                    .font(.title)
                    .foregroundColor(AppColors.text)
                    .frame(width: 40, height: 40)
                    .background(
                        Capsule()
                            .stroke(
                                AngularGradient(
                                    gradient: AppColors.Gradients.glass,
                                    center: .center
                                ),
                                lineWidth: 20
                            )
                            .frame(width: 60, height: 16)
                    )
                    .shadow(radius: 5)
            }
            .offset(x: 420)
            
        }
        .navigationDestination(isPresented: $navigateToPlan) {
            PlanView().environmentObject(navModel)
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
                Circle()
                    .stroke(AppColors.Compass.ring, lineWidth: 0)
                
                // Tick marks every 10°
                ForEach(0..<360, id: \.self) { angle in
                    if angle % 10 == 0 {
                        Rectangle()
                            .fill(AppColors.Compass.ticks)
                            .frame(width: 2, height: angle % 90 == 0 ? size * 0.05 : size * 0.025)
                            .offset(y: tickOffset)
                            .rotationEffect(.degrees(Double(angle)))
                    }
                }
                
                // Cardinal direction labels (N, E, S, W)
                Group {
                    Text("N")
                        .foregroundColor(AppColors.Compass.cardinal)
                        .fontWeight(.bold)
                        .offset(y: labelOffset)
                    
                    Text("W")
                        .foregroundColor(AppColors.Compass.cardinal)
                        .fontWeight(.bold)
                        .offset(y: labelOffset)
                        .rotationEffect(.degrees(-90))
                    
                    Text("S")
                        .foregroundColor(AppColors.Compass.cardinal)
                        .fontWeight(.bold)
                        .offset(y: labelOffset)
                        .rotationEffect(.degrees(-180))
                    
                    Text("E")
                        .foregroundColor(AppColors.Compass.cardinal)
                        .fontWeight(.bold)
                        .offset(y: labelOffset)
                        .rotationEffect(.degrees(-270))
                }
            }
            .rotationEffect(.degrees(-heading))
            .frame(width: size, height: size)
            .clipShape(Rectangle().offset(y: -radius * 1.5))
        }
    }
}

struct RadarPulse: View {
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1.0
    
    var animationDuration: Double = 10.0
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: AppColors.Gradients.glass,
                        center: .center
                    ),
                    lineWidth: 1
                )
                .frame(width: 340 ,height: 340)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            AppColors.Radar.scan,
                            Color.clear
                        ]),
                        center: .bottom,
                        startRadius: 340,
                        endRadius: 200
                    )
                )
                .frame(width: 630, height: 630)
                .saturation(0.2)
            
            Circle()
                .fill(AppColors.Radar.pulse)
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
                .frame(width: 380, height: 300)
                .clipShape(Circle())
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: AppColors.Gradients.glass,
                                    center: .center
                                ),
                                lineWidth: 20
                            )
                            .frame(width: 320, height: 320)
                        
                        CurvedText(text: elevationText, radius: 160, centerAngle: 0)
                            .font(.caption)
                            .foregroundColor(AppColors.text)
                        
                        CurvedText(text: coordinateText, radius: 160, centerAngle: 180)
                            .font(.caption)
                            .foregroundColor(AppColors.text)
                    }
                )
                .frame(width: 300, height: 300)
            
            RadarPulse()
            
            Circle()
                .fill(AppColors.Radar.center)
                .frame(width: 12, height: 12)
        }
    }
}

struct CurvedText: View {
    var text: String
    var radius: CGFloat
    var centerAngle: Double = 0
    var font: Font = .caption
    var color: Color = AppColors.text
    
    var body: some View {
        let chars: [Character] = Array(centerAngle == 180 ? String(text.reversed()) : text)
        let count = chars.count
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
    var speedFactor: Double
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        AngularGradient(
                            gradient: AppColors.Gradients.wheel,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 355, height: 355)
                    .rotationEffect(.degrees(rotation))
                
                VStack(spacing: 2) {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(180))
                        .foregroundColor(AppColors.primary)
                    
                    Text(String(format: "%.2f", speedFactor))
                        .foregroundColor(AppColors.text)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .offset(y: -185)
            }
        }
    }
    
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

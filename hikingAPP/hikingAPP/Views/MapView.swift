import SwiftUI

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
    var body: some View {
        Text("map")
    }
}

#Preview {
    MapView()
        .environmentObject(NavigationViewModel())
}

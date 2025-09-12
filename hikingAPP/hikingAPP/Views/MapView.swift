import SwiftUI

struct MapView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    var body: some View {
        
            if navModel.planState == .active {
                //show map
            }
            else{
                Color.black.opacity(1)
            }
        
    }
}

#Preview {
    MapView()
        .environmentObject(NavigationViewModel())
}

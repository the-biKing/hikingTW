import SwiftUI

struct MountainButton: View {
    let imageName: String
    let title: String
    let leftMark: Bool
    let areaCodes: [String]
    
    @EnvironmentObject var navModel: NavigationViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let buttonWidth = geometry.size.width * 0.9
            NavigationLink(destination:
                            DetailView(areaCodes: areaCodes, areaName: title).environmentObject(navModel)
            ) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.background)
                        .frame(width: buttonWidth, height: 300)
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: buttonWidth, height: 300)
                        .clipped()
                        .cornerRadius(16)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [AppColors.text.opacity(0.4), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: buttonWidth, height: 300)
                    HStack {
                        if leftMark { Spacer() }
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.text)
                            .padding(.top, 50)
                            .shadow(radius: 3)
                        if !leftMark { Spacer() }
                    }
                    .padding(.horizontal, 24)
                    .frame(width: buttonWidth)
                }
                .frame(width: buttonWidth, height: 300)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .simultaneousGesture(TapGesture().onEnded {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            })
        }
        .frame(height: 320)
    }
}

struct PlanningView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @ObservedObject var vm: GraphViewModel
    @Binding var showHistory: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        vm.history.append(vm.path)
                        navModel.loadPlan(from: vm)
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppColors.secondary)
                            .padding()
                    }
                    Spacer()
                }
                
                Text("預估時間：" +
                     (vm.estimatedTime < 60
                      ? "\(String(format: "%.1f", vm.estimatedTime)) 分鐘"
                      : "\(Int(vm.estimatedTime) / 60) 小時 \(Int(vm.estimatedTime) % 60) 分鐘"))
                .font(.headline)
                .foregroundColor(.yellow)
                .padding(.top, 8)
                
                if let current = vm.current {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(current.name)
                                .font(.largeTitle)
                        }
                        .frame(width: 150, alignment: .leading)
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.primary)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        
                        VStack {
                            ForEach(current.nearBy, id: \.self) { nextId in
                                if let nextNode = vm.nodes.first(where: { $0.id == nextId }) {
                                    Button {
                                        vm.move(to: nextId)
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    } label: {
                                        Text(nextNode.name)
                                            .frame(width: 140, height: 44)
                                            .background(AppColors.secondary.opacity(0.6))
                                            .foregroundColor(AppColors.text)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .frame(width: 150)
                    }
                    .padding()
                    .transition(.move(edge: .leading))
                }
                
                Divider()
                    .background(AppColors.text.opacity(0.3))
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(vm.path, id: \.self) { id in
                            if let node = vm.nodes.first(where: { $0.id == id }) {
                                Text(node.name)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.text.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                
                HStack {
                    Button {
                        vm.goBack()
                    } label: {
                        Image(systemName: "chevron.backward.2")
                            .padding(.horizontal, 60)
                            .foregroundColor(AppColors.text)
                    }
                    
                    Button {
                        vm.reset()
                        navModel.loadPlan(from: vm)
                    } label: {
                        Image(systemName: "tent")
                            .padding(.horizontal, 60)
                            .foregroundColor(AppColors.text)
                    }
                }
                
                Button {
                    withAnimation {
                        showHistory = true
                    }
                } label: {
                    Text("已規劃路線")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .foregroundColor(AppColors.text)
        }
    }
}

struct HistoryView: View {
    @ObservedObject var vm: GraphViewModel
    @Binding var showHistory: Bool
    
    var body: some View {
        VStack {
            Text("已規劃路線")
                .font(.title2)
                .padding()
                .foregroundColor(AppColors.text)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(vm.history.enumerated()), id: \.offset) { index, route in
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(route, id: \.self) { id in
                                    if let node = vm.nodes.first(where: { $0.id == id }) {
                                        Text(node.name)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppColors.text.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 50)
                        .background(AppColors.text.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Text("第 \(index + 1) 天")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Spacer()
                                Button {
                                    withAnimation {
                                        vm.deleteHistory(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                                .padding(6),
                            alignment: .topLeading
                        )
                    }
                    if !vm.path.isEmpty {
                        VStack(alignment: .leading) {
                            Text("正在規劃的路線")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(vm.path, id: \.self) { id in
                                        if let node = vm.nodes.first(where: { $0.id == id }) {
                                            Text(node.name)
                                                .padding(6)
                                                .background(AppColors.text.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 50)
                            .background(AppColors.text.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            
            Button {
                withAnimation {
                    showHistory = false
                }
            } label: {
                Text("返回安排頁面")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.secondary.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(AppColors.text)
            }
            .padding(.horizontal)
        }
    }
}

import SwiftUI

struct PlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navModel: NavigationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Spacer()
                Spacer()
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(AppColors.secondary)
                            .padding(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button(action: {
                        print("history")
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(AppColors.textSecondary)
                                .frame(width: 200)
                                .padding(.trailing)
                                .padding(.trailing)
                            Text("history")
                                .font(.title2)
                                .padding(.trailing)
                                .foregroundColor(AppColors.text)
                                .shadow(radius: 3)
                        }
                    }
                }
                
                Group {
                    MountainButton(imageName: "d_Yushan", title: "測試", leftMark: false, areaCodes: ["NT"])
                    MountainButton(imageName: "d_Yushan", title: "玉山群峰", leftMark: false, areaCodes: ["WM", "PF"])
                    MountainButton(imageName: "d_DaBa", title: "大霸群峰", leftMark: false, areaCodes: ["DB"])
                    MountainButton(imageName: "d_Xueshan", title: "雪山群峰", leftMark: false, areaCodes: ["XS"])
                    MountainButton(imageName: "d_Nanhu", title: "南湖中央尖", leftMark: false, areaCodes: ["NF"])
                    MountainButton(imageName: "d_Wuming", title: "北二段", leftMark: false, areaCodes: ["NS"])
                    MountainButton(imageName: "d_4spicy", title: "中橫四辣", leftMark: false, areaCodes: ["WM", "PF", "BG"])
                    MountainButton(imageName: "d_Hehuan", title: "合歡群峰", leftMark: false, areaCodes: ["HH"])
                    MountainButton(imageName: "d_ChER", title: "奇萊東稜", leftMark: false, areaCodes: ["ER"])
                    MountainButton(imageName: "d_Tianchi", title: "能高越嶺", leftMark: false, areaCodes: ["UL"])
                    MountainButton(imageName: "d_NG", title: "能高安東軍", leftMark: false, areaCodes: ["NG"])
                    MountainButton(imageName: "d_Mabo", title: "馬博橫斷", leftMark: false, areaCodes: ["1"])
                    MountainButton(imageName: "d_Gandrowan", title: "干卓萬橫斷", leftMark: false, areaCodes: ["GC"])
                    MountainButton(imageName: "d_Xiluan", title: "西巒郡大", leftMark: false, areaCodes: ["JD", "WL"])
                    MountainButton(imageName: "d_S3", title: "南三段", leftMark: false, areaCodes: ["1"])
                    MountainButton(imageName: "d_S2", title: "南二段", leftMark: false, areaCodes: ["1"])
                    MountainButton(imageName: "d_S1", title: "南一段", leftMark: false, areaCodes: ["SF"])
                    MountainButton(imageName: "d_Jiaming", title: "嘉明新康", leftMark: false, areaCodes: ["1"])
                    MountainButton(imageName: "d_6shun", title: "六順山", leftMark: false, areaCodes: ["1"])
                    MountainButton(imageName: "d_Taimu", title: "北大武山", leftMark: false, areaCodes: ["NB"])
                }
            }
            .padding(.top)
        }
        .background(AppColors.background)
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct DetailView: View {
    let areaCode: String
    let areaName: String
    @StateObject private var vm: GraphViewModel
    @EnvironmentObject var navModel: NavigationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedStart: Node? = nil
    @State private var showHistory = false
    
    init(areaCodes: [String], areaName: String) {
        _vm = StateObject(wrappedValue: GraphViewModel(areaCodes: areaCodes))
        self.areaCode = areaCodes.joined(separator: ", ")
        self.areaName = areaName
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background.ignoresSafeArea()
            VStack {
                if selectedStart == nil {
                    Text("請選擇 \(areaName) 的起始點")
                        .font(.title2)
                        .padding(.top, 40)
                        .foregroundColor(AppColors.text)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vm.startNodes) { node in
                                Button {
                                    vm.setStart(node)
                                    selectedStart = node
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                } label: {
                                    Text(node.name)
                                        .font(.title3)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.secondary.opacity(0.7))
                                        .foregroundColor(AppColors.text)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Label("返回", systemImage: "arrow.uturn.backward.circle")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.textSecondary.opacity(0.7))
                            .foregroundColor(AppColors.text)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else {
                    VStack {
                        if showHistory {
                            HistoryView(vm: vm, showHistory: $showHistory)
                        } else {
                            PlanningView(vm: vm, showHistory: $showHistory)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        PlanView()
            .environmentObject(NavigationViewModel())
    }
}



#Preview {
    NavigationStack{
        PlanView()
            .environmentObject(NavigationViewModel())
    }
}

import SwiftUI

func MountainButton(imageName: String, title: String, code: String, leftMark: Bool,
                    destination: AnyView? = nil) -> some View {
    GeometryReader { geometry in
        let buttonWidth = geometry.size.width * 0.9
        NavigationLink(destination: destination ?? AnyView(Text("這是 \(title) 的頁面"))) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
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
                            gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
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
                        .foregroundColor(.white)
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

struct PlanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navModel: NavigationViewModel
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Spacer()
                Spacer()
                HStack(){
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                            .padding(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button(action:{
                        print("history")
                    }){
                        ZStack(){
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.gray)
                                .frame(width:200)
                                .padding(.trailing)
                                .padding(.trailing)
                            Text("history")
                                .font(.title2)
                                .padding(.trailing)
                                .foregroundColor(.white)
                            .shadow(radius: 3)                        }
                        
                    }
                }
                
                MountainButton(
                    imageName: "d_Yushan",
                    title: "玉山群峰",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_DaBa",
                    title: "大霸群峰",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Xueshan",
                    title: "雪山群峰",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Nanhu",
                    title: "南湖中央尖",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Wuming",
                    title: "北二段",
                    code:"NS",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"NS").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_4spicy",
                    title: "中橫四辣",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Hehuan",
                    title: "合歡群峰",
                    code:"HH",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"HH").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_ChER",
                    title: "奇萊東稜",
                    code:"ER",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"ER").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Tianchi",
                    title: "能高越嶺",
                    code:"UL",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"UL").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_NG",
                    title: "能高安東軍",
                    code:"NG",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"NG").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Mabo",
                    title: "馬博橫斷",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Gandrowan",
                    title: "干卓萬橫斷",
                    code:"GC",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"GC").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Xiluan",
                    title: "西巒郡大",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_S3",
                    title: "南三段",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_S2",
                    title: "南二段",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_S1",
                    title: "南一段",
                    code:"ST",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"ST").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Jiaming",
                    title: "嘉明新康",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_6shun",
                    title: "六順山",
                    code:"1",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"1").environmentObject(navModel))
                )
                MountainButton(
                    imageName: "d_Taimu",
                    title: "北大武山",
                    code:"NB",
                    leftMark: false,
                    destination: AnyView(DetailView(areaCode:"NB").environmentObject(navModel))
                )
                
            }
            .padding(.top)
        }
        .background(Color(.black).opacity(0.9)) // 整個背景深灰
        .ignoresSafeArea()            // 延伸到螢幕邊緣
        .navigationBarHidden(true)
        
    }
    
}


class GraphViewModel: ObservableObject {
    @Published var nodes: [Node] = []
    @Published var current: Node?
    @Published var path: [String] = []
    @Published var history: [[String]] = []
    
    private var lookup: [String: Node] = [:]
    private var start: Node?
    
    init(areaCode: String) {
        let allNodes = loadNodes()
        // 篩出該山區的節點
        self.nodes = allNodes.filter { $0.id.contains(areaCode) }
        self.lookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
    }
    
    func setStart(_ node: Node) {
        self.start = node
        self.current = node
        self.path = [node.id]
    }
    
    
    func move(to nextId: String) {
        if let nextNode = lookup[nextId] {
            withAnimation(.easeInOut) {
                self.current = nextNode
                self.path.append(nextNode.id)
            }
        }
    }
    
    // 🔙 返回一步
    func goBack() {
        guard path.count > 1 else { return }
        path.removeLast()
        if let lastId = path.last,
           let lastNode = lookup[lastId] {
            withAnimation(.easeInOut) {
                self.current = lastNode
            }
        }
    }
    
    // 🏕️ 歸零
    func reset() {
        guard let now = current else { return }
        if !path.isEmpty {
            history.append(path)  // now path stores IDs
        }
        
        withAnimation(.easeInOut) {
            self.start = now
            self.path = [now.id]
            self.current = now
        }
    }
    func deleteHistory(at index: Int) {
        guard history.indices.contains(index) else { return }
        history.remove(at: index)
        
        if let lastRoute = history.last,
           let lastId = lastRoute.last,
           let lastNode = lookup[lastId] {
            self.current = lastNode
            self.start = lastNode
            self.path = [lastNode.id]
        } else if let first = nodes.first {
            self.current = first
            self.start = first
            self.path = [first.id]
        }
    }
}

struct DetailView: View {
    let areaCode: String
    @StateObject private var vm: GraphViewModel
    @EnvironmentObject var navModel: NavigationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedStart: Node? = nil
    @State private var showHistory = false
    
    init(areaCode: String) {
        _vm = StateObject(wrappedValue: GraphViewModel(areaCode: areaCode))
        self.areaCode = areaCode
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                if selectedStart == nil {
                    // ===============================
                    // 起始點選擇畫面
                    // ===============================
                    Text("請選擇 \(areaCode) 的起始點")
                        .font(.title2)
                        .padding(.top, 40)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vm.nodes.filter { $0.id.hasPrefix("s_") }) { node in
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
                                        .background(Color.blue.opacity(0.7))
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
                            .background(Color.gray.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // ===============================
                // 已選擇起始點 → 顯示路線規劃畫面
                // ===============================
                else {
                    VStack {
                        if showHistory {
                            HistoryView(vm: vm, showHistory: $showHistory)
                        } else {
                            PlanningView(vm: vm, showHistory: $showHistory)
                        }
                    }
                }
            }
            .foregroundColor(.white)
            .background(Color.black.ignoresSafeArea())
        }
        .navigationBarHidden(true)
    }
}

struct PlanningView: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @ObservedObject var vm: GraphViewModel
    @Binding var showHistory: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()  // 背景延伸
            
            VStack {
                // 返回鍵
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                            .padding()
                    }
                    Spacer()
                }
                
                if let current = vm.current {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(current.name)
                                .font(.largeTitle)
                        }
                        .frame(width: 150, alignment: .leading)
                        
                        Spacer()
                        
                        VStack {
                            ForEach(current.nearBy, id: \.self) { nextId in
                                if let nextNode = vm.nodes.first(where: { $0.id == nextId }) {
                                    Button(nextNode.name) {
                                        vm.move(to: nextId)
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    }
                                    .frame(width: 140, height: 44)
                                    .background(Color.blue.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .frame(width: 150)
                    }
                    .padding()
                    .transition(.move(edge: .leading))
                }
                
                Divider()
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(vm.path, id: \.self) { id in
                            if let node = vm.nodes.first(where: { $0.id == id }) {
                                Text(node.name)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
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
                    }
                    
                    Button {
                        vm.reset()
                        navModel.loadPlan(from: vm)
                    } label: {
                        Image(systemName: "tent")
                            .padding(.horizontal, 60)
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
            .foregroundColor(.white)
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
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            HStack {
                                Text("路線 \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Spacer()
                                Button {
                                    withAnimation {
                                        vm.deleteHistory(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                                .padding(6),
                            alignment: .topLeading
                        )
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
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}



#Preview {
    NavigationStack{
        PlanView()
            .environmentObject(NavigationViewModel())
    }
}

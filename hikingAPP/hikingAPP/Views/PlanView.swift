import SwiftUI
/*
 func MountainButton(imageName: String, title: String, leftMark: Bool, areaCodes: [String]) -> some View {
 @EnvironmentObject var navModel: NavigationViewModel
 return GeometryReader { geometry in
 let buttonWidth = geometry.size.width * 0.9
 NavigationLink(destination: DetailView(areaCodes: areaCodes, areaName: title).environmentObject(navModel)) {
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
 */

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
                    title: "測試",
                    leftMark: false,
                    areaCodes: ["NT"]
                )
                MountainButton(
                    imageName: "d_Yushan",
                    title: "玉山群峰",
                    leftMark: false,
                    areaCodes: ["WM", "PF"]
                )
                MountainButton(
                    imageName: "d_DaBa",
                    title: "大霸群峰",
                    leftMark: false,
                    areaCodes: ["DB"]
                )
                MountainButton(
                    imageName: "d_Xueshan",
                    title: "雪山群峰",
                    leftMark: false,
                    areaCodes: ["XS"]
                )
                MountainButton(
                    imageName: "d_Nanhu",
                    title: "南湖中央尖",
                    leftMark: false,
                    areaCodes: ["NF"]
                )
                MountainButton(
                    imageName: "d_Wuming",
                    title: "北二段",
                    leftMark: false,
                    areaCodes: ["NS"]
                )
                MountainButton(
                    imageName: "d_4spicy",
                    title: "中橫四辣",
                    leftMark: false,
                    areaCodes: ["WM", "PF", "BG"]
                )
                MountainButton(
                    imageName: "d_Hehuan",
                    title: "合歡群峰",
                    leftMark: false,
                    areaCodes: ["HH"]
                )
                MountainButton(
                    imageName: "d_ChER",
                    title: "奇萊東稜",
                    leftMark: false,
                    areaCodes: ["ER"]
                )
                MountainButton(
                    imageName: "d_Tianchi",
                    title: "能高越嶺",
                    leftMark: false,
                    areaCodes: ["UL"]
                )
                MountainButton(
                    imageName: "d_NG",
                    title: "能高安東軍",
                    leftMark: false,
                    areaCodes: ["NG"]
                )
                MountainButton(
                    imageName: "d_Mabo",
                    title: "馬博橫斷",
                    leftMark: false,
                    areaCodes: ["1"]
                )
                MountainButton(
                    imageName: "d_Gandrowan",
                    title: "干卓萬橫斷",
                    leftMark: false,
                    areaCodes: ["GC"]
                )
                MountainButton(
                    imageName: "d_Xiluan",
                    title: "西巒郡大",
                    leftMark: false,
                    areaCodes: ["JD", "WL"]
                )
                MountainButton(
                    imageName: "d_S3",
                    title: "南三段",
                    leftMark: false,
                    areaCodes: ["1"]
                )
                MountainButton(
                    imageName: "d_S2",
                    title: "南二段",
                    leftMark: false,
                    areaCodes: ["1"]
                )
                MountainButton(
                    imageName: "d_S1",
                    title: "南一段",
                    leftMark: false,
                    areaCodes: ["SF"]
                )
                MountainButton(
                    imageName: "d_Jiaming",
                    title: "嘉明新康",
                    leftMark: false,
                    areaCodes: ["1"]
                )
                MountainButton(
                    imageName: "d_6shun",
                    title: "六順山",
                    leftMark: false,
                    areaCodes: ["1"]
                )
                MountainButton(
                    imageName: "d_Taimu",
                    title: "北大武山",
                    leftMark: false,
                    areaCodes: ["NB"]
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
    @Published var segments: [Segment] = []
    @Published var estimatedTime: Double = 0.0
    @Published var startNodes: [Node] = []
    @Published var current: Node?
    @Published var path: [String] = []
    @Published var history: [[String]] = [] {
        didSet { saveHistory() }
    }
    
    private var lookup: [String: Node] = [:]
    private var areaCodes: [String]  // ← 支援多代碼
    private var start: Node?
    
    init(areaCodes: [String]) {
        self.areaCodes = areaCodes.map { $0.uppercased() }  // 統一大寫
        let allNodes = loadNodes()
        self.nodes = allNodes
        self.segments = loadSegments()
        self.lookup = Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })
        
        // ✅ 起始點條件：以 S_ 開頭 + 包含任一區域代碼
        self.startNodes = allNodes.filter { node in
            let id = node.id.uppercased()
            guard id.hasPrefix("S_") else { return false }
            // 任何一個代碼符合即可
            return areaCodes.contains { code in
                id.contains("_\(code)_") || id.hasSuffix("_\(code)")
            }
        }
    }
    
    func setStart(_ node: Node) {
        self.start = node
        self.current = node
        self.path = [node.id]
    }
    
    func move(to nextId: String) {
        if let nextNode = lookup[nextId], let current = current {
            withAnimation(.easeInOut) {
                self.current = nextNode
                self.path.append(nextNode.id)
                self.estimatedTime += timeBetween(current.id, nextNode.id)
            }
        }
    }
    
    func goBack() {
        guard path.count > 1 else { return }
        let removedId = path.removeLast()
        if let lastId = path.last,
           let lastNode = lookup[lastId] {
            withAnimation(.easeInOut) {
                self.current = lastNode
                let timeToSubtract = timeBetween(lastId, removedId)
                self.estimatedTime = max(0, self.estimatedTime - timeToSubtract)
            }
        }
    }
    
    func reset() {
        guard let now = current else { return }
        if !path.isEmpty {
            history.append(path)
        }
        withAnimation(.easeInOut) {
            self.start = now
            self.path = [now.id]
            self.current = now
            self.estimatedTime = 0.0
        }
    }
    
    func timeBetween(_ from: String, _ to: String) -> Double {
        var time: Double = 0.0
        if let seg = segments.first(where: { $0.id == "\(from)_\(to)" }) {
            time = seg.standardTime
        } else if let seg = segments.first(where: { $0.id == "\(to)_\(from)" }) {
            time = seg.revStandardTime
        } else {
            print("⚠️ No segment found for \(from) ↔ \(to)")
            return 0.0
        }
        
        if let user = loadUser() {
            return time * user.speedFactor
        } else {
            return time
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
        } else if let first = startNodes.first {
            self.current = first
            self.start = first
            self.path = [first.id]
        }
    }
    func saveHistory() {
        UserDefaults.standard.set(history, forKey: "PlanHistory")
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
            VStack {
                if selectedStart == nil {
                    // ===============================
                    // 起始點選擇畫面
                    // ===============================
                    Text("請選擇 \(areaName) 的起始點")
                        .font(.title2)
                        .padding(.top, 40)
                    
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
                        vm.history.append(vm.path)
                        navModel.loadPlan(from: vm)
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
                            .foregroundColor(.red)
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
                                        Text(nextNode.name) // 使用 Text 作為 Label
                                            .frame(width: 140, height: 44) // 大小設定在 Text 上
                                            .background(Color.blue.opacity(0.6)) // 背景設定在 Text 上
                                            .foregroundColor(.white)
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
                        .padding(.horizontal, 50)
                        .background(Color.white.opacity(0.05))
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
                                        .foregroundColor(.red)
                                }
                            }
                                .padding(6),
                            alignment: .topLeading
                        )
                    }
                    if !vm.path.isEmpty {      //add 規劃中路線
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
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 50)
                            .background(Color.white.opacity(0.05))
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

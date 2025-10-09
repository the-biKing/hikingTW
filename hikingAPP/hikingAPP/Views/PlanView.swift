import SwiftUI

struct DetailView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text("這是 \(title) 的頁面")
                .font(.largeTitle)
                .padding()
            
            Spacer()
        }
        .navigationTitle(title) // 顯示在 NavigationBar 上
        .navigationBarTitleDisplayMode(.inline)
    }
}



// 建立一個可重用的 View
// MountainButton 改成用 NavigationLink
func MountainButton(imageName: String, title: String, leftMark: Bool) -> some View {
    GeometryReader { geometry in
        let buttonWidth = geometry.size.width * 0.9 // 90% of screen width

        NavigationLink(destination: DetailView(title: title)) {
            
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .frame(width: buttonWidth, height: 300)

                // Image
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: buttonWidth, height: 300)
                    .clipped()
                    .cornerRadius(16)

                // Highlight gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: buttonWidth, height: 300)

                // Text with alignment
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
    .frame(height: 320) // Keep enough space for GeometryReader
}




struct PlanView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
            ScrollView {
                VStack(spacing: 15) {
                    Spacer()
                    Spacer()
                    HStack(){
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
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
                    
                    MountainButton(imageName: "d_Yushan", title: "玉山群峰", leftMark: false)
                    MountainButton(imageName: "d_Xueshan", title: "雪山群峰", leftMark: false)
                    MountainButton(imageName: "d_DaBa", title: "大霸群峰", leftMark: true)
                    MountainButton(imageName: "d_Nanhu", title: "南湖中央尖", leftMark: false)
                    MountainButton(imageName: "d_Wuming", title: "北二段", leftMark: true)
                    MountainButton(imageName: "d_4spicy", title: "中橫四辣", leftMark: false)
                    MountainButton(imageName: "d_Hehuan", title: "合歡群峰", leftMark: true)
                    MountainButton(imageName: "d_ChER", title: "奇萊東稜", leftMark: false)
                    MountainButton(imageName: "d_Tianchi", title: "能高越嶺", leftMark: true)
                    MountainButton(imageName: "d_NG", title: "能高安東軍", leftMark: false)
                    MountainButton(imageName: "d_Mabo", title: "馬博橫斷", leftMark: false)
                    MountainButton(imageName: "d_Gandrowan", title: "干卓萬橫斷", leftMark: false)
                    MountainButton(imageName: "d_Xiluan", title: "西巒郡大", leftMark: false)
                    MountainButton(imageName: "d_S3", title: "南三段", leftMark: false)
                    MountainButton(imageName: "d_S2", title: "南二段", leftMark: false)
                    MountainButton(imageName: "d_S1", title: "南一段", leftMark: true)
                    MountainButton(imageName: "d_Jiaming", title: "嘉明新康", leftMark: false)
                    MountainButton(imageName: "d_6shun", title: "六順山", leftMark: true)
                    MountainButton(imageName: "d_Taimu", title: "北大武山", leftMark: true)
                }
                .padding(.top)
            }
            .background(Color(.black).opacity(0.9)) // 整個背景深灰
            .ignoresSafeArea()            // 延伸到螢幕邊緣
            .navigationBarHidden(true)

    }
        
}

#Preview {
    PlanView()
}

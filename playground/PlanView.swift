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
    NavigationLink(destination: DetailView(title: title)) {
        ZStack(alignment: .topLeading) {
            // 黑色背景
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .frame(height: 400)
            
            // 圖片
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 400)
                .clipped()
                .cornerRadius(16)
            
            // 高光
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(height: 400)
            
            // 文字
            if leftMark {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 350)
                    .padding(.top, 50)
                    .shadow(radius: 3)
            } else {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.leading,50)
                    .shadow(radius: 3)
            }
        }
        .frame(height: 400)
        .frame(maxWidth: .infinity)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    .padding(.horizontal)
}



struct ContentView: View {
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: 16) {
                    HStack(){
                        Image(systemName: "arrow.uturn.backward.circle")
                            .resizable() // 讓 SF Symbol 可以縮放
                            .frame(width: 40, height: 40) // 大小
                            .foregroundColor(.blue) // 顏色
                            .padding(.leading) // 左邊留點空間
                            .padding(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading) // 靠左
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
        }
    }
        
}

#Preview {
    ContentView()
}

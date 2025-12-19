import SwiftUI

struct PlanDisplayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var navModel: NavigationViewModel
    var title: String
    var route: [String]
    var nodes: [Node]
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title == "目前沒有計劃" {
                VStack {
                    Text(title)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .foregroundColor(AppColors.text)
                    Spacer()
                }
            } else {
                Text("DAY \(navModel.dayIndex + 1)")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
                    .foregroundColor(AppColors.text)
                
                Text(title)
                    .font(.title2)
                    .padding(.bottom, 4)
                    .foregroundColor(AppColors.text)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(route, id: \.self) { id in
                            if let node = nodes.first(where: { $0.id == id }) {
                                Text(node.name)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.text.opacity(0.2))
                                    .cornerRadius(4)
                                    .foregroundColor(AppColors.text)
                            } else {
                                Text(id)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.primary.opacity(0.2))
                                    .cornerRadius(4)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.leading, 10)
                .scaleEffect(1.15)
                
                HStack(spacing: 40) {
                    Button {
                        if navModel.dayIndex > 0 {
                            navModel.setCurrentDay(navModel.dayIndex - 1)
                        }
                    } label: {
                        Text("Prev Day")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(AppColors.secondary.opacity(0.35))
                            .cornerRadius(10)
                            .foregroundColor(AppColors.text)
                    }
                    
                    Button {
                        let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
                        if navModel.dayIndex + 1 < savedHistory.count {
                            navModel.setCurrentDay(navModel.dayIndex + 1)
                        }
                    } label: {
                        Text("Next Day")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(AppColors.secondary.opacity(0.35))
                            .cornerRadius(10)
                            .foregroundColor(AppColors.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                
                Text("所有計劃")
                    .font(.headline)
                    .padding(.vertical, 6)
                    .foregroundColor(AppColors.text)

                let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(savedHistory.enumerated()), id: \.offset) { (index, dayPlan) in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("Day \(index + 1)")
                                        .font(.footnote)
                                        .foregroundColor(.yellow)
                                    if index == navModel.dayIndex {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(AppColors.primary)
                                            .font(.footnote.bold())
                                    }
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(dayPlan, id: \.self) { id in
                                            if let node = nodes.first(where: { $0.id == id }) {
                                                Text(node.name)
                                                    .font(.caption)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(AppColors.text.opacity(0.15))
                                                    .cornerRadius(3)
                                                    .foregroundColor(AppColors.text)
                                            } else {
                                                Text(id)
                                                    .font(.caption)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(AppColors.primary.opacity(0.15))
                                                    .cornerRadius(3)
                                                    .foregroundColor(AppColors.text)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 6)
                        }
                    }
                }
                .padding(.top, 6)
                
                Spacer()
                Button {
                    showResetAlert = true
                } label: {
                    HStack{
                        Label("重設計劃", systemImage: "arrow.clockwise.circle")
                            .foregroundStyle(AppColors.text)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.primary.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .alert("確定要刪除目前計劃嗎？", isPresented: $showResetAlert) {
                    Button("取消", role: .cancel) {}
                    Button("刪除", role: .destructive) {
                        navModel.currentPlan = []
                        UserDefaults.standard.removeObject(forKey: "CurrentDayIndex")
                        UserDefaults.standard.removeObject(forKey: "PlanHistory")
                        dismiss()
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(8)
    }
}

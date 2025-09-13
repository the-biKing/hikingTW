/*import SwiftUI

struct SummaryView: View {
    let nodes: [Node]
    let segments: [Segment]
    let userFactor: Double

    var totalShangheTime: Double {
        segments.reduce(0) { acc, seg in acc + seg.shangheTimeMinutes }
    }
    var estimatedTotal: Double {
        totalShangheTime * userFactor
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("預估上河總時間：\(Int(estimatedTotal)) 分鐘")
                .font(.headline)

            List {
                ForEach(segments) { seg in
                    HStack {
                        Text("段：")
                        Text(seg.fromNodeID.uuidString.prefix(4) + " → " + seg.toNodeID.uuidString.prefix(4))
                        Spacer()
                        Text("\(Int(seg.shangheTimeMinutes)) min")
                    }
                }
            }
        }
        .padding()
    }
}
*/
